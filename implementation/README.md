# La mise en œuvre de la méthode

Ce dossier contient ce que Claude Code lit réellement pour travailler. Les documents à la
racine du dépôt décrivent la méthode ; ici, c'est la méthode elle-même.

## Ce qu'il y a dedans

| Dossier | Contenu |
|---|---|
| `agents/` | Les six fiches d'agent : `tdd-writer`, `verifier`, `testeur`, `correcteur`, `decoupeur`, `contradicteur`. |
| `skills/pilot/` | La skill : `SKILL.md`, ses fichiers de `reference/`, ses scripts Python. |
| `skills/research-assistant/` | Lancée par `pilot init` avant l'entretien de cadrage. |
| `skills/diagnosing-bugs/`, `skills/resolving-merge-conflicts/`, `skills/to-questionnaire/` | Importées telles quelles de `mattpocock/skills` (1.2.3, MIT) : un bug dur, un conflit de merge, une décision que seul le client peut prendre. Corps en anglais, déclencheurs en français. |
| `tools/` | `cout-agents` (ce qu'a coûté une boucle, le suivi des étapes de chaque agent en direct, les alertes), `passe-visuelle` (les captures du `testeur`) et `verrou-git` (le hook qui refuse tout push vers la branche principale et tout merge : le merge est humain, par construction). |
| `global/` | Ce qui ne s'installe pas par projet — voir plus bas. |

## Comment ça s'installe

Depuis la racine du dépôt :

```bash
./install.sh <chemin du projet>
```

Le script copie `agents/`, `skills/` et `tools/` dans le `.claude/` du projet, et y écrit
`METHODE.md` avec la version installée. Il sert aussi bien à la première pose qu'à une mise
à jour.

La méthode est ensuite **versionnée avec le projet**. Chaque membre qui clone reçoit le code
et la méthode dans le même geste : personne ne travaille avec une version différente sans
le voir.

## La règle

**On modifie la méthode ici, jamais dans un projet.** Une amélioration se fait sur une
branche de ce dépôt, avec une PR. Chaque projet la reçoit quand il décide de se mettre à
jour, en relançant `install.sh`.

Modifier la copie d'un projet ne remonte nulle part, et la prochaine mise à jour l'écrase.

## Le dossier `global/`

Deux choses restent dans `~/.claude`, parce qu'elles ne dépendent d'aucun projet :

- `CLAUDE.md` — les préférences de travail (langue, style, règles de commit) ;
- `skills/rendu-fonctionnel/` — la façon de rendre un compte rendu.

Elles sont ici pour être versionnées, pas pour être installées par projet. Elles se copient
à la main dans `~/.claude/`, une fois :

```bash
cp implementation/global/CLAUDE.md ~/.claude/CLAUDE.md
cp -R implementation/global/skills/rendu-fonctionnel ~/.claude/skills/
```

## Ce qui n'est pas versionné

Les dépendances installées : `tools/passe-visuelle/node_modules`. Elles se réinstallent avec
`npm install` dans le dossier de l'outil, une seule fois par projet.
