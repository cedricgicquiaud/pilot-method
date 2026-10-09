#!/usr/bin/env bash
#
# Installe la méthode pilot dans un projet.
#
#   ./install.sh <chemin du projet>
#
# Copie les fiches d'agent, la skill pilot et les outils dans <projet>/.claude/.
# Sert aussi bien à la première pose qu'à une mise à jour : les fichiers du projet sont
# alignés sur la version de ce dépôt, qui fait foi.
#
# Le script ne touche qu'à ce qui lui appartient. Une skill, une fiche d'agent ou un outil
# propre au projet, posé à côté, n'est jamais supprimé.
#
# Après l'installation, le projet contient sa propre copie de la méthode. Elle est
# versionnée avec lui : chaque membre du projet travaille avec la même.

set -euo pipefail

SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ $# -ne 1 ]; then
  echo "Usage : $0 <chemin du projet>" >&2
  exit 1
fi

PROJET="$(cd "$1" 2>/dev/null && pwd)" || { echo "Dossier introuvable : $1" >&2; exit 1; }

if [ ! -d "$PROJET/.git" ]; then
  echo "« $PROJET » n'est pas un dépôt git." >&2
  echo "La méthode se versionne avec le projet : sans dépôt, l'installation n'a pas de sens." >&2
  exit 1
fi

if [ ! -d "$SOURCE/implementation" ]; then
  echo "« $SOURCE/implementation » est introuvable. Lancer ce script depuis le dépôt pilot." >&2
  exit 1
fi

VERSION="$(git -C "$SOURCE" rev-parse --short HEAD 2>/dev/null || echo inconnu)"
DATE="$(date +%F)"
METHODE="$PROJET/.claude/METHODE.md"

echo "Source  : $SOURCE (version $VERSION)"
echo "Projet  : $PROJET"
echo

mkdir -p "$PROJET/.claude/agents" "$PROJET/.claude/skills" "$PROJET/.claude/tools"

# --- Les fiches d'agent -----------------------------------------------------------------
#
# Elles vivent à plat dans .claude/agents/, à côté de fiches qui peuvent appartenir au
# projet. On ne peut donc pas aligner le dossier entier. La liste posée à l'installation
# précédente est relue dans METHODE.md : une fiche qui y était et n'est plus dans la méthode
# est retirée, les autres ne sont pas touchées.

FICHES=""
for f in "$SOURCE"/implementation/agents/*.md; do
  FICHES="$FICHES $(basename "$f")"
done

if [ -f "$METHODE" ]; then
  ANCIENNES="$(sed -n 's/^- fiche: //p' "$METHODE")"
  for vieille in $ANCIENNES; do
    case " $FICHES " in
      *" $vieille "*) ;;
      *) [ -f "$PROJET/.claude/agents/$vieille" ] && {
           mv "$PROJET/.claude/agents/$vieille" "$PROJET/.claude/agents/.$vieille.retiree"
           echo "  retirée : .claude/agents/$vieille (renommée, plus dans la méthode)"
         } ;;
    esac
  done
fi

# Les fiches nomment les outils Linear de la connexion par défaut, `mcp__linear__*`. Un
# projet sur un autre workspace passe par une autre connexion, nommée dans sa section Pilot
# (« connexion MCP `linear-<slug>` ») : on réécrit ces outils à son nom, sans quoi l'agent
# n'en reçoit aucun et travaille sans Linear.

CONNEXION=""
if [ -f "$PROJET/CLAUDE.md" ]; then
  CONNEXION="$(sed -n 's/.*connexion MCP `\([A-Za-z0-9_-]*\)`.*/\1/p' "$PROJET/CLAUDE.md" | head -1)"
fi
CONNEXION="${CONNEXION:-linear}"

echo "Installé :"
for f in $FICHES; do
  sed "s/mcp__linear__/mcp__${CONNEXION}__/g" "$SOURCE/implementation/agents/$f" \
    > "$PROJET/.claude/agents/$f"
done
echo "  .claude/agents/ — $(echo $FICHES | wc -w | tr -d ' ') fiches (outils Linear : connexion \`$CONNEXION\`)"

