# La boucle agents — faire travailler plusieurs agents Claude Code sans les regarder

_Document interne. Il complète `PILOTAGE-LINEAR-GITHUB-CLAUDE.md` : la Partie B de ce dernier
décrit le circuit complet d'une feature (cadrer → découper → produire → merger → apprendre) ;
ce document détaille l'étape « produire » : comment plusieurs agents fabriquent en parallèle,
avec une vérification qui tourne sans humain. Méthode rodée les 26 et 27 août 2026
sur le dépôt `cedricgicquiaud/pilotage-sandbox` (10 PR mergées, 2 features terminées, 126 tests verts)._

---

## 1. Pourquoi

Trois idées, tirées de deux vidéos (analyse critique complète en annexe
`sources/analyse-videos-2026-08-26.md`, dans ce dépôt) :

1. **Le goulot n'est plus d'écrire le code, c'est de le vérifier.** Tant que la
   vérification, c'est un humain qui lit en direct, on reste « moniteur d'auto-école »,
   le pied sur le frein. Il faut une boucle de vérification qui tourne sans lui.
2. **Quatre chantiers pour y arriver** : le contrat (`CLAUDE.md`, tout ce qu'on répète à
   l'oral) ; l'examen (une commande de tests que l'agent lance lui-même) ; les bacs à sable
   (un dossier isolé par agent, commandes sûres pré-autorisées) ; la relecture (un agent neuf
   qui n'a pas écrit le code, avec un seul mandat : trouver ce qui casse).
3. **Un agent se recrute, il ne s'installe pas.** Chaque agent a une fiche : périmètre, docilité
   (l'exécutant obéit, le relecteur contredit), effort, disjoncteurs (budget, accès).

Deux tests pour savoir si on y est : « un ingénieur l'aurait-il fait comme ça ? » avant chaque
sortie d'agent ; « puis-je lancer deux chantiers le matin et partir deux heures ? ». Si la
seconde question fait peur, c'est la boucle qu'il faut renforcer, pas la tolérance au risque.

Sources : Cherny, « Steps of AI Adoption » (16/07/2026) ; vidéo 1
<https://www.youtube.com/watch?v=8ZJI4uCp6bA> ; vidéo 2
<https://www.youtube.com/watch?v=Nmu1-eILb9g> ; vidéo 3 (Factory « Missions »)
<https://www.youtube.com/watch?v=ow1we5PzK-o> ; Cognition, « Making Fable Cheaper Than Opus ».
À retenir : la méthode. Les chiffres (METR, +441 %, jauge en tokens) sont des directions, pas
des certitudes.

---

## 2. La recette

### 2.0 Place dans le circuit

La boucle commence quand le découpage est validé (feature « Planifiée » dans Linear) et se
termine quand les PR sont ouvertes avec leur rapport d'audit. Avant : cadrage et découpage,
avec l'humain. Après : merge humain, puis apprentissage. Le tout est décrit dans la Partie B
du document pilotage ; l'humain ne lance la boucle que par `/pilot run <feature>`.

### 2.1 Vue d'ensemble

```
Feature Linear (découpée en livraisons disjointes)
        │
        ▼
 ┌──────────────┐   ┌──────────────┐
 │ Producteur A │   │ Producteur B │   ← 1 worktree + 1 MISSION.md chacun
 └──────┬───────┘   └──────┬───────┘
        ▼                  ▼
   Relecteur (verifier) + Testeur (testeur) — n'ont pas écrit le code, signalent, ne corrigent pas
   (l'un lit le diff, l'autre regarde l'écran)
        │
        ▼
   Correcteur — liste fermée de corrections, rien d'autre
        │
        ▼
   PR (rapport d'audit joint)  →  merge HUMAIN  →  décisions gravées dans Linear
```

Une itération complète = 18 à 25 minutes par livraison, mesuré sur le bac à sable.

### 2.2 Les briques

Ce tableau dit **pourquoi** chaque brique existe. Le **comment** vit dans la fiche de l'agent ou
dans la skill, et n'est pas recopié ici : deux textes qui décrivent le même mécanisme finissent
par se contredire, et c'est le second qu'on oublie de corriger.

| Brique | Pourquoi elle existe | Le détail |
|---|---|---|
| **Livraisons disjointes** | Deux agents qui modifient le même fichier produisent deux travaux à démêler à la main au moment de les réunir. C'est une compétence de découpage, pas un outil. | `feature`, temps 2 |
| **Un worktree par agent** | Un second dossier de travail branché sur le même dépôt, sur sa propre branche. Si A casse tout dans le sien, B ne le voit pas. | `run`, étape 2 |
| **Un `MISSION.md` par worktree** | La fiche dit la règle, la mission donne la valeur. Sans elle, l'agent ne sait ni quels fichiers il ouvre, ni ce qu'il doit prouver. | `reference/MISSION.template.md` |
| **Commandes pré-autorisées** | L'agent doit travailler sans demander la permission à chaque geste — mais pas n'importe lequel. Réseau, suppressions et merge restent manuels. | § 2.4 |
| **Producteur** | Le test commité avant le code est la seule preuve qu'il a été écrit en premier. Un test écrit après confirme une décision ; il n'attrape pas de bug. Sur une livraison XL, un producteur neuf par tâche : une session courte relit moins, et un incident ne coûte qu'une tâche (bancs des 16 et 17/09, mesure du 18/09). | `agents/tdd-writer.md` |
| **Relecteur indépendant** | Celui qui a écrit le code ne voit pas ses propres fautes. Découverte n° 1 de l'essai : deux failles bloquantes trouvées par lui seul, sur 32 tests verts. | `agents/verifier.md` |
| **Testeur** | Il ne lit jamais le diff. C'est ce qui fait de son avis une seconde preuve, et non un doublon du relecteur. | `agents/testeur.md` |
| **Correcteur** | Sa tentation propre n'est pas de bâcler, c'est d'élargir la liste. Un diff qui grossit oblige à tout ré-auditer. | `agents/correcteur.md` |
| **Découpeur** | Le découpage décide si les agents travaillent ou se gênent. Une réponse valable est « ça ne se parallélise pas ». | `agents/decoupeur.md` |
| **Contradicteur** | Un trou trouvé avant le code coûte une phrase à corriger ; le même trou trouvé après coûte une journée. | `agents/contradicteur.md` |

### 2.3 Le `MISSION.md`

Un fichier par livraison, écrit par `run` depuis `reference/MISSION.template.md`, exclu de git.

**Il porte ce qui change d'une livraison à l'autre** : les tâches dans l'ordre de production, les fichiers modifiables, les
décisions produit déjà tranchées, le texte des phrases du contrat à rendre vraies, les idiomes
du projet, la commande de tests, le titre de la PR.

**Il ne porte jamais la façon de travailler** — ordre des commits, périmètre, « tu ne tranches
pas », `UAT.md`, stop après la PR, format du rapport. Tout cela est dans la fiche de l'agent.

Il est jetable parce que tout ce qu'il contient de durable vit ailleurs.

### 2.4 L'allowlist de référence

`.claude/settings.json` d'un projet, posé par `init`. La partie `hooks` est posée par `install.sh` : à chaque sous-agent lancé, un panneau cmux suit ses étapes (voir n° 9 du backlog).

```json
{
  "permissions": {
    "allow": [
      "Bash(node --test:*)", "Bash(npm run:*)", "Bash(python3 -m http.server:*)",
      "Bash(git status:*)", "Bash(git diff:*)", "Bash(git log:*)", "Bash(git show:*)",
      "Bash(git add:*)", "Bash(git commit:*)", "Bash(git push:*)", "Bash(git branch:*)",
      "Bash(ls:*)", "Bash(cat:*)", "Bash(grep:*)", "Bash(find:*)",
      "Bash(head:*)", "Bash(tail:*)", "Bash(sort:*)", "Bash(echo:*)",
      "Bash(lsof:*)", "Bash(ps:*)", "Bash(kill:*)", "Bash(pkill:*)", "Bash(sleep:*)",
      "Bash(curl:*)",
      "mcp__linear__get_issue", "mcp__linear__list_issues", "mcp__linear__get_project",
      "mcp__linear__save_issue", "mcp__linear__save_project", "mcp__linear__save_comment"
    ]
  }
}
```

Trois lignes se remplacent selon le projet : la commande de tests, celle qui lance l'app,
celle qui la construit. Ne jamais y mettre : suppression de fichiers, merge, réseau autre
que `git push` et `curl` vers l'app locale.

**Une commande composée n'est autorisée que si chacun de ses morceaux l'est.** Le testeur
qui écrit `pkill -f "next dev"; sleep 1; curl localhost:3000/api/health` attend un humain sur
`sleep`, même si `pkill` est autorisé. C'est pour ça que `sleep`, `echo`, `sort` et `curl`
sont dans la liste : pas pour eux-mêmes, mais parce qu'un agent les glisse dans une chaîne
sans y penser, et qu'une chaîne refusée arrête l'agent jusqu'au retour de l'humain. Les
fiches des quatre agents de la boucle disent la règle de l'autre côté : une commande par
appel, sans `sleep`, `curl` ni `echo` autour.

### 2.5 Deux façons de lancer un agent

| Mode | Quand | Propriétés |
|---|---|---|
| **Session indépendante** (pane cmux dans le worktree) | Travail long, doit survivre, doit être visible et interruptible. Les producteurs. | **Se lance par `claude --agent tdd-writer`** : une session ordinaire ne charge aucune fiche, et n'aurait donc aucune des règles de la boucle. Lit le `settings.json` de son worktree, contexte propre, survit à la session principale. C'est le seul mode qui teste réellement l'allowlist. |
| **Sous-agent orchestré** (lancé par la session principale) | Travail court, borné, dont seule la valeur est le rapport. Relecteurs, correcteurs. | Hérite des permissions de la session principale, invisible, meurt avec elle. |

---

## 3. Trois invariants non négociables

1. **Le merge reste humain.** L'arbitrage ne se délègue pas. Ce n'est pas de la prudence
   décorative : c'est le cas d'échec mesuré (Cognition : déléguer le jugement = −27 points).
2. **Les décisions de fond remontent, elles ne se prennent pas en chemin.** Exemple réel : un
   correcteur a décidé seul de passer le registre des permissions en « refus par défaut ».
   Bonne décision, mais c'était de l'architecture, pas une correction. Dans la boucle, ce
   choix doit s'arrêter et être posé à l'humain. D'où la ligne « tu ne tranches pas » de la
   fiche `tdd-writer`, puis la gravure de chaque décision validée dans la fiche Linear.
3. **Pas de code sans test préalable, prouvé par les commits.** Des tests écrits après le code
   confirment des décisions, ils n'attrapent pas de bugs (Factory). Le producteur est
   `tdd-writer`, l'historique montre le test avant le code, le `verifier` le contrôle. Ça ne
   change rien au parallélisme : le TDD se joue à l'intérieur d'une livraison, le parallélisme
   entre livraisons. Les phrases du contrat, recopiées dans le `MISSION.md`, fournissent les
   premiers tests rouges.

---

## 4. Ce que l'essai a appris

Chaque leçon avec le fait qui la justifie.

**Le premier run complet a tenu (04/09).** Feature « Tableau de bord », deux livraisons de
taille S produites l'une après l'autre, vérifiées ensuite à la main hors de la boucle : 308
tests relancés par un tiers, tous verts ; douze cycles `test:` puis `feat:` dans l'ordre, sans
exception ; aucun test désactivé ni affaibli — les diffs de tests ne contiennent que des ajouts.
Quatre décisions de produit sont remontées au lieu d'être tranchées en chemin. 32 minutes de
travail réel pour un barème qui en prévoyait 30, et **12 minutes d'attente du merge humain** :
le goulot d'étranglement n'est plus l'agent.

Deux réserves. Le `correcteur` ne s'est pas déclenché sur ces deux tours ; il a tourné
l'après-midi même sur « Portail client », deux fois, dont une où il a laissé un défaut et
marqué la PR non mergeable, comme sa fiche le prévoit. Et un run ne prouve pas une méthode : il
faut les quatre ou cinq features d'affilée, sur deux projets, que le backlog n° 10 réclame.

**L'outil vaut mieux que l'agent qui l'imite.** Le `testeur` pilotait le navigateur clic par
clic : 26, 23, 14 et 9 minutes sur quatre passes, jusqu'à 401 échanges et 46 M de jetons relus,
296 appels navigateur. Avec la passe visuelle outillée, la même vérification prend 2,9 et
2,2 minutes, 36 et 28 échanges, 1 M de jetons relus, zéro appel navigateur. Dix fois plus
rapide, quarante fois moins de jetons. Le producteur, lui, n'a pas bougé d'une minute : la
réécriture de sa fiche l'a rendu plus fiable, pas plus rapide. Corollaire vu le 07/09 : ce que
l'outil ne sait pas faire, l'agent le refait à la main au prix fort. La palette ⌘K du
projet CRM ne s'affichait qu'après un raccourci ; l'outil photographiait la page fermée. Le
testeur a écrit deux scripts hors dépôt, brûlé ses quinze actions de navigateur sans ouvrir la
palette, doublé son budget, et rendu un cas « non observé ». L'outil sait maintenant cliquer,
presser une touche, taper et attendre un élément avant la capture. Ce qui coûte cher dans une
boucle d'agents, ce n'est pas de réfléchir, c'est de faire à la main ce qu'un script fait en
dix secondes — et de faire revenir chaque capture d'écran dans la conversation.

**Un chevauchement d'une seule ligne reste un chevauchement.** Les deux livraisons du run
ajoutaient chacune une balise `<script>` à `index.html` et une section à `UAT.md`. Le découpage
les disait indépendantes — c'est vrai de leur code, faux de leur merge. Créer les deux
worktrees d'avance les aurait fait partir du même `main` : les deux lignes au même endroit, un
conflit à démêler à la main. Corrigé dans la fiche du `decoupeur` (le contact se déclare, même
pour une ligne) et dans `produire.md` (un worktree se crée quand son producteur démarre, pas au
début du run).

**Une consigne incomplète se comble en silence (04/09).** Le `correcteur`, éprouvé sur banc
avec six pièges, en passe cinq : il écrit le test avant la correction et le rouge échoue
vraiment, il corrige le défaut visuel sans test et le dit, il ne touche pas à la duplication
que le rapport marque « non retenu » alors qu'elle est à deux lignes de sa correction, il ne
modifie aucun test existant. Le sixième piège était un défaut décrit sans sa cible — « le bouton
n'a pas le bon état au survol », sans dire lequel. Il a choisi un bleu plus foncé, plausible, et
l'a présenté comme une correction ordinaire. Sa fiche disait « ne devine pas » et « arrête-toi
s'il te manque une information » : trop général pour le cas, et impraticable quand quatre autres
défauts restent à traiter. Elle nomme maintenant le cas — un défaut qui ne dit pas ce qu'il
attend va dans « Non corrigé », avec la question qui manque. La leçon vaut au-delà de cet
agent : une règle qui n'a pas de cas nommé ne s'applique pas.

**Une panne silencieuse se cache derrière ce qui marche encore (04/09).** Corollaire trouvé le
même jour : la même panne a laissé quatre tâches isolées affichées « À faire » alors que leurs
PR étaient mergées. Personne ne les fermait — le producteur d'une livraison pose lui-même le
statut de ses tâches, `fix` ne le fait pas et compte sur l'intégration GitHub. Deux agents, deux
comportements, et rien qui rattrape. `sync` traite désormais les tâches sans feature. Ce que la
panne a d'abord montré, c'est l'endroit du circuit où deux mécanismes se relayaient sans que
personne l'ait décidé. Depuis une semaine,
les PR du sandbox ne portaient plus le lien vers leur fiche Linear. Le symptôme paraissait
cosmétique. La cause ne l'était pas : le dépôt avait changé de propriétaire GitHub, et
l'organisation nouvelle n'était pas déclarée dans l'intégration de Linear, qui ne voyait donc
plus aucune de ses PR. Rien n'avait l'air cassé parce que **les statuts de tâche continuaient
d'avancer** : ce n'est pas l'intégration qui les posait, c'est le producteur, via `save_issue`.
Deux mécanismes faisaient le même travail, l'un est tombé, l'autre l'a masqué. La preuve tenait
en un champ : la fiche de la dernière livraison mergée avait `attachments: []`, celle d'il y a
une semaine portait l'URL de sa PR. `sync` contrôle désormais ce champ à chaque réconciliation.

**Le deuxième projet a tenu, et il a donné la vraie vitesse (05/09).** Le projet CRM, un dossier
vide le 04/09 à 18:30 : étude, PRD, direction visuelle, team Linear de 13 features, puis la
feature 1 cadrée, découpée en cinq livraisons, produite, auditée et rétro faite le 05/09, et la
première livraison de la feature 2 mergée à minuit. Sur une vraie pile (Next.js, Postgres,
tests de bout en bout), une livraison coûte **50 à 80 minutes de travail d'agents**, quelle que
soit la taille annoncée — contre 15 sur la page statique du sandbox. Le producteur en prend la
moitié, à écrire un test puis son code, 45 commits par livraison. Rien à gagner là sans casser
l'invariant. Et cinq livraisons sur cinq sont sorties une taille au-dessus de l'annonce : le
barème venait du sandbox, le `decoupeur` lit maintenant ce que la dernière livraison du projet
a coûté en lignes avant de se prononcer.

**Un agent qui attend ressemble à un agent qui travaille (04 et 05/09).** Quatre fois en deux
jours. Sur le sandbox, le testeur bloqué 101 minutes sur `lsof` et `kill`. Sur le projet CRM, le
producteur 73 minutes, le relecteur 152, le correcteur 53 — la livraison 2.1a affichait six
heures d'horloge pour 81 minutes de travail. Chaque fois, l'agent venait de lancer une commande
composée dont un morceau n'était pas dans la liste blanche : `pkill … ; sleep 1 ; curl …`,
`echo … ; git show … | sort`, `lsof … && kill … ; npm run build`. Et chaque fois, personne
devant l'écran pour cliquer. Le pire n'est pas le temps perdu : c'est que le lead, en fin de
run, a écrit « le relecteur a relancé les tests et le build » sans regarder la transcription.
Une cause plausible, fausse, devenue une leçon dans la note du projet et une ligne de six heures
dans la calibration. Trois corrections : la liste blanche de référence porte les morceaux que
les agents glissent dans leurs chaînes (§ 2.4) et les fiches disent « une commande par appel » ;
`cout-agents.py` sépare horloge, temps actif et attente, et nomme la commande avant chaque
attente ; `run` et `sync` ne reportent plus que le temps actif, et un chiffre non mesuré s'écrit
« estimé ». La règle, pour le lead : quand un agent dépasse son seuil, lire ses trous avant
d'écrire une cause.

**Le second projet, quatre livraisons plus tard (07/09).** Les livraisons 2.1b, 2.2 et 2.3 du
projet CRM ont tourné le même jour, 59 minutes, 2 h 15 et 3 h 35 d'horloge. La première est
propre. Les deux autres ont appris trois choses. **La liste des fichiers d'une mission se
déduit du contrat, phrase par phrase** : deux fois, une phrase demandait un écran que la
liste du lead n'ouvrait pas ; le producteur a signalé au lieu de contourner, c'est ce qu'on
lui demande, mais il a fallu le relancer et tout réauditer. **Un producteur relancé ouvre un
second cycle**, avec son audit et sa correction unique : le lead l'a fait sans que la règle
l'ait prévu, et la règle le dit maintenant. **Un testeur ne tue jamais un serveur** : celui
de 2.3 avait lancé `npm run dev` en tâche de fond et l'a arrêté par `kill <pid>` ; le `kill`
n'est revenu qu'au bout de 44 minutes, puis 53 la seconde fois, sans qu'aucune permission
soit en cause (`kill` était autorisé). Le mécanisme n'est pas élucidé, deux cas ne suffisent
pas ; la parade ne dépend pas du mécanisme : l'outil de passe visuelle lance le serveur dans
son propre groupe de processus, attend qu'il réponde, et l'arrête en partant. L'agent ne
touche plus à un processus. Le relevé de coût distingue désormais un agent **bloqué** sur une
commande d'un agent **en veille** après son rapport, qui attend qu'on le relance : le second
cas n'est pas une perte, sauf si le lead tarde.

**La boucle de contrôle coûtait autant que la production (15/09).** Livraison 3.0 du
projet CRM, la première avec les fiches réécrites : producteur 56 min, contrat couvert en une
passe, coût dans la fourchette des livraisons L précédentes (le +58 % du banc du 14/09 ne
s'est pas reproduit). Mais 1 h 48 d'horloge pour ces 56 min. Trois pertes, toutes dans le
contrôle. **Deux serveurs sur un poste se tuent l'un l'autre** : l'outil de passe visuelle
relance le serveur du poste (c'est la parade du 07/09), et le verifier jouait Playwright sur
le même port au même moment ; deux suites rouges en `ECONNREFUSED`, 8 min bloquées, le
verifier relancé à la main. **Le testeur a repassé trois écrans pour rien** : la liste du
correcteur ne contenait aucun défaut d'écran. **La session a relancé le verifier sur le diff
du correcteur** sans que la méthode le demande : sa boucle d'objectif l'a poussée à ajouter
une étape en chemin. Quatre règles posées le soir même (PR #58) : le verifier ne joue que la
suite courte et lit la suite d'écran dans la CI ; un poste, un serveur, le correcteur attend
le rapport du testeur ; repasse seulement si la liste contient un défaut d'écran ; pas de
second audit après correction (`.out-of-scope/second-audit-apres-correction.md`). Cible :
ramener l'horloge d'une L vers 50 min. À mesurer sur 3.1a.

**La production ne ralentit pas, le calendrier si (16/09).** Impression de Cédric : « le pilote
met de plus en plus de temps à développer ». Les chiffres du projet CRM disent autre chose :
de 0,85 à 1,85 h d'agents par livraison depuis le 05/09, sans tendance, sur quinze livraisons.
Ce qui s'allonge est hors des runs : la feature 1 a pris une nuit et un jour, la feature 2
quatre jours de production étalés sur huit, et cinq jours ont séparé la dernière livraison de
la feature 2 de la première de la feature 3 (rétro, refonte de la méthode, jours sans
session). Le cadrage de la feature 3 a pris un après-midi, 41 questions, et n'est mesuré
nulle part. D'où une ligne par feature dans la calibration : calendrier, cadrage, runs,
attente de merge, le reste. Deux autres règles sortent de la même nuit. **Une livraison
fusionnée n'est pas une XL** : 3.1 (deux L produites en une) a coûté 2,92 h, deux fois les
XL d'avant ; elle sort de la médiane, et son producteur se compare au seuil multiplié par
deux. Elle a tenu : une passe, neuf phrases sur neuf, une boucle de contrôle de 49 min au
lieu de deux. **La session du lead s'use** : le 15/09, une seule session a enchaîné sept heures
de commandes, cadrage et deux runs compris, jusqu'à sa fin ; `next` propose désormais une
session neuve avant `run` et `feature`.

**Contre la méthode de Matt Pocock, match nul sur la qualité, défaite sur la dépense (16-17/09).**
Même livraison des deux côtés (4.1 « Leads » du projet CRM, XL avec écrans), même commit de
départ, même entretien de cadrage, même modèle, même juge ; d'un côté `run`, de l'autre ses
skills `to-spec`, `to-tickets` et `implement`, une session neuve par ticket. Les deux tiennent
les 30 phrases du contrat et ont leurs suites vertes ; coût égal, environ 90 $ chacun. Pocock
a relu un quart de jetons en moins et fini 30 minutes plus tôt, sans incident ; notre
producteur a atteint sa limite de 150 tours, et une livraison a été tuée faute de mémoire.
Deux relectures à l'aveugle par version, puis chaque défaut rejoué par un test jetable :
quatre importants chez nous, deux chez lui. Les nôtres sont des règles de décision mal
appliquées — un poste de contact jamais complété, une différence non affichée — que
`MISSION.md` recopiait pourtant, noyées dans un paragraphe de 23 décisions ; ses tickets les
portaient en cases à cocher, une par clause, avec leurs tests. S'y ajoute une course entre
une modification et la conversion qui « dé-convertit » un lead, 20 fois sur 20 : sa revue de
code l'avait vue et corrigée chez lui, notre `verifier` non. Les siens sont des transactions
qui lisent hors transaction et figent l'application sous dix écritures simultanées ; le
même défaut, trouvé ensuite chez nous par le `verifier` réécrit, fige aussi notre conversion
au-delà de dix. Notre
contradicteur a apporté 20 questions utiles sur 24 après un entretien de 27 : lui n'a pas
d'équivalent. Trois changements en sortent, une PR chacun : un producteur neuf par tâche, sur les
seules livraisons XL — rejoué sur l'épreuve TST-B1 (300 lignes), il relisait 43 % de
jetons de plus qu'un producteur unique, chaque session neuve relisant fiche, mission et code ;
des tâches coupées par situation, une case par clause de décision ; deux contrôles de
concurrence au `verifier`. Une relecture fraîche après chaque tâche, comme chez lui, est
écartée : la boucle a été allégée le 15/09 pour son coût.

**Le producteur par tâche coûte : il reste aux seules XL (18-19/09).** Deux mesures sur
le projet CRM, la méthode d'essai installée.
- **4.2a**, XL de 6 400 lignes, un producteur neuf par tâche : aucune coupure, c'était le but.
  Mais 293 M relus et 3 h 41 d'agents, contre 150 M et 2 h 55 pour la 3.1, de taille voisine
  et prise sur la même ligne « Par livraison » de `cout-agents`. Deux de ses quatre tâches ont
  relu 100 M et 96 M : une tâche de livraison XL relit autant qu'une livraison L entière.
  L'écart ne vient pas d'un changement de compteur, contrairement à ce qu'avait écrit le sync
  du 18/09 : la 3.1 était mesurée de la même façon.
- **4.2c**, L de 850 lignes en quatre tâches, un seul producteur, lancée en même temps que la
  4.2b pour servir de témoin : 45 min, 71 M relus, CI verte au premier passage, aucun
  incident. Une L tient dans une session.
D'où le seuil XL, et non L. Ce que la règle achète sur une XL n'est pas de l'économie, c'est
l'absence de coupure : deux livraisons XL avaient été tuées en route les 16 et 17/09, par la
limite de tours puis par la mémoire.

**Tests verts ≠ sûr.** Deux producteurs consciencieux, 32 tests verts, et deux failles
bloquantes (échappement HTML, contrôle de permissions) trouvées uniquement par le relecteur
indépendant. Les deux producteurs avaient reproduit le même défaut d'idiome : seul un œil
extérieur le voit. C'est la découverte n° 1 de l'essai ; la plomberie (worktrees,
permissions) n'était que mécanique.

**Chaque leçon d'audit se grave dans le `CLAUDE.md` du projet.** Les deux failles du matin
sont devenues une section « Idiomes de code » (commit de 21:40). Le soir, huit livraisons qui
manipulaient du texte utilisateur et des mutations ont appliqué ces règles ; les fautes exactes
n'ont pas réapparu, mais une variante (URL de logo non échappée dans un attribut) est passée et
a été attrapée par l'audit. Ce qu'on peut affirmer : le contrat s'enrichit au fil des audits,
et le relecteur reste nécessaire. Ce qu'on ne peut pas affirmer : que c'est la règle écrite,
plutôt que l'imitation du code déjà corrigé que les producteurs avaient sous les yeux, qui a
évité les fautes. Il faudrait l'épreuve comparative (backlog n° 4) pour le savoir.

**Les fiches Linear font le bon métier au bon niveau.** Sur 8 livraisons, aucun agent n'a
livré à côté. La qualité tient sur trois étages : la fiche (intention et résultat observable),
les idiomes du `CLAUDE.md` (exigences transversales), l'audit + l'escalade (ce que ni l'un ni
l'autre ne dit). Une fiche « complète » coûterait plus cher que le code qu'elle décrit.

**Chaque « Terminé quand » doit contenir un constat de refus.** La vingtaine de décisions
remontées et les défauts trouvés à l'audit avaient un motif commun : des cas négatifs (ce qui
doit être refusé) que la fiche ne disait pas. Les fiches qui avaient déjà ce réflexe sont
passées l'audit sans correction.

**Ce qui n'est pas dans la fiche n'existe pas.** L'interface du sandbox est laide parce
qu'aucune fiche n'a commandé du beau. Preuve que les fiches pilotent vraiment. Et personne
dans la boucle ne regarde l'écran : l'audit vérifie la sécurité et la justesse, pas l'œil.

**Le nombre d'agents se déduit, il ne se vise pas.** « Commencer à deux » vient de Cherny ; le
bon nombre = chantiers réellement disjoints × capacité à relire ce qui remonte × budget. Le
soir du 26/08, trois producteurs en parallèle sans incident, parce qu'il y avait trois
livraisons disjointes.

**Parallèle seulement si la disjonction est décidée en amont ; sinon, en série.** Factory
(vidéo 3) a testé dix agents en parallèle sur un même projet et a abandonné : ils se marchent
dessus, dupliquent, prennent des décisions d'architecture incohérentes ; la coordination mange
le gain. Ils exécutent les features une par une et ne parallélisent que les lectures (recherche,
revue). Notre essai a réussi en parallèle parce qu'un humain avait découpé des livraisons
disjointes à l'étape précédente. Les deux sont vrais : le parallélisme est un gain quand la
disjonction est garantie par le découpage, jamais quand on laisse un système découper seul.

**Des PR empilées se mergent dans leur base, pas dans `main`.** Premier `run` réel (Facturation,
27/08, 1 agent à la fois) : chaque worktree avait été créé depuis la branche de la livraison
précédente. Les PR #26 à #29 ont donc été mergées dans la branche d'avant, pas dans `main`, qui
n'a reçu que la livraison 1 ; il a fallu une PR d'intégration (#31). Règle depuis : tout worktree
part de `origin/main`, même en série ; les PR sont indépendantes et se mergent dans n'importe
quel ordre. Si des PR empilées existent quand même : supprimer chaque branche au merge (GitHub
re-cible alors la suivante) ou re-cibler vers `main` avant de merger.

**Un agent = un rôle + un contexte + une durée de vie.** Les producteurs et correcteurs
n'étaient pas des agents installés : des instances jetables de Claude Code, définies par leur
`MISSION.md`. Seul `verifier` avait alors une fiche permanente. **Les six agents en ont une
depuis** (backlog n° 6) : la fiche porte ce qui ne change jamais, le `MISSION.md` ce qui change
d'une livraison à l'autre.

**La boucle complète tient en une instruction.** Le 26/08 soir : « livre X et Y, boucle
complète » → production → audit → corrections → PR, sans sollicitation, verrouillée par la
commande `/goal` avec le critère « PR ouvertes, auditées sans bloquant ni important, tests
verts, décisions listées ». Trois niveaux d'automatisation existent :

| Niveau | Qui enchaîne | État |
|---|---|---|
| 1 | La session principale, en une instruction | Validé |
| 2 | Un agent orchestrateur qui appelle `tdd-writer` puis `verifier` | Non testé |
| 3 | Un workflow encodé (l'enchaînement fixé par du code, pas par un modèle) | À faire |

**Le testeur fait le travail ; l'outillage lui coûte un tiers du temps.** Essai à froid du
28/08 sur la livraison « Recherche et filtres » de Carnet, déjà mergée : compte jetable et
contacts créés par l'interface, 8 cases sur 8 jouées et constatées, console propre, 15 à
20 minutes. Environ un tiers perdu en frictions : `file://` refusé (il faut un serveur local),
deux navigateurs connectés, une extension de mots de passe qui bloque un champ, une session
d'un essai précédent encore ouverte, des captures qui ne survivent pas à la session. Les
trois premières sont réglées dans la fiche ; les autres sont au backlog. Deux cases du
cahier étaient ambiguës (jeu de données non précisé, contact supprimé dans ou hors du
filtre) : même leçon que les « Terminé quand », une case dit sa donnée et son refus.

**Le testeur attrape de vrais défauts, mais pas en jouant le cahier — en regardant l'écran.**
Mesure du 31/08 sur 28 passages de `testeur` (WATIDO, sandbox, PILOT) : sur ~115 cases de
recette déroulées, 108 constatées, et les rares refus portaient souvent sur une case mal
rédigée (« rebuild > 30 s » alors qu'il prend 7 s) plutôt que sur un défaut. Tout ce qui a été
trouvé de réel — huit défauts — venait de la colonne « vu hors cahier » : contour de sélection
invisible (lien `inline` autour d'un SVG `block`, boîtes 0 × 0), bloc de couleur étiré sur toute
la hauteur d'une carte, bouton fixe par-dessus le menu à 375 px, débordement horizontal, titre
caché sous la barre fixe. Aucun n'était visible dans les tests, tous verts, ni dans le diff lu
par `verifier` ; environ une correction sur cinq de la boucle en vient, et chacune a été
verrouillée ensuite par un test. Le rejeu du cahier, lui, coûtait jusqu'à 2,5 min et 4 M jetons
**par case**. D'où la fiche actuelle : la passe visuelle remplace le cahier, le cahier repasse
à l'humain en phase de recette. Contre-épreuve du 31/08 sur le sandbox, nouvelle fiche : 8
minutes, 33 actions navigateur, 6 captures (contre 22 à 36 minutes et ~290 actions pour
l'ancienne), et sept défauts remontés dont trois confirmés dans le code sans ouvrir le
navigateur — aucune règle `:focus` dans la feuille de style, aucun `@media` hors impression.
L'agent a aussi écarté de lui-même un faux positif (un bouton « coupé » qui n'était qu'un
artefact de capture, position mesurée à l'appui).

**Un agent qui n'a pas le droit de lire le code invente sur le code.** Les deux passages du
31/08 ont affirmé, chacun de son côté, que « la feuille de style contient bien une règle
`prefers-color-scheme: dark` mais l'application n'offre pas de bascule ». Vérification : le
projet ne contient aucune règle `prefers-color-scheme`, ni dans sa feuille, ni dans le vendor,
ni dans le HTML — et l'outil le montre sans discuter, l'image sombre étant l'octet pour octet
identique à l'image claire. L'agent avait comblé un trou d'observation par une explication
plausible. La fiche interdit désormais toute affirmation sur le code, et la mesure remplace la
supposition : quand la machine mesure, l'agent n'a plus de trou à combler. C'est la deuxième
raison d'outiller la passe, après le coût.

**Une fiche d'exécution s'écrit à l'envers d'une fiche de jugement.** Les fiches de la boucle
disent *comment faire* : phases numérotées, ordre imposé, gabarit de rapport. C'est ce qu'on veut
d'un agent qui exécute — la reproductibilité est le but. Les deux fiches du cadrage disent *ce qui
fait un bon résultat*, et laissent trouver le chemin. La différence n'est pas cosmétique : une
marche à suivre produit toujours son livrable. Si `decoupeur` avait reçu « rends le tableau des
lots », il aurait rendu un tableau ; il a conclu que cette feature ne se parallélisait pas, chiffré
l'alternative à quatre conflits pour un gain nul, et remonté six décisions produit qu'aucune de ses
consignes ne nommait. Une procédure n'a pas de case « ce que vous me demandez est une mauvaise
idée » ; un mandat, si. Seconde raison, propre au modèle : la documentation d'Anthropic note que
des consignes trop prescriptives, écrites pour les générations précédentes, **font baisser** la
qualité de Fable. Règle retenue : discipline là où l'agent exécute, latitude là où il juge.

**Une règle inventée survit tant que personne ne la vérifie.** L'audit du 01/09 a produit deux
chiffres présentés comme venant de `code.claude.com/docs/en/sub-agents` : « la `description` doit
tenir sous 150 caractères » et « le corps sous 200-500 jetons ». **Vérification du 03/09 : ni l'un
ni l'autre n'est dans cette page.** Elle ne donne aucune limite par fiche. Sa seule limite chiffrée
porte sur la **somme** des descriptions — 15 000 jetons, au-delà desquels Claude Code prévient au
démarrage ; les 27 fiches installées en occupent 6 %. Et sur le corps elle dit l'inverse :
« déplacez le détail dans le prompt système, qui ne se charge que lorsque cet agent tourne ».

Ces deux chiffres allaient faire raccourcir quatre descriptions pour rien. C'est le même motif que
le reste du document, appliqué à la documentation : une affirmation plausible, sourcée en
apparence, que personne n'avait relue. Ce qui reste vrai de cet audit : `name` et `description`
sont les deux seuls champs obligatoires ; une description courte est un bon réflexe, pas une
contrainte de l'outil ; et il existe des champs qu'on ignorait — `maxTurns`, `effort`,
`permissionMode`, `disallowedTools`, `memory`, `skills`, `hooks`, `isolation`.

**Ce que coûte chaque agent, mesuré.** `cout-agents.py` sur les trois projets, moyennes par
agent : producteur 7,5 min, 67 échanges, 3,7 M jetons relus ; correcteur 2,8 min, 26 échanges,
1,1 M ; relecteur 2,6 min, 20 échanges, 0,7 M ; auditeur 2,0 min, 18 échanges, 0,5 M. Le
testeur d'avant : 6,9 min, 96 échanges, 5,3 M, 52 appels de navigateur. Le même écran par la
passe outillée : 2,4 min, 27 échanges, 0,8 M, **zéro** appel de navigateur. Sur le banc
d'essai, l'écart d'un bout à l'autre est d'un facteur 48 sur les jetons relus (39 M pour
`atest-TB1b`, 0,8 M pour `passe-outillee`). Ces chiffres servent de seuils : au-delà du double
de la médiane de son agent, un agent est à regarder, pas forcément à blâmer.

**Un agent ne connaît pas sa dépense, mais il sait compter ses essais.** L'outillage n'expose
aucun compteur de jetons à l'intérieur d'une fiche : un plafond en jetons ne serait pas
observable par celui qui doit le respecter. D'où des points d'arrêt exprimés dans ce que
l'agent voit lui-même — trois essais infructueux sur le même test, dix cycles rouge/vert, une
vingtaine d'échanges pour un audit. C'est moins précis qu'un disjoncteur, mais c'est vérifiable
après coup par `cout-agents.py`, et surtout ça évite le pire : l'agent qui, à force d'insister,
finit par contourner le test au lieu d'échouer proprement.

**L'instrument était le vrai plafond, pas le coût.** L'essai du 31/08 avec le navigateur piloté
par l'extension a buté sur trois des cinq points de la passe : les frappes `Tab` ne parviennent
pas à la page, `resize_window` ne change pas le viewport (bloqué à 1374 px, le repli par iframe
ne rend que l'en-tête), et le thème système est hors de portée. Playwright fixe une largeur
exacte, envoie de vraies frappes, force `colorScheme` et écrit des PNG — les quatre limites
tombent ensemble. Il tourne sur le Chrome déjà installé (`channel: 'chrome'`), donc sans
navigateur à télécharger et sans toucher au profil de l'utilisateur. Sur le tableau de bord du
sandbox, il a nommé le défaut que les deux agents avaient mis 35 actions à approcher :
`button#mailbox-toggle « Boîte aux lettres »`, débordement de 74 px à 375 px. Essai de la fiche
outillée, deux écrans (tableau de bord et agenda) : **0 action de navigateur piloté, 1 min 15 s
de bout en bout, deux défauts remontés** avec leurs valeurs et l'élément fautif nommé, dont un
inédit (à 375 px la semaine de l'agenda est coupée, samedi et dimanche illisibles) — contre 33
et 35 actions pour 8 et 14 minutes sur **un seul** écran avec l'extension. L'agent a joint le
test qui verrouillerait les deux défauts, et il a conclu « il n'y a pas de thème sombre » en
s'appuyant sur l'empreinte identique des deux captures, sans rien avancer sur le code.

**Docilité par contrat, pas par marque de modèle.** L'exécutant a « périmètre STRICT » et
interdiction de réinterpréter ; le relecteur a mandat de contredire. Même modèle partout,
comportements opposés. Le casting par marque (« tel modèle est docile ») est périssable.

---

## 4 bis. Écarts avec les sources

Relecture du 28/08 : ce que les trois vidéos préconisent, contre ce qui est en place.

| Préconisation | Source | Chez nous | Écart |
|---|---|---|---|
| Le contrat (`CLAUDE.md`) | V1 | `CLAUDE.md` + idiomes gravés au fil des audits + `MISSION.md` | Couvert |
| L'examen, tests **et** navigateur | V1 | Tests lancés par le producteur ; `testeur` depuis le 28/08 | Couvert, à inscrire dans `run` |
| Les bacs à sable (worktrees, allowlist, deux agents) | V1 | Rodé, trois producteurs le 26/08 | Couvert |
| La relecture par un agent neuf | V1 | `verifier` | Couvert, découverte n° 1 de l'essai |
| Le test des deux heures (deux chantiers, écran fermé) | V1 | Run Facturation : 1,4 h en une instruction, **un agent, écran ouvert** | Non fait tel quel |
| Pas d'agents en plus avant que la boucle mérite confiance | V1 | Règle « parallèle seulement si disjoint » | Respecté |
| Docilité et effort réglés par agent | V2 | Docilité par contrat ; `effort` posé sur les six agents, `model` sur deux (`fable`) | Couvert le 01/09 |
| Disjoncteurs : budget et accès | V2 | Accès : allowlist ; budget : `maxTurns` sur les six agents, plus un point d'arrêt auto-imposé par fiche | Couvert le 01/09 |
| Recruter un modèle sur épreuve | V2 | `fable` posé sur `decoupeur` et `contradicteur` par jugement, pas par mesure | Backlog 4 |
| Le meneur délègue, ne délègue jamais le jugement | V2, Cognition | Merge humain, décisions remontées | Couvert, invariants |
| Contrat de validation avant le code | V3 | Écrit au cadrage, réparti au découpage, texte recopié dans `MISSION.md`, couverture contrôlée par le `verifier` | Couvert le 02/09 |
| Validateur « testeur utilisateur » | V3 | `testeur` | Couvert, voir backlog 5 |
| Handoff structuré | V3 | Rapport final du `MISSION.md`, audit joint à la PR | Couvert |
| Vue de contrôle (avancement, budget) | V3 | Linear pour l'avancement ; la dépense après coup par le relevé de coût, en direct par le fil de Claude Code lui-même ; l'outil n'ajoute que les alertes (bloqué, seuil) | Couvert |
| Élaguer les consignes tous les six mois | V2 | Aucune date | Backlog 7 |
| Ne pas piloter au compteur de tokens | V1 (critique) | Pas de jauge | Respecté |

Sur un abonnement Max, le disjoncteur de budget ne protège pas l'argent (plafonné) mais le
quota (fenêtre de 5 h, limite hebdomadaire) : un agent en boucle vide la réserve de tous les
autres. L'unité utile n'est donc pas le dollar mais le nombre d'actions et la durée par
mission, imposés par un hook `PreToolUse`. Nécessaire au moment de fermer l'écran, pas avant.

Ordre retenu le 28/08 : `testeur` dans la boucle de chaque livraison, limité aux cases de la
livraison (fait à froid) ; disjoncteur ; épreuve des deux heures sur le sandbox ; seulement
ensuite un second projet (mobile, Maestro) et deux agents en parallèle.

## 5. Backlog des manques avant d'industrialiser

Ce qui a été mis en place relève du **management** (fiches d'agent, docilité par agent,
disjoncteur d'accès, propriété du dispositif). Ce qui manque relève de l'**économie**, de la
**tenue dans le temps** et de la **confiance** nécessaire pour merger moins souvent.

| # | Manque | Pourquoi ça compte | Piste |
|---|---|---|---|
| 1 | Disjoncteur de budget tokens par agent | **En partie traité le 01/09.** Mesure : `.claude/tools/cout-agents/cout-agents.py <projet> --seuils` lit les transcripts de sous-agents et sort le coût par agent (durée, échanges, jetons écrits et relus, appels navigateur), avec les agents au-dessus des seuils. Garde-fous : chaque fiche porte désormais un point d'arrêt qu'un agent peut observer lui-même (`tdd-writer` : trois essais infructueux sur le même test ou dix cycles ; `verifier` : le double d'une vingtaine d'échanges veut dire qu'il a quitté le diff ; `testeur` : 15 actions de navigateur en secours). Le relevé est **automatique en fin de `run`** (étape 7 de la commande) : le tableau part dans la réponse finale et sa dernière ligne dans `.pilot/calibration.md`, avec les agents hors seuils nommés — la dépense n'est visible qu'à ce moment-là, après plus personne ne regarde. **Corrigé le 01/09** : le disjoncteur existe. `maxTurns` dans le frontmatter d'une fiche coupe l'agent après n tours ; il est posé sur les six agents, à environ le double des échanges mesurés (tdd-writer 150, correcteur 80, decoupeur 70, testeur 60, verifier et contradicteur 50). Les points d'arrêt auto-imposés restent utiles : ils font rendre un rapport partiel au lieu d'être coupé net. | `maxTurns` par fiche + mesure automatique en fin de run + arrêt auto-imposé. |
| 2 | Modèle déclaré par agent | **En partie fait le 01/09** : `model:` accepte `opus`, `sonnet`, `haiku`, `fable`, `inherit` ou un identifiant complet. Posé où le choix était évident — `fable` sur `decoupeur` et `contradicteur`, les deux agents de jugement du cadrage, qui tournent une fois par feature sur du texte court (33 et 21 échanges mesurés). **Tranché le 09/09 par le n° 4** : `verifier` passe sur `fable`, fixé dans sa fiche (relecteur, il contredit ; un modèle fixe, pas celui de la session, pour que l'audit ne change pas de niveau avec le réglage du lead) ; `testeur` passe sur `sonnet` en exécutant pur, le jugement sur l'image revenant à l'humain par les écrans dans la PR. `tdd-writer` et `correcteur` passent sur `opus` le 10/09, après le banc du producteur (voir n° 4) ; à confirmer au tour 2 du projet CRM. | Champ `model` dans les fiches. |
| 3 | Effort déclaré par agent | **Fait le 01/09** : `effort` accepte `low` à `max` dans le frontmatter. Posé selon la nature du travail, pas selon l'importance de l'agent — `xhigh` sur les deux agents de jugement (`decoupeur`, `contradicteur`), `high` sur `tdd-writer` et `verifier`, `medium` sur `testeur` depuis qu'un outil mesure à sa place. | Champ `effort` dans les fiches. |
| 4 | Banc d'essai maison | **Fait le 09/09** pour les deux agents candidats à descendre de modèle, le `testeur` et le `verifier` : même livraison du sandbox (TST-91, 531 lignes), même consigne, une fois avec Sonnet et une fois avec le modèle actuel, en même temps. **Verifier** : les deux relancent les tests, trouvent le même commit sans test et le même contrat invérifiable ; le modèle actuel relève en plus deux points réels dans le code (un focus qui ne tombe jamais sur l'erreur de champ, un refus jeté sans affichage), vérifiés, et lit un par un les trois tests modifiés ; Sonnet ne voit ni l'un ni l'autre. Coût égal : 3 min et 24 échanges contre 3 min et 36. **Testeur** : les deux rapportent les trois défauts que l'outil mesure, sans en inventer ; le modèle actuel voit en plus, sur l'image, la barre de navigation empilée sur six lignes qui repousse le contenu de 300 px — le genre de constat pour lequel l'agent existe — mais il a passé trois écrans pour deux demandés. Coût : 6 min et 3,2 M relus contre 5 min et 4,3 M. **Opus, joué ensuite sur le testeur** : il respecte les deux écrans demandés, pose des données plus riches (trois contacts, trois rendez-vous), rapporte les mêmes défauts mesurés et en voit un de plus sur l'image, une année tronquée dans les champs de date (« 09/09/2 »), vérifié ; 4 min, 54 échanges, 3,5 M relus, le coût de Fable pour un prix au jeton plus bas. C'est donc lui qu'on met en face de Fable au banc du `tdd-writer`, pas Sonnet. **Décision (Cédric, le soir même) : le `verifier` passe sur `fable`, fixé dans sa fiche comme les deux agents de jugement du cadrage, et le `testeur` descend sur Sonnet en exécutant pur.** Le verifier est du côté « revue », réflexion maximale selon les sources, et le banc montre ce que Sonnet y perd. Le testeur avait été construit comme un exécutant — l'outil mesure, il recopie — et sa fiche lui avait ajouté une phase de jugement sur l'image ; ce jugement revient à l'humain, qui voit désormais les écrans dans la PR (n° 12). Sonnet recopie les mesures sans faute et n'invente rien : c'est le poste. Le prix : un défaut que seul l'œil voit ne part plus au correcteur dans la boucle, il attend le merge et devient une tâche isolée. **Le `tdd-writer` au banc, le 10/09, Opus contre Fable** : même livraison inventée (« Étiquettes de contact », dix phrases de contrat dont quatre refus), même ordre de mission, deux worktrees au même commit, puis le même verifier sur chaque copie, contrat en main. Opus : 10/10 couverts, rien de bloquant, 4 points mineurs, 23 commits test-avant-code, 11 tests, 235 lignes, 11 min, 107 échanges, 11 M relus. Fable : 10/10, rien de bloquant, 3 points mineurs, 29 commits, 13 tests, 277 lignes, 15 min, 157 échanges, 19 M relus. Mêmes choix de conception, mêmes décisions remontées, même test vert d'emblée signalé. L'hypothèse « un modèle moins capable contourne davantage » ne s'est pas vérifiée : Opus n'a rien contourné, il a fait plus court, 40 % de jetons en moins. Réserve : une épreuve, une page statique. **Décision (Cédric, 10/09) : `tdd-writer` et `correcteur` passent sur `opus`**, à confirmer sur le tour 2 du projet CRM par ce que le verifier trouve dans les PR ; retour à Fable en une ligne si c'est plus qu'avant. | Fait. |
| 4 bis | Le `correcteur` éprouvé | **Fait le 04/09.** Banc à six pièges : 5 sur 6. Réussis : test avant correction avec un rouge réel, défaut visuel corrigé sans test et signalé comme tel, liste fermée respectée alors que la duplication était dans un fichier ouvert à deux lignes de la correction, aucun test existant modifié, suite complète relancée. Raté : un défaut décrit sans sa cible — il a inventé la valeur au lieu de poser la question. Fiche corrigée le jour même. | Fait. Tourné en run réel le 04/09 sur le sandbox (3 sur 3 puis 3 sur 4 corrigés, PR marquée non mergeable comme prévu) et cinq fois sur le projet CRM le 05/09, sans jamais élargir sa liste. |
| 4 ter | Le `tdd-writer` et l'existant | **Fait le 09/09.** Un producteur ne regarde pas ce que le dépôt sait déjà faire : il redéveloppe. Banc à quatre runs, même livraison inventée sur le sandbox (« Journal d'activité »), deux worktrees sans la consigne et deux avec, un seul écart entre les fiches. Résultat reproduit : **sans, le format `JJ/MM/AAAA à HH:MM` est réécrit à la main deux fois sur deux ; avec, `Appointments.label` est retrouvé et appelé deux fois sur deux** — un troisième exemplaire d'une duplication déjà présente dans le dépôt évité. Deux choses ne tiennent pas : la consigne ne réduit pas le volume de code (47, 40 sans ; 36, 51 avec) et ne fait pas gagner de temps — l'écart de coût du premier couple était de la variance, l'écart entre deux runs identiques étant du même ordre que l'écart entre les deux groupes. Ce qu'on peut dire : elle ne coûte pas plus cher, et elle fait réutiliser. La fiche porte la recherche en **phase de lecture**, une seule passe, deux ou trois recherches par critère, et une section `### Réutilisé` au rapport qui rend l'effet lisible. | Fait. À revoir en run réel. |
| 5 | Validation de bout en bout | **Fait le 02/09.** La passe visuelle est inscrite dans `run` (étape 4) et dans la fiche du `testeur` ; la moitié « gabarit `MISSION.md` » est devenue sans objet depuis le partage fiche / mission — le moule ne porte plus que le variable. Tranché le 31/08 : **`UAT.md` est le cahier de recette de l'humain**, qu'il déroule lui-même avant mise en ligne ; aucun agent ne le joue ni ne le coche. Le producteur continue de l'écrire (une case par « Terminé quand », non cochée), pour un lecteur qui ne connaît pas le code ; un état vierge de l'application avant chaque passage ; l'instrument mobile (Maestro sur simulateur) au premier projet mobile. Voir aussi 11 et 12. | Section `## Pilot` : `Lancer l'app :`, `Testeur :`. Rapport de `run` en deux colonnes : prouvé (tests, audit, cases jouées) / à relire (esthétique, non testable). |
| 6 | Fiche `producteur` permanente | **Fait le 02/09.** `tdd-writer.md` porte désormais les invariants de la boucle : périmètre strict, « tu ne tranches pas », `UAT.md`, URL des écrans, push, PR, STOP, format du rapport. Le gabarit `MISSION.md` a été allégé d'autant : il ne porte plus que la partie variable. Éprouvé sur banc le 01/09 — l'agent a refusé un piège de périmètre et remonté une décision au lieu de la trancher, alors que son `MISSION.md` était muet sur les deux. | Fait. |
| 7 | Élaguer les consignes tous les six mois | **Première passe faite les 01 et 02/09.** `SKILL.md` : 597 → 276 lignes, le détail des commandes sorti dans `reference/cadrer.md`, `produire.md`, `suivre.md`. Douze règles retirées du moule de mission, quatre définitions de `section-pilot.md`, les six fiches réécrites. Prochaine passe à prévoir vers mars 2027. | Relire `CLAUDE.md` et skills : retirer ce qui tient debout tout seul. |
| 8 | Contrat de validation à l'échelle de la feature | **Fait le 02/09.** La chaîne est complète : le contrat s'écrit au cadrage (10 à 30 phrases, un tiers de refus), le découpage affecte chaque phrase à une livraison, `MISSION.md` en porte **le texte** et plus seulement les numéros, et le `verifier` contrôle qu'un test couvre chacune. Le maillon qui manquait était le texte dans `MISSION.md` : sans lui, le `verifier` lisait « numéros 4, 5, 6 » et n'avait rien à vérifier. _Constat d'origine :_ nos « Terminé quand » étaient par tâche, jamais consolidés. Factory écrit avant tout code la liste de « ce qui devra être vrai », chaque feature devant couvrir ses phrases ; des tests écrits après le code « confirment des décisions, ils n'attrapent pas de bugs ». Prévu à l'étape « Cadrer » du circuit. | Section de la fiche feature Linear ; le découpage affecte chaque phrase à une livraison ; `verifier` contrôle la couverture. |
| 9 | Vue de contrôle | **En partie traité le 01/09** par `cout-agents.py` : après coup, le coût par agent et les agents à regarder. **Depuis le 07/09** il sépare horloge, temps actif et attente, nomme la commande avant chaque attente de plus de cinq minutes, et retrouve les transcripts par leur dossier de travail même si la session a été lancée d'ailleurs. **Le direct, en trois temps.** Le 09/09, `--direct` affichait un tableau résumé par agent dans un second terminal ; le 10/09 Cédric a montré que Claude Code affiche déjà cela sur la ligne de chaque agent, en bas du fil, et le tableau a été retiré. Ce que Claude Code ne donne pas pour un sous-agent, c'est le déroulé : ce qu'il fait, au fil du temps. Ce que Cédric veut voir, c'est ce déroulé **en grandes étapes et en français, pas en code**, sans intervenir. **Fait le 10/09** : `--suivre` lit les journaux que les agents écrivent en direct et n'en garde que les phrases que l'agent écrit entre deux commandes, plus trois repères mécaniques (commit test ou code, résultat des tests, PR ouverte) ; un bloc par agent, jamais entremêlés. Pour que les phrases soient régulières, la fiche du producteur et celle du correcteur demandent une phrase en français avant chaque critère attaqué. **Le panneau s'ouvre tout seul** : un hook `SubagentStart`, posé dans `.claude/settings.json` par `install.sh`, lance `panneau-agent.sh`, qui ouvre un panneau cmux avec le flux de l'agent qui démarre et le referme quand l'agent a rendu ; vérifié sur une session isolée, panneau ouvert huit secondes après le lancement. Sans cmux, rien ne s'ouvre. `--direct --notifier` reste pour les alertes (bloqué, seuil). Réserve : le format des journaux est interne à Claude Code, le relevé de coût et le suivi tomberaient ensemble à un changement. Leçon : regarder ce que l'écran montre déjà, et demander ce que l'humain veut voir, avant de construire un affichage. | Fait. Le n° 10 s'appuiera sur cette lecture pour décider seul de continuer ou de s'arrêter. |
| 10 | Reprise automatique après audit | Chez nous : audit → corrections → PR, puis stop. Ailleurs, on enchaîne des jalons regroupant plusieurs livraisons sans humain — c'est ce qui autorise « un merge par feature » au lieu d'un par livraison. **Les conditions n° 1 et n° 5 sont levées depuis le 02/09**, mais on n'ouvre pas ce chantier tant que le flux n'a pas fait ses preuves : quatre ou cinq features d'affilée, sur au moins deux projets, avec les cinq constats de l'étape de validation (aucune demande à un humain, aucune sortie de périmètre, tests relancés par le `verifier`, aucune correction manuelle en cours de run, coût dans les repères). **Compteur au 07/09 : deux features terminées, deux en cours, sur deux projets** — « Tableau de bord » et « Portail client » (2 livraisons sur 3) sur le sandbox, la feature 1 et la feature 2 (1 livraison sur 9) sur le projet CRM. Quatre constats sur cinq tiennent ; le cinquième, le coût dans les repères, a échoué sur le projet CRM parce que les repères venaient du sandbox et que les attentes de permission passaient pour du travail (leçon ci-dessus). À rejouer avec la liste blanche complétée. Et il manquera encore le n° 9 : enchaîner trois livraisons sans rien voir de ce qui se passe est le cas exact que le merge humain protège. | Après validation du flux sur plusieurs features et plusieurs projets, puis n° 9. |
| 11 | Profil de navigateur dédié aux tests | **Devenu marginal le 31/08** : la passe visuelle tourne sans fenêtre et sans profil utilisateur, donc aucune extension tierce ne peut la bloquer. Le besoin ne subsiste que pour le navigateur piloté gardé en secours (parcours interactif, formulaire à soumettre). | Créer le profil le jour où le secours servira vraiment. |
| 12 | Captures durables | **Résolu le 31/08.** La passe visuelle passe par Playwright (`.claude/tools/passe-visuelle/passe-visuelle.mjs`, Chrome du système, rien à télécharger) : elle écrit ses images en fichiers dans `.pilot/recette/<date>-<écran>/` (dossier ignoré de git) et un `mesures.json` à côté. **Dans la PR depuis le 09/09** : l'option `--pr` écrit en plus une image légère par écran (1280 px, clair, JPEG, 2000 px de haut au plus, autour de 50 Ko) dans `.pilot/pr/<CODE>/`, que le lead commite dans la branche après l'audit et affiche dans le rapport de PR, section « Écrans ». L'humain voit l'écran tel que l'agent l'a vu, sans lancer l'application. Les quatre PNG de mesure restent locaux. | Fait. |
| 13 | Recherche et contradicteur au cadrage (repris de FORGE, phase FIND) | **Contradicteur fait le 01/09** : fiche `contradicteur`, appelée par `feature` avant la validation du cadrage et par `roadmap` sur la liste proposée. Premier passage sur une feature réelle du sandbox : trois bloquants (un renvoi vers une page qui n'est pas publique, un lien de paiement qui ne peut pas toujours être construit, une livraison non démontrable seule) et six décisions manquantes, tous vérifiés dans le code, en 21 échanges. **Recherche tranchée le 02/09.** Au **PRD** : `init` lance la skill `research-assistant` avant l'entretien — ce qui existe, les standards du domaine, les règles extérieures qui s'imposent ; le document va dans `.pilot/recherche.md`. Systématique, sans question préalable : au moment du PRD personne ne sait encore rien, et une supposition posée là se paie sur toute la roadmap. Au **cadrage d'une feature** : pas de recherche (décision de Cédric). Les questions y sont internes au produit, pas externes ; `WebSearch` et `WebFetch` ont été retirés des outils du `contradicteur`. | Fait. |
| 14 | Le coût par résultat accepté, et la taxe de coordination | **Fait le 13/09**, à partir d'une vidéo sur la loi de Brooks appliquée aux agents (Cursor : 70 000 conflits puis moins de 1 000 avec cinq règles de vie, mêmes modèles) et d'un constat : le relevé comptait les agents, jamais le lead, et donnait un coût par agent, jamais par livraison. Le relevé sort désormais **une ligne par livraison** — tous ses agents, corrections et repasses comprises : minutes actives, jetons, tours de correction, horloge — et **une ligne par run pour le lead**, lue dans le journal de sa session entre le premier agent lancé et le dernier rapport. Sur le projet CRM, le lead pèse 16 à 24 % des jetons d'un run, et le tour à deux producteurs n'a pas fait monter cette part (19 %). C'est la jauge pour « trois producteurs » : si la part du lead monte, la coordination mange le gain. Au passage, le verifier vérifie aussi que chaque décision produit de la mission est appliquée dans le code, pas seulement que chaque phrase du contrat a son test (règle Cursor n° 1 : une décision écrite que le code doit citer). Les autres règles Cursor sont couvertes autrement ou volontairement écartées : arbitrage par un tiers (verifier, merge humain) ; fichier trop gros gelé (rien, mineur à deux agents) ; sortie de périmètre avec un mot (interdite chez nous, l'agent s'arrête) ; carnet de bord (rapports de PR, idiomes, leçons ici, méthode modifiée par PR). | Fait. |
| 15 | La méthode relue à la manière de Matt Pocock | **Fait le 14/09**, en six chantiers d'une PR chacun (#44 à #56) : une grille de relecture en huit questions (`GRILLE-DE-RELECTURE.md`) tirée de sa skill `writing-for-agents` ; le verrou git ; trois skills importées telles quelles ; `pilot/SKILL.md` de 3 420 à 1 327 mots avec ses règles rangées dans `reference/` ; l'entretien par rounds, les trois mauvais tests, les douze odeurs, `CONTEXT.md` et les ADR ; les six fiches d'agent relues bloc par bloc (`.workflow/relectures/`), le `tdd-writer` rejoué au banc TST-B1 (même qualité, rapport plus riche, coût à confirmer). Contre-épreuve : le bloc commun des fiches réduit d'un tiers fait signer 28 commits sur 28 ; il reste entier. Analyse complète : `sources/analyse-repo-2026-09-14-mattpocock-skills.md`. | Fait. |
| 16 | Jev comme outil de tri, pas comme agent | **Noté le 21/09, pas commencé.** Jev (TypeSafe AI, modèle « System One ») ne rédige pas : il choisit parmi des options connues et donne sa confiance, en 70 à 500 ms, pour 0,042 $ le million de jetons en entrée (chiffres annoncés, non mesurés). Il ne remplace aucun des six agents, qui raisonnent et rédigent ; il peut devenir un outil qu'ils appellent, comme `passe-visuelle`. Quatre places, par ordre d'intérêt : **1. Passe exploratoire à côté du `testeur`** : Playwright clique, le code détecte le certain (erreur 500, console, page blanche), Jev choisit le geste suivant en jouant des utilisateurs difficiles (impatient, négligent, URL trafiquée), avec des valeurs piégées préparées d'avance ; tous les écrans de la livraison au lieu de trois. Un signal de Jev n'entre au rapport que rejoué et prouvé par une trace. **2. Tri « déjà connu / nouveau »** des défauts du `testeur` contre la liste ouverte (un défaut rapporté trois fois a lancé trois fois le `correcteur`). **3. Carte « contrat → tests »** préparée pour le `verifier`, qui contrôle d'abord les associations douteuses. **4. Tri d'une CI rouge** (instable, régression, environnement) ; un LLM classique ferait aussi bien. Exclu : Jev dans les suites de tests (non déterministe, casse le rouge-vert) ; Jev dans une décision qui laisse passer (il ajoute un signal, jamais n'en retire). Accès : OpenRouter en bêta (`typesafe/jev-1.13`), sans liste d'attente. Référence externe : `DowLucas/browser-jev` (MIT, non audité), d'après le cas de Rafal Wilinski. Réserves : français non documenté ; limites connues de jev-1.13 (dates, comptage, contenu piégé, état trop gros). | Prototyper `passe-exploratoire` hors du dépôt, clé plafonnée ; mesurer sur le projet CRM contre les défauts connus du banc 1 (trouvés en plus, fausses alertes) ; si concluant, PR ici puis banc TST-B1. Après le dev en cours. |

---

## 6. Où vivent les choses

**Dans ce dépôt** (`~/Desktop/PILOT`)

| Quoi | Où |
|---|---|
| La méthode expliquée — ce document | `BOUCLE-AGENTS.md` |
| Le circuit complet, présentable à un client | `PILOTAGE-LINEAR-GITHUB-CLAUDE.md` et sa version visuelle `circuit-linear-github-claude.html` |
| Analyse critique des vidéos sources | `sources/analyse-videos-2026-08-26.md`, `sources/analyse-video-2026-08-27-factory-missions.md` |
| Comptes rendus de session | `.workflow/sessions/` |

**Dans `implementation/`** — ce qui s'exécute

| Quoi | Où |
|---|---|
| Les six fiches d'agent | `agents/` : `tdd-writer.md`, `verifier.md`, `testeur.md`, `correcteur.md`, `decoupeur.md`, `contradicteur.md` |
| Ce qu'est un bon test et les trois mauvais (lu par `tdd-writer` et `verifier`) ; les douze odeurs de code de Fowler (lu par `verifier`) | `skills/pilot/reference/tests.md`, `smells.md` (repris de `tdd` et `code-review`, 14/09) |
| Ce qu'un agent fait d'un système de design (`.pilot/design/`), lu par `tdd-writer`, `verifier` et `testeur` quand il existe | `skills/pilot/reference/design-agents.md` |
| Les relectures des fiches avec la grille, bloc par bloc, et leurs épreuves | `.workflow/relectures/2026-09-14-*.md` |
| Les commandes de pilotage | `skills/pilot/SKILL.md` — règles communes et résumé des neuf commandes |
| Le détail des commandes | `skills/pilot/reference/cadrer.md`, `produire.md`, `suivre.md` |
| Les règles communes aux commandes : le moule des fiches, tailles, priorités, dates ; l'outil Linear (MCP, API, workspaces, initiatives, frise) ; git (branches, release, gabarit de PR, verrou) ; l'entretien de cadrage par rounds | `skills/pilot/reference/fiches.md`, `linear.md`, `git.md` (sortis de `SKILL.md` le 14/09 avec la grille), `entretien.md` (repris de `grilling`) |
| Comment s'écrit une fiche d'agent | `skills/pilot/reference/AGENT.template.md` |
| Le moule d'ordre de mission | `skills/pilot/reference/MISSION.template.md` |
| Les moules de fiche Linear | `skills/pilot/reference/template-feature.md`, `template-tache.md`, `template-bug.md` |
| Le moule de configuration d'un projet | `skills/pilot/reference/section-pilot.md` |
| Les scripts | `skills/pilot/scripts/` : `init_team.py`, `linear_api.py`, `schedule.py`, `benchmark.py` |
| La recherche préalable au PRD | `skills/research-assistant/SKILL.md` |
| Le glossaire du produit (`CONTEXT.md`, posé par `init`, affûté au cadrage) et les ADR (gravées par `sync` au merge, trois conditions) ; les sept questions de relecture des audits | `skills/pilot/reference/domaine.md` (repris de `domain-modeling`), `suivre.md` § `sync` Apprendre (repris de `retro`) |
| Trois skills importées telles quelles de `mattpocock/skills` 1.2.3 (corps en anglais, déclencheurs français) : le diagnostic d'un bug dur, la résolution d'un conflit de merge, le questionnaire au client | `skills/diagnosing-bugs/`, `skills/resolving-merge-conflicts/`, `skills/to-questionnaire/` ; appelées depuis `fix`, le merge, et le cadrage d'une feature |
| La passe visuelle | `tools/passe-visuelle/passe-visuelle.mjs` (Playwright sur le Chrome du système) |
| Le relevé de coût, le suivi des étapes d'un agent (`--suivre`), les alertes (`--direct --notifier`) | `tools/cout-agents/cout-agents.py` |
| Le panneau cmux ouvert à chaque agent lancé (hook `SubagentStart`) | `tools/cout-agents/panneau-agent.sh`, posé dans `.claude/settings.json` par `install.sh` |
| Le verrou git (hook `PreToolUse` sur Bash) : refuse le push vers `main`/`master`/`release`, le push forcé, `gh pr merge`, le merge depuis une branche protégée | `tools/verrou-git/verrou-git.py`, posé dans `.claude/settings.json` par `install.sh` ; épreuve `test_verrou.py` |
| Ce qui reste personnel | `global/` : le `CLAUDE.md` de préférences et la skill `rendu-fonctionnel`, copiés à la main dans `~/.claude/` |

**Dans chaque projet piloté** — la copie qui travaille

`./install.sh <projet>` pose `agents/`, `skills/` et `tools/` dans le `.claude/` du projet,
avec un `METHODE.md` qui note la version installée. Cette copie est versionnée avec le projet :
tous ceux qui le clonent travaillent avec la même méthode, et l'historique du projet montre
quelle version a produit quel code.

**La copie ne se modifie jamais.** Une amélioration se fait ici, sur une branche, avec une PR.
Le projet la reçoit quand il relance `install.sh`.

**Sur le banc d'essai** (`cedricgicquiaud/pilotage-sandbox`)

L'allowlist, un `CLAUDE.md` d'exemple, et `.pilot/MISSION.template.md` adapté au projet — le
moule porte les idiomes et la commande de tests du dépôt, à reporter quand le moule de
référence change.
