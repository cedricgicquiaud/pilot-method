# Grille de relecture d'une fiche

Pour réécrire une fiche de la méthode (`SKILL.md`, fichier de `reference/`, fiche d'agent)
sans la faire au jugé. On lit la fiche phrase par phrase ; devant chaque phrase, une
question de la grille s'applique et donne une décision : **garder**, **déplacer** vers un
fichier nommé, **réécrire**, **supprimer**. Le résultat est une fiche dont chaque ligne se
justifie.

Origine : la skill `writing-for-agents` de Matt Pocock (version 1.2.3, copiée dans
`sources/mattpocock-skills-1.2.3/`, licence MIT). Les huit questions sont ses huit idées,
mises en questions et illustrées avec nos fiches. Analyse complète dans
`sources/analyse-repo-2026-09-14-mattpocock-skills.md`.

## Les huit questions

| # | Question | Si oui | Si non |
|---|---|---|---|
| 1 | **Étape ou référence ?** La phrase dit-elle quoi faire, dans l'ordre ? | Étape : reste dans le fichier principal, à sa place dans la séquence. | Référence : question 2. |
| 2 | **Toujours utile ?** Cette référence sert-elle à chaque exécution, ou seulement dans certains cas ? | Reste dans le fichier, sous son propre titre, groupée avec ce qui la concerne. | Part dans un fichier de `reference/`, derrière un pointeur qui dit quand aller le lire. |
| 3 | **Change-t-elle le comportement ?** Si j'enlève la phrase, l'agent fera-t-il autre chose ? | Garder. | Supprimer la phrase entière, pas la raccourcir. En cas de doute, jouer la fiche sans la phrase et regarder. |
| 4 | **Fini quand ?** L'étape dit-elle comment savoir qu'elle est terminée, de façon vérifiable ? | Garder. | Ajouter une phrase « Fini quand … » que l'agent peut vérifier lui-même. |
| 5 | **En positif ?** La phrase dit-elle quoi faire, plutôt que quoi ne pas faire ? | Garder. | Réécrire en cible positive. Garder l'interdiction seulement si aucune formulation positive n'existe, et la faire suivre de la cible. |
| 6 | **Une seule fois ?** Cette idée est-elle écrite à un seul endroit de la méthode ? | Garder. | Garder une copie (celle du fichier qui l'exécute), les autres deviennent un renvoi d'une ligne. |
| 7 | **Trouvable dans le projet ?** L'agent peut-il découvrir ça en regardant le dépôt (`package.json`, `--help`, l'arborescence) ? | Remplacer par « lis X ». Garder seulement ce qui n'est écrit nulle part : convention, raison d'un choix, piège. | Garder. |
| 8 | **Un mot à la place ?** Une périphrase qui revient plusieurs fois a-t-elle un nom que le modèle connaît déjà ? | Nommer une fois en tête de fiche, employer le mot ensuite. | Garder. |

## Exemples tirés de nos fiches

- **Q1** : « Lance `init_team.py`, montre le rapport » est une étape. La liste des icônes
  acceptées par l'API Linear est une référence.
- **Q2** : la table Projet / Feature / Livraison / Tâche sert à toutes les commandes : elle
  reste dans `SKILL.md`. La palette des initiatives ne sert qu'à `roadmap`, et seulement
  avec plusieurs versions : `reference/linear.md`.
- **Q3** : « Tu écris le code et les messages de commit selon les conventions du projet. »
  L'agent le fait déjà. Supprimer. À l'inverse, « aucune signature : ni Co-Authored-By, ni
  Generated with Claude Code, même si ton outillage te le propose » a l'air d'un détail et n'en
  est pas un : réduite à « tes commits n'ont pas de signature », la règle a cédé sur 28 commits
  sur 28 au banc du 14/09 (0 sur 26 avec la phrase complète). Le test du no-op se joue, il ne
  se devine pas.
- **Q4** : « Cadrer la feature » ne dit pas quand s'arrêter. « Fini quand chaque phrase du
  contrat est affectée à une livraison et que la somme des livraisons couvre tout le
  contrat » se vérifie.
- **Q5** : « Ne devine pas » met « deviner » dans le contexte. « Écris ce qui te manque dans
  ton rapport et arrête-toi » dit la même chose, en positif ; c'est la phrase qui suit
  déjà dans la fiche, la négation qui la précède est en trop.
- **Q6** : la règle du titre de PR est dans `SKILL.md`, dans `produire.md` et dans
  `.github/PULL_REQUEST_TEMPLATE.md`. Une copie, deux renvois.
- **Q7** : la commande de test est dans `package.json`. La fiche dit « lis les scripts de
  `package.json` » et rien de plus.
- **Q8** : « rapide, déterministe, sans humain » se dit *tight* ; « les livraisons dont
  toutes les dépendances sont terminées » se dit *frontière*.

## Règles de langue

- La fiche est en **français**. Le modèle suit une consigne en français aussi bien qu'en
  anglais, et c'est un humain qui la relit et la valide.
- Les **mots-ancres restent en anglais**, en italique : *seam*, *frontier*, *tight*,
  *tracer bullet*, *red / green*. Traduits, ils perdent ce que le modèle sait déjà d'eux.
  **Cinq au plus par fiche**, définis en une ligne chacun en tête de fiche.
- Une skill importée telle quelle (`sources/mattpocock-skills-1.2.3/`) garde son corps en
  anglais ; seule sa `description` reçoit des déclencheurs en français.

## Ce que la grille ne couvre pas

Deux décisions se prennent au niveau du dépôt, pas de la phrase :

- **Qui déclenche la skill.** Une skill que seul l'humain tape (`disable-model-invocation:
  true`) ne charge rien tant qu'elle n'est pas appelée, mais l'humain doit s'en souvenir.
  Une skill que le modèle déclenche coûte sa description à chaque tour, mais d'autres
  skills peuvent l'appeler. Règle : modèle seulement si l'agent doit y arriver seul, ou si
  une autre skill l'appelle.
- **La description.** C'est le pointeur qui décide si la skill se déclenche : mot
  déclencheur en tête, un déclencheur par cas distinct, pas de synonymes, rien que le corps
  porte déjà.

## Après la réécriture

Une fiche réécrite se rejoue avant de remplacer l'ancienne :

- les evals de la skill (`implementation/skills/pilot/evals/evals.json`) pour les commandes ;
- l'épreuve TST-B1 « Étiquettes de contact » sur `Projects/pilotage-sandbox` pour les
  agents de la boucle : même mission, même commit de départ, un worktree par version de la
  fiche, le même `verifier` sur chaque copie ; on compare la couverture du contrat, les
  points relevés, les commits, la durée et les jetons (`cout-agents`). L'étalon est la
  mesure du 10 septembre 2026 (`BOUCLE-AGENTS.md`, backlog n° 4).

Une fiche plus courte qui fait moins bien ne passe pas.