# --- Les skills et les outils -----------------------------------------------------------
#
# Chacun est un dossier qui nous appartient en entier : rsync --delete l'aligne sur la
# source, y compris pour les fichiers retirés. Les dossiers voisins ne sont pas touchés.
# Les chemins exclus ne sont ni copiés ni supprimés : les dépendances déjà installées
# dans le projet survivent.

aligner() {
  local chemin="$1"
  mkdir -p "$PROJET/.claude/$chemin"
  rsync -a --delete \
    --exclude='__pycache__' --exclude='*.pyc' \
    --exclude='.DS_Store' --exclude='node_modules' \
    "$SOURCE/implementation/$chemin/" "$PROJET/.claude/$chemin/"
  echo "  .claude/$chemin"
}

for d in "$SOURCE"/implementation/skills/*/; do
  aligner "skills/$(basename "$d")"
done
for d in "$SOURCE"/implementation/tools/*/; do
  aligner "tools/$(basename "$d")"
done

# --- Les hooks --------------------------------------------------------------------------
#
# Deux hooks posés dans .claude/settings.json du projet, à côté de l'allowlist, sans toucher
# au reste du fichier :
#   - SubagentStart : à chaque sous-agent lancé, panneau-agent.sh ouvre un panneau cmux qui
#     suit ses grandes étapes (rien sans cmux) ;
#   - PreToolUse sur Bash : verrou-git.py refuse, avant exécution, tout push vers la branche
#     principale ou `release`, tout push forcé et tout merge de PR. Le merge est humain ;
#     ici, ce n'est plus une consigne, c'est un fait.

python3 - "$PROJET/.claude/settings.json" <<'PY'
import json, os, sys
chemin = sys.argv[1]
conf = {}
if os.path.exists(chemin):
    with open(chemin) as f: conf = json.load(f)
hooks = conf.setdefault("hooks", {})

def poser(evenement, matcher, script):
    cmd = '"$CLAUDE_PROJECT_DIR"/.claude/tools/' + script
    entrees = [e for e in hooks.get(evenement, [])
               if not any(script.split("/")[-1] in h.get("command", "") for h in e.get("hooks", []))]
    entrees.append({"matcher": matcher, "hooks": [{"type": "command", "command": cmd}]})
    hooks[evenement] = entrees

poser("SubagentStart", ".*", "cout-agents/panneau-agent.sh")
poser("PreToolUse", "Bash", "verrou-git/verrou-git.py")
os.makedirs(os.path.dirname(chemin), exist_ok=True)
with open(chemin, "w") as f: json.dump(conf, f, indent=2, ensure_ascii=False); f.write("\n")
PY
chmod +x "$PROJET/.claude/tools/verrou-git/verrou-git.py" "$PROJET/.claude/tools/cout-agents/panneau-agent.sh"
echo "  .claude/settings.json — hooks SubagentStart (panneau de suivi) et PreToolUse (verrou git)"

# --- La trace ---------------------------------------------------------------------------

{
  echo "# Méthode pilot — version installée"
  echo
  echo "- Version : \`$VERSION\` (dépôt \`pilot\`)"
  echo "- Installée le : $DATE"
  echo
  echo "Fiches d'agent posées par l'installation — cette liste sert à retirer proprement"
  echo "une fiche qui sortirait de la méthode. Ne pas la modifier à la main."
  echo
  for f in $FICHES; do echo "- fiche: $f"; done
  echo
  cat <<EOF
Ce dossier est une **copie**. La version de référence vit dans le dépôt \`pilot\`, dans
\`implementation/\`. Une amélioration de la méthode s'y fait, sur une branche, avec une PR.

Pour recevoir la dernière version dans ce projet :

\`\`\`bash
cd <dépôt pilot> && git pull && ./install.sh $PROJET
\`\`\`

Modifier les fichiers de ce dossier ne remonte nulle part, et la prochaine mise à jour
les écrase.
EOF
} > "$METHODE"
echo "  .claude/METHODE.md"

echo
if [ ! -d "$PROJET/.claude/tools/passe-visuelle/node_modules" ]; then
  echo "Reste à faire, une seule fois, pour que le testeur puisse prendre des captures :"
  echo "  cd \"$PROJET/.claude/tools/passe-visuelle\" && npm install"
  echo
fi
echo "La méthode est en place. Elle se commite avec le projet."
