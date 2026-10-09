# pilot

_A method to run a software project with Linear, GitHub and Claude Code: AI agents frame, build,
review and fix the code, a human merges. Documentation in French; agent prompts and tools in
`implementation/`._

Une méthode pour mener un projet logiciel avec Linear, GitHub et Claude Code — et le code qui
la fait tourner.

Ce dépôt contient les deux : les documents qui expliquent la méthode, et son implémentation,
qui s'installe dans chaque projet.

## Le principe

Trois outils, trois rôles, et rien qui se recopie d'un endroit à l'autre.

| | |
|---|---|
| **Linear** | Le tableau de bord. Ce qu'on fait, dans quel ordre, où on en est. |
| **GitHub** | L'atelier. Le code, les branches, les pull requests. |
| **Claude Code** | L'ouvrier. Il cadre, il découpe, il produit, il vérifie. |

Une seule règle fait tenir l'ensemble : **le code de la tâche Linear voyage dans le nom de la
branche et dans le titre de la PR.** Tout le reste en découle — Linear lit GitHub et se met à
jour seul.

## Le vocabulaire

Quatre étages, du plus large au plus fin. Les noms sont imposés, parce qu'un mot flottant
finit par désigner deux choses.

| Dans Linear | Chez nous | Durée |
|---|---|---|
| Team | **Projet** | des mois |
| Project | **Feature** | des semaines |
| Milestone | **Livraison** — une PR | des jours |
| Issue | **Tâche** | des heures |

Ne jamais dire « projet » pour un Project Linear : c'est une feature.

## Ce que fait la boucle d'agents

Une feature cadrée est découpée en livraisons qui ne se marchent pas dessus. Chacune est
produite par un agent seul dans sa copie du dépôt, en test-d'abord strict. Deux autres agents
la relisent — l'un le code, l'autre les écrans — sans jamais la corriger. Un troisième corrige
ce qu'ils ont trouvé, une seule fois.

Puis la PR s'ouvre, et **c'est toi qui merges**.

Trois invariants, jamais négociés :

1. **Le merge est humain**, à chaque livraison.
2. **Les décisions de fond remontent**, elles ne se tranchent pas en chemin.
3. **Pas de code sans test préalable** — l'historique des commits en est la preuve, et un agent
   la contrôle.

## Les fichiers

| Fichier | Ce qu'on y trouve |
|---|---|
| [`PILOTAGE-LINEAR-GITHUB-CLAUDE.md`](PILOTAGE-LINEAR-GITHUB-CLAUDE.md) | La méthode complète. Partie A : le suivi Linear/GitHub. Partie B : le circuit d'une feature et les commandes. |
| [`circuit-linear-github-claude.html`](circuit-linear-github-claude.html) | La même chose en cinq écrans, à ouvrir dans un navigateur. Support de présentation. |
| [`BOUCLE-AGENTS.md`](BOUCLE-AGENTS.md) | La boucle d'agents : pourquoi, les briques, les leçons de chaque essai, ce qui manque encore. Journal de bord autant que méthode. |
| [`implementation/`](implementation/) | Ce que Claude Code lit pour travailler : six fiches d'agent, la skill `pilot`, trois skills importées, trois outils. |
| [`GRILLE-DE-RELECTURE.md`](GRILLE-DE-RELECTURE.md) | Les huit questions à poser à chaque phrase d'une fiche avant de la modifier. |
| `.out-of-scope/` | Les idées essayées ou étudiées et écartées, avec la raison, pour ne pas rouvrir le débat sans élément nouveau. |

Pour comprendre la méthode, commence par le HTML — cinq minutes. Pour la mettre en œuvre, lis
la Partie B du Markdown.

## Quelle commande, dans quelle situation

| Tu veux… | Tape | Claude s'arrête quand |
|---|---|---|
| Savoir où en est le projet et quoi faire ensuite | `/pilot next` | Il a proposé l'étape logique |
| Démarrer un projet | `/pilot init` | Le PRD est à valider |
| Poser toutes les features | `/pilot roadmap` | La liste est à valider |
| Ouvrir une feature | `/pilot feature <nom>` | Le cadrage, puis le découpage, sont à valider |
| Produire les livraisons | `/pilot run <feature>` | Les PR sont ouvertes et auditées ; tu merges |
| Remettre Linear d'aplomb après un merge | `/pilot sync` | Il enchaîne sur `next` |
| Corriger un bug ou faire une retouche hors feature | `/pilot fix <description>` | La PR est ouverte |
| Comprendre un bug qui ne se reproduit pas | dis « diagnostique » | La cause est nommée |
| Sortir d'un merge en conflit | dis « le merge bloque » | Le merge est terminé |
| Faire trancher le client | `/to-questionnaire` | Le document à lui envoyer est écrit |
| Mettre la méthode d'un projet à jour | `/pilot update` | Le commit est à valider |

Dans l'usage courant, `next` suffit : chaque commande finit en proposant la suivante.

## Installer la méthode dans un projet

```bash
git clone git@github.com:cedricgicquiaud/pilot-method.git
cd pilot-method
./install.sh /chemin/vers/ton/projet
```

Le script copie les fiches d'agent, la skill et les outils dans le `.claude/` du projet. **La
méthode est ensuite versionnée avec ce projet** : qui le clone reçoit le code et la méthode
dans le même geste, et deux personnes ne peuvent pas travailler avec des versions différentes
sans le voir.

Ensuite, dans le projet :

```bash
claude
/pilot init
```

`init` mène l'entretien de cadrage, écrit le PRD, crée la team Linear et pose les meubles dans
le dépôt.

## Mettre à jour un projet

Depuis le projet, `/pilot update`. Il va chercher la dernière version, dit en trois lignes ce
qui change pour ton travail, et commite. Il refuse de tourner pendant qu'une livraison est en
cours : un agent lancé avec les anciennes fiches ne doit pas finir avec les nouvelles.

## La règle qui tient tout

**On modifie la méthode ici, jamais dans un projet.** Ce qu'un projet contient dans son
`.claude/` est une copie ; la modifier ne remonte nulle part, et la prochaine mise à jour
l'écrase.

Une amélioration se fait dans ce dépôt, sur une branche, avec une pull request.

## Pré-requis

- Un compte Linear (le plan gratuit suffit : deux teams par workspace) et son intégration
  GitHub activée
- Un dépôt GitHub par projet
- Claude Code
- Node et Python 3 pour les deux outils

## Licence

- Les textes (documents, fiches d'agent, skills) : [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.fr).
  Réutilisation libre, en citant l'auteur.
- Le code (`install.sh`, scripts et outils de `implementation/`) : MIT, voir [`LICENSE`](LICENSE).
- Les trois skills importées de [`mattpocock/skills`](https://github.com/mattpocock/skills)
  gardent leur licence MIT, jointe dans leur dossier.
