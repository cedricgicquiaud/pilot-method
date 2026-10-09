# CLAUDE.md

Guide de travail dans ce dépôt.

## Nature du dossier

Ce dépôt contient deux choses : la **documentation** de la méthode, en français, et la
**méthode elle-même**, dans `implementation/`.

La documentation décrit deux sujets complémentaires :

1. comment **piloter** un projet avec Linear (suivi), GitHub (code) et Claude Code
   (exécution) — présentable à un client ;
2. comment **produire** en parallèle avec plusieurs agents, et vérifier sans humain
   (la « boucle agents ») — cuisine interne.

`implementation/` contient ce que Claude Code lit pour travailler : les six fiches d'agent,
la skill `pilot`, deux outils. `./install.sh <projet>` en pose une copie dans le `.claude/`
du projet, où elle est versionnée avec lui.

Dépôt git : branche de travail `main`, développement sur branches `docs/…`. Le merge est
humain, comme partout ailleurs. Ce dépôt est l'extrait public d'un dépôt de travail
privé, qui garde les comptes rendus de session : une contribution passe par une issue ou une
PR ici, reportée là-bas.

## Fichiers

| Fichier | Rôle |
|---|---|
| `README.md` | La porte d'entrée, pour quelqu'un qui arrive : le principe, le vocabulaire, l'installation. Le reste des documents s'adresse à qui travaille déjà avec la méthode. |
| `PILOTAGE-LINEAR-GITHUB-CLAUDE.md` | Document de référence complet. Partie A = tronc commun (suivi Linear/GitHub) ; Partie B = le circuit d'une feature, les commandes, `next`. |
| `circuit-linear-github-claude.html` | Version visuelle résumée, page autonome (CSS inline, aucune dépendance). Support de présentation. |
| `BOUCLE-AGENTS.md` | La boucle agents : pourquoi, les briques, les invariants, les leçons de chaque essai, le backlog des manques. Journal de bord autant que méthode. |
| `GRILLE-DE-RELECTURE.md` | Les huit questions à poser à chaque phrase d'une fiche avant de la garder, la déplacer ou la supprimer ; les règles de langue ; comment rejouer une fiche réécrite. À appliquer à toute modification d'une fiche dans `implementation/`. |
| `.out-of-scope/` | Un fichier par idée écartée : ce qu'on a refusé, pourquoi, et ce qui ferait rouvrir. À consulter avant de proposer une évolution de la méthode. |
| `implementation/` | La méthode elle-même : fiches d'agent, skill `pilot`, outils. Son `README.md` dit comment elle s'installe. |
| `install.sh` | Pose la méthode dans le `.claude/` d'un projet. Sert à la première installation comme aux mises à jour. |

`PILOTAGE-…md` et le HTML décrivent la même méthode : toute modification de fond dans l'un
(statuts, nommage, vocabulaire) doit passer dans l'autre. Le HTML est volontairement plus
court — 5 sections, contre 24 pour le Markdown.

`BOUCLE-AGENTS.md` s'appuie sur le pilotage sans le modifier. Il ne cite aucun projet réel :
le seul exemple est le banc d'essai `pilotage-sandbox`.

## Ce qu'il ne faut pas casser

- **Vocabulaire imposé**, quatre étages plus un :
  Team = **Projet** (mois) · Project Linear = **Feature** (semaines) · Milestone = **Livraison**,
  soit une PR (jours) · Issue = **Tâche** (heures). Initiative = **Cap**, facultatif.
  Ne jamais dire « projet » pour un Project Linear : c'est une feature.
- **Règle centrale** : le code Linear voyage dans le nom de branche (`feature/<CODE>-<nom>`,
  `fix/…`, `chore/…`) et dans le titre de la PR. Tout le reste en découle.
- **Statuts de feature**, dans l'ordre : À cadrer → Planifiée → En développement → En revue
  → Terminée → Rétro faite. **C'est Claude qui les pose, jamais GitHub** — l'intégration
  GitHub ne fait avancer que les statuts de *tâche*.
- **Partie B ne modifie jamais la Partie A** : le circuit remplit les cases définies par le
  tronc commun. Garder cette séparation.
- **FORGE n'existe plus** : absorbé par la Partie B et par `BOUCLE-AGENTS.md`. Ne pas le
  réintroduire.
- **Le merge est humain, à chaque livraison.** C'est là que tu réponds aux décisions que les
  agents ont refusé de trancher : enchaîner sans répondre, c'est les laisser deviner tes
  réponses. La condition d'ouverture est écrite au backlog n° 10 de `BOUCLE-AGENTS.md`.
- **Ton rédactionnel** : phrases courtes, une idée par phrase, un exemple plutôt qu'une
  définition, aucune phrase qui puisse se lire de deux façons.

## Vérification

Pour contrôler le HTML après modification, l'ouvrir dans un navigateur
(`open circuit-linear-github-claude.html`) ; aucun serveur n'est nécessaire.

## Mise en œuvre

La méthode est dans `implementation/`, versionnée avec sa documentation. **L'inventaire
complet est au § 6 de `BOUCLE-AGENTS.md`** — un seul endroit le tient à jour.

**Le texte et la méthode doivent rester d'accord.** Une modification de fond dans les
documents doit se retrouver dans `implementation/`, et l'inverse. Un document qui décrit ce
que la skill ne fait plus est pire que pas de document.

**On modifie la méthode ici, jamais dans un projet.** Ce qu'un projet contient dans son
`.claude/` est une copie posée par `install.sh` ; la modifier ne remonte nulle part, et la
prochaine mise à jour l'écrase.
