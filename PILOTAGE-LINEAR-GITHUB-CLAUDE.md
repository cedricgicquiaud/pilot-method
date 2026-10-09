# Pilotage de projet avec Linear, GitHub et Claude

Méthode de gestion de projet logiciel pour une personne seule ou une petite
équipe, quand le développement est réalisé par Claude Code. Ce document est
générique : il s'applique à n'importe quel dépôt, avec ou sans workflow de
développement structuré.

Il est en deux parties :

- **Partie A — Tronc commun.** La couche de gestion de projet, indépendante de
  toute méthode de développement.
- **Partie B — Ce que Claude fait entre vos validations.** Le circuit d'une
  feature, vos commandes, et ce qui reste volontairement manuel.

---

# Partie A — Tronc commun

## 1. Le principe en trois phrases

- **Linear** est le tableau de bord : roadmap, features, tâches, statuts.
  C'est l'écran que l'humain regarde.
- **GitHub** est l'atelier : code, branches, pull requests, tests.
  On n'y va que pour relire du code et merger.
- **Claude** est l'ouvrier : il lit le travail dans Linear, écrit le code dans
  GitHub, ouvre la PR, et met Linear à jour en chemin.

Une seule règle fait tenir l'ensemble : **le code Linear d'une tâche
(`ABC-12`) voyage dans le nom de la branche et le titre de la PR.** C'est ce qui
permet à Linear de reconnaître ses tâches dans ce que fait GitHub, et de les faire
avancer sans intervention — les tâches seulement ; les statuts de feature restent
posés par Claude (§ 5). Rien n'est à configurer côté GitHub : tout se passe dans
Linear. Cette règle ne dépend d'aucune méthode de développement.

---

## 2. Qui parle à qui

```
            lit le backlog,                    crée la branche,
            coche les tâches                   pousse le code, ouvre la PR
   Linear  <──────────────── Claude ────────────────────────────>  GitHub
     ^                                                               │
     │        branche poussée → tâche « En cours »                    │
     │        PR ouverte      → tâche « En revue »                    │
     └────────────────────────────────────────────────────────────────┘
              PR mergée      → tâche « Terminée »
              (automatique, via l'intégration GitHub de Linear)
```

- Claude écrit dans les deux outils.
- GitHub prévient Linear tout seul quand une PR change d'état, **pour les
  tâches**. Il ne touche jamais au statut d'une feature : c'est Claude qui le
  pose (« En revue » quand il ouvre la PR, « Terminée » quand il constate le
  merge à sa session suivante). La barre de progression de la feature, elle,
  se remplit seule à mesure que ses tâches se ferment.
- Linear ne contient aucun code. GitHub ne sert pas au suivi.
- Personne ne déclenche Claude sauf l'humain (voir § 9 pour les variantes).

---

## 3. Vocabulaire : quatre étages

C'est la gestion de projet classique, en quatre étages : le projet, ses
grandes fonctionnalités, les livraisons de chaque fonctionnalité, les tâches.
Le vocabulaire de Linear prête à confusion : ce qu'il appelle « projet »
n'est pas le projet au sens courant, mais une feature.

| Linear dit | On dit | Ce que c'est | Durée |
|---|---|---|---|
| Initiative | Cap | Un objectif de fond regroupant plusieurs features allant dans la même direction : une version (« V1 — la liste qui marche ») ou un thème (« Authentification »). Disponible en gratuit (vérifié). Étage supérieur de la roadmap. | Mois |
| Project | **Feature** | Une grande fonctionnalité (« Authentification », « Partage de listes »), décrite à l'utilisateur. **Une barre sur la roadmap.** Livrée en une ou plusieurs PR. | Semaines |
| Milestone (jalon) | **Livraison** | Une partie livrable d'une feature = **une branche, une PR** (« Écran d'inscription », « Mot de passe oublié »). Une petite feature n'a qu'une livraison. | Jours |
| Issue | **Tâche** | Une étape d'une livraison. Rattachée à une feature et à sa livraison, ou isolée (voir § 4). | Heures |

Et au-dessus des trois : la **Team** Linear, c'est **le projet** au sens
courant (un dépôt, un produit), avec sa clé à trois lettres (`ABC`). Le plan
gratuit en permet deux par workspace (§ 12).

### Feature, livraison ou initiative ?

Le critère est la taille. Une **livraison** se merge d'un coup, en une PR, en
quelques heures de session. Une **feature** regroupe les livraisons d'une même
fonctionnalité et s'étale sur des jours ou des semaines : c'est l'unité de la
roadmap. Une **initiative** regroupe des features (une version, un thème) ;
elle ne sert que sur un gros projet.

Exemple : « Authentification » est une feature ; ses livraisons sont « écran
d'inscription », « connexion », « mot de passe oublié » ; chaque livraison a
ses tâches (formulaire, validation, e-mail, tests).

Règle pratique : une feature trop petite pour avoir plusieurs livraisons fait
une mauvaise barre de roadmap, on la regroupe ; une feature de plus de six
livraisons se coupe en deux.

### La roadmap

La roadmap est la vue des **features** sur une frise (Projects → Display →
Timeline). Chaque barre va de sa première à sa dernière livraison, porte ses
jalons en repères, et affiche un pourcentage calculé d'après ses tâches
terminées. Le pourcentage s'affiche sur la barre quand la propriété « Milestones » est
désactivée, les jalons quand elle est activée (pas les deux) ; une tâche en
cours compte pour un quart. Les tâches n'y apparaissent pas. Si des initiatives existent, les
barres sont regroupées par initiative (Group by → Initiative) ; une initiative
n'a pas de barre propre.

---

## 4. Deux façons de travailler : feature ou tâche isolée

Tout le travail n'entre pas dans une feature. Un bug, une correction de
documentation, un réglage : ce sont des **tâches isolées**, sans feature, qui
ne passent par aucun cadrage.

| | Feature | Tâche isolée |
|---|---|---|
| Ce que c'est | Une grande fonctionnalité, en une ou plusieurs livraisons | Une correction ou un petit ajustement |
| Taille | Des jours à des semaines, plusieurs PR | Moins d'une heure, une seule PR |
| Cadrage | Livraisons posées à la roadmap ; tâches découpées livraison par livraison | Aucun : le titre de la tâche suffit |
| Branche | `feature/<CODE>-<n° de la première tâche>-<nom>` | `fix/<CODE>-<n°>-<nom>` ou `chore/<CODE>-<n°>-<nom>` |
| PR | Une par livraison. Titre `<CODE>-<n°> <titre de la livraison>` ; description au gabarit (§ 7) terminée par `Closes <CODE>-a, <CODE>-b` | Titre `<CODE>-<n°> <titre>` ; même gabarit sans la ligne Feature |
| Sur la roadmap | Oui | Non (visible dans le backlog et le kanban) |
| Statut mis à jour par GitHub | Les tâches ; la feature est posée par Claude | La tâche elle-même |
| Taille | S / M / L / XL (§ 4 bis) | — |

Le critère de bascule : **si ça change ce que l'utilisateur peut faire, c'est
une feature.** Sinon, c'est une tâche isolée, même si elle prend un peu de
temps. En cas de doute, tâche isolée ; on la promeut en feature si elle grossit.

Claude traite une tâche isolée en un seul geste : branche, correction, tests,
PR. Pas de description préalable, pas de plan.

---

## 4 bis. Le cadrage : la roadmap dès le premier jour

Dès que le projet est cadré (PRD, spécification, README, plan validé), **toutes
ses features sont posées dans Linear avec leurs livraisons** (jalons datés), au
statut « À cadrer », sans aucune tâche. La roadmap est complète dès le premier
jour, toutes les barres à 0 %.

Les tâches d'une feature ne s'écrivent qu'à son ouverture, mais alors
**toutes d'un coup, pour toutes ses livraisons** : c'est ce que Linear attend
pour calculer un avancement juste (tâches terminées sur tâches de la feature),
qui monte sans jamais redescendre. Règle de la longue-vue entre les features :
**plus c'est proche, plus c'est net.** Détailler aujourd'hui une feature qui
s'ouvrira dans trois mois, c'est du travail jeté ; mais une feature ouverte se
découpe entièrement.

### Proposer, valider, créer

Rien ne se crée dans Linear avant validation humaine. Claude propose un
**squelette** (titres + une ligne chacun), l'humain fusionne, coupe, rejette,
reformule, puis dit « validé ». Alors seulement Claude crée. Grille de
jugement : un résultat par titre ? pas de doublon avec l'existant ? tout le
cadrage est couvert ? rien d'inventé hors cadrage ?

Vérification à l'échelle : **compter** (annoncé par Claude / présent dans
Linear) et **sonder** deux fiches au hasard.

### Le moule d'une fiche

Une fiche se lit en trente secondes et personne n'a besoin de poser de
question. Les templates de la team l'imposent aux humains ; la section
Pilotage (§ 10) l'impose à Claude.

- **Titre** : court, 5 à 6 mots, comme une étiquette : « Case à cocher par
  tâche », « Export CSV », « Écran d'inscription ». Ni phrase ni roman : le
  résultat vérifiable se lit dans « Terminé quand », pas dans le titre.
- **Description en trois temps** : le problème (ce qui manque ou gêne),
  l'action (ce qu'on fait, sans le comment), « Terminé quand » (des constats
  observables, en cases à cocher). Pour une feature : problème, comportement
  attendu, terminé quand, lien vers la recette. Pour un bug : reproduction,
  attendu, obtenu, terminé quand.
- **Granularité** : une tâche promet un résultat livrable en quelques jours au
  plus. Trop grosse → feature ou sous-tâches. Trop fine → une case à cocher.

### La charge : des tailles, pas des heures

Chaque livraison porte une **taille** S / M / L / XL (et la feature, le label de
sa somme),
posée par Claude avec une justification d'une ligne et corrigeable. Jamais
d'heures : le chiffre aurait l'air précis et serait faux.

Un **barème** traduit les tailles en durées : il est produit une fois à partir
de l'historique des dépôts (premier commit → PR ouverte = temps de Claude ;
PR ouverte → merge = temps d'attente humaine ; nombre d'allers-retours), puis
**recalibré automatiquement** à chaque feature terminée. La **capacité**
humaine (délai médian de merge observé, corrigeable à la main quand le rythme
va changer) complète le calcul.

Le barème ne mesure que la production. À la fin de chaque feature, une ligne de plus dit
où est passé le reste du calendrier : le cadrage, les runs, l'attente de merge, et le reste
(jours sans session, travail sur la méthode, tâches isolées). Exemple : si une feature prend
huit jours pour quatre heures de runs, c'est cette ligne qui dit si le cadrage ou l'attente a
grossi.

Ordre validé × barème × capacité = une date par livraison, donc une fenêtre de
début et de fin par feature.
La roadmap est plausible, pas promise ; elle se recale à chaque livraison.

### Dépendances, décisions et glissements

Trois règles gouvernent ce qui s'enchaîne et ce qui glisse.

**Les dépendances sont rares et réelles.** Le test : « si on inversait
l'ordre, est-ce que ça casse, ou est-ce que c'est juste bizarre ? » Ça casse →
on pose la relation dans Linear (entre tâches : « Bloquée par », cadenas et
avertissement ; entre features : la fin de l'une s'accroche au début de
l'autre sur la frise). C'est juste bizarre → simple file de passage, les
dates suffisent. Une relation posée « par réflexe » encode le planning au
lieu de la logique, et devient du bruit à entretenir. Cas limite : une
feature qui dépend d'une simple **tâche** (une décision, un achat, un accès
à obtenir) — Linear ne sait pas le représenter ; la tâche reste isolée, avec
une échéance, et la fiche de chaque feature conditionnée la cite.

**La frise montre le scénario retenu.** Le plan auquel on croit est daté,
même derrière une décision pas encore prise — on ne retire jamais ses dates.
L'autre branche existe en **réserve** : des features visibles, sans aucune
date, prêtes à être datées si la décision bascule. La fiche de la
tâche-décision décrit les deux branches : ce qui s'annule, ce qui se date à
la place. C'est l'alerte (« la décision X a n jours de retard, m features en
dépendent »), pas l'absence de dates, qui rappelle que le plan est
conditionnel.

**La réconciliation recale et raconte.** Linear ne décale jamais une date
tout seul : il signale les conflits, c'est tout — une date est un engagement
humain, pas un calcul. C'est la réconciliation (jouée à chaque session) qui
replanifie : elle recale toutes les fenêtres selon la capacité observée,
jamais une feature avant la fin de sa bloquante, puis **ouvre par le récit** :
ce qui a été décalé, la nouvelle fin de plan, et — si le projet déclare une
date butoir — la **marge restante**. Sur un projet à échéance fixe, un
glissement ne pose jamais la question « quand ? » mais « qu'est-ce qu'on
coupe ? » : quand la marge devient négative, c'est le périmètre qui doit
bouger, et le récit le dit en ces termes.

---

## 5. Statuts

### Statuts de feature

Une feature traverse ces statuts dans l'ordre, une seule fois. Ils décrivent
n'importe quel développement, quelle que soit la méthode :

| Statut | Ce que ça veut dire | Qui le pose |
|---|---|---|
| À cadrer | Posée sur la roadmap au cadrage, pas encore découpée | Claude, à la roadmap |
| Planifiée | Les tâches sont listées et validées | Claude |
| En développement | La branche existe, le code s'écrit | Claude |
| En revue | La PR est ouverte | Claude, en ouvrant la PR |
| Terminée | La PR est mergée et toutes les tâches sont terminées | Claude, par réconciliation à sa session suivante |

Un projet peut ajouter un statut final propre à sa méthode (« Rétro faite »,
voir Partie B).

GitHub prévient Linear tout seul quand une PR change d'état, **pour les tâches**.
Il ne touche jamais au statut d'une feature : c'est Claude qui le pose — « En
revue » quand il ouvre la PR, « Terminée » quand il constate le merge à sa
session suivante. La barre de progression de la feature, elle, se remplit seule
à mesure que ses tâches se ferment.

D'où le seul décalage du dispositif : entre le merge et la session suivante de
Claude, la feature affiche 100 % mais reste « En revue ».

### Statuts de tâche

À faire → En cours → En revue → Terminée, plus Bloquée (et Annulée).

« En cours », « En revue » et « Terminée » sont posés par GitHub (branche
poussée, PR ouverte, PR mergée), pour toute tâche dont le code apparaît dans
la branche ou la PR. Claude coche aussi les tâches d'une feature au fil de son
travail.

---

## 6. Types de tâches : les labels

Linear n'a pas de champ « type », mais les **groupes de labels** en jouent le
rôle : dans un groupe, une tâche ne porte qu'une valeur. Disponible en gratuit.

Groupe « Type » recommandé :

| Label | Usage |
|---|---|
| `code` | tâche de développement d'une feature |
| `bug` | comportement faux constaté |
| `documentation` | README, docs d'API, guides |
| `contenu` | rédaction, données, éléments non logiciels du produit |
| `refactoring` | amélioration sans changement de comportement |

Un second groupe « Zone » (serveur / interface / infra…) est utile dès que le
dépôt a plusieurs parties distinctes.

Des **modèles de tâche** (templates) pré-étiquetés accélèrent la saisie : par
exemple un modèle « Bug » avec reproduction / attendu / obtenu.

Les features ont leur propre label (« Project label ») : la **Taille**
(S / M / L / XL, voir § 4 bis). Les versions ne sont pas des labels mais des
**initiatives** (§ 3) : c'est ce qui donne à la roadmap son second niveau.

### Les priorités

Linear a quatre niveaux natifs (Urgent, Haute, Moyenne, Basse), sur les tâches
comme sur les features. Règle : Claude pose **Haute** sur la première feature
de l'ordre validé, **Moyenne** sur les autres de la version en cours, **Basse**
sur les versions suivantes. **Urgent est réservé à l'humain** : c'est son geste
pour faire passer une feature devant, sans toucher aux dates. « Prochaine
feature » choisit par priorité, puis par date. Une tâche isolée est Haute si
c'est un bug, Moyenne sinon ; une tâche de feature n'a pas de priorité propre.

---

## 7. Ce qu'on abandonne sur GitHub, ce qu'on garde

Abandonné : les onglets **Issues** et **Projects**. Ils restent vides.

Gardé : le code et son historique, les **pull requests** (relecture et bouton
Merge, atteintes depuis le lien affiché sur la feature ou la tâche Linear), les
tests automatiques branchés sur les PR.

### Faut-il un miroir des tâches en issues GitHub ?

Linear peut créer une issue GitHub synchronisée pour chaque tâche (« GitHub
Issues Sync »). **Recommandation : laisser éteint.** Une seule source pour le
suivi (Linear), une seule pour le code (GitHub). Le miroir n'a d'intérêt que si
des personnes extérieures à Linear doivent signaler ou suivre des problèmes
depuis GitHub. Il s'active plus tard en un clic si le besoin apparaît.

Pour fermer la porte proprement, `init` pose `.github/ISSUE_TEMPLATE/config.yml`
dans le dépôt : les issues vierges sont désactivées et le bouton « New issue »
affiche un lien « Les tâches se suivent dans Linear » vers la team. Personne ne
crée de doublon par habitude.

**Et hors pilotage ?** Un projet non piloté garde ses issues GitHub — au même
moule que les fiches Linear : gabarits « Tâche » (Problème / Action / Terminé
quand) et « Bug » (constaté / attendu / reproduire), dans
`.github/ISSUE_TEMPLATE/`. Un projet sans ces gabarits hérite du filet de
compte : le dépôt spécial `.github` du compte (ou de l'organisation) fournit
les gabarits de PR et d'issues par défaut à tous les dépôts qui n'ont pas les
leurs.

### Le cahier de recette

Linear n'a pas de module de test et ne remplace pas un cahier de recette. La
recette vit là où le projet la tient déjà (fichier versionné, base Notion,
outil dédié) ; la feature Linear pointe vers elle.

### La description de PR : le gabarit

La fiche Linear et la PR n'ont pas le même lecteur. La fiche répond à « quel
problème, quel résultat attendu » — elle est écrite AVANT le travail. La PR
s'adresse au relecteur et répond à « comment ça a été résolu, quelle preuve » —
elle est écrite APRÈS. Ne jamais recopier la fiche dans la PR : l'intégration
Linear l'affiche déjà, dépliée, sous la description.

Une PR = une livraison : sa description raconte la **livraison entière** (ce
que ce merge apporte à la feature), pas chaque tâche — le détail par tâche,
c'est la liste `Closes` et ses cartes Linear.

```markdown
**Feature « <nom> »** — livraison <n>/<total> « <nom de la livraison> »

## Ce qui change
<la livraison en fonctionnel : ce qu'on peut faire après ce merge qu'on ne
 pouvait pas faire avant — 2-4 lignes, lisibles par un non-développeur>

## Comment
<les choix techniques faits, les alternatives écartées, par où commencer
 la relecture>

## Preuve
<du constaté, jamais des cases à cocher : CI verte, sortie réelle collée,
 capture d'écran si interface>

## Hors périmètre / risques
<ce que cette livraison ne couvre pas — souvent : les livraisons suivantes —
 dette assumée, renvois de tâches>

Closes <CODE>-a, <CODE>-b, <CODE>-c
```

Pour une tâche isolée (fix/chore), même gabarit sans la ligne Feature.

Chaque dépôt piloté pose ce gabarit dans `.github/PULL_REQUEST_TEMPLATE.md` :
GitHub pré-remplit alors toute PR ouverte à la main. Côté fiches, l'équivalent
existe déjà : les templates de team Linear (Feature / Tâche / Bug) posés par
`init`.

---

## 8. Ce qui reste humain, par choix

- **Le merge.** Claude ouvre la PR, avec le rapport d'audit d'un agent qui n'a
  pas écrit le code ; un humain décide de l'intégrer. Pas de merge automatique.
  Depuis le 14/09, ce n'est plus seulement une consigne : un verrou technique
  (`.claude/tools/verrou-git/`, posé par `install.sh`) refuse avant exécution
  tout push vers `main` ou `release`, tout push forcé et tout `gh pr merge`.
- **L'ordre de la roadmap.** Le placement initial est automatique (Claude pose
  la feature en fin de roadmap avec une priorité par défaut selon son type) ;
  l'arbitrage entre deux features reste un choix, pas un calcul. L'humain
  glisse la barre s'il n'est pas d'accord.

Dans les deux cas, le mécanisme sait le faire ; on garde volontairement un
endroit où l'humain tranche.

---

## 9. Qui déclenche Claude : trois niveaux

**Niveau 1 — l'humain lance, Claude trouve seul son travail.** Ouvrir Claude
Code, dire « prochaine feature » ou « traite les tâches isolées ». Claude lit
Linear, prend le premier élément, le livre en PR, s'arrête. L'humain merge,
puis relance. Zéro infrastructure. C'est le point de départ recommandé.

**Niveau 2 — un événement déclenche.**
- Depuis GitHub : la GitHub Action officielle d'Anthropic
  (`anthropics/claude-code-action`). `@claude` dans une issue ou une PR lance
  un Claude dans le cloud. Suppose des issues GitHub, donc le miroir du § 7.
- Depuis Linear : assignation d'une tâche à un « agent ». Demande un agent
  intégré à Linear ou un petit service qui reçoit le signal et lance Claude
  Code. Le plus cohérent avec « Linear pilote », mais à développer.

**Niveau 3 — l'horloge déclenche.** Une routine planifiée Claude Code (« chaque
matin, lire Linear, prendre le premier élément, livrer une PR »). L'humain se
réveille avec des PR à relire. Le plus simple des déclencheurs à installer.

Passer au niveau 2 ou 3 seulement quand on constate qu'on ouvre toujours Claude
pour dire la même phrase.

---

## 10. Ce que le dépôt doit déclarer

Pour que Claude sache que le projet est piloté par Linear, le `CLAUDE.md` du
dépôt contient une section :

```
## Pilot

**Posé par `init`**
- Workspace Linear : <slug> (connexion MCP, clé API)
- Team : <nom> — clé <CODE> — id <id>
- Agents en parallèle : 1
- Barème et capacité : .pilot/calibration.md
- Cahier de recette : UAT.md à la racine

**Selon le projet** — une ligne absente vaut « non »
- Lancer l'app : <commande> — sans elle, le testeur n'a pas d'écran à ouvrir
- Amorce de recette : .pilot/amorce-recette.js — sans elle, il voit des écrans vides
- Release : release — une branche stable en plus de main
- Échéance : <AAAA-MM-JJ> — sync annonce alors la marge restante

**Le contrat de ce projet** : aucun développement sans fiche Linear ; rien n'est
créé dans Linear sans liste validée.
```

Cette section ne porte que **les valeurs propres à ce projet**. Les règles de la
méthode — vocabulaire, nommage des branches, format des PR, merge humain — vivent
dans la skill et ne se recopient pas ici : deux textes qui disent la même chose
finissent par se contredire. Le moule à jour est
`.claude/skills/pilot/reference/section-pilot.md`, dans le projet.

Cette section est écrite par `/pilot init`, qui crée aussi la team, ses
statuts, ses labels, ses templates et son archivage automatique (par l'API
Linear, car la connexion MCP ne sait pas créer ces éléments de structure).

Sans cette section, Claude considère que le projet n'est pas piloté par Linear
et retombe sur ce que le dépôt prévoit (fichier de backlog, issues GitHub…).

---

## 11. Mise en place, pas à pas

1. **Créer le workspace Linear**, une équipe, choisir la clé (3 lettres).
   Inviter les membres (illimité en gratuit).
2. **Configurer les statuts** de feature (§ 5) et de tâche, les groupes de
   labels (§ 6), un modèle de tâche « Bug ».
3. **Brancher GitHub** : Settings → Integrations → GitHub → autoriser le dépôt.
   Régler « PR ouverte → En revue » et « PR mergée → Terminée ». Laisser
   « Issues Sync » éteint.
4. **Brancher Claude** : `claude mcp add linear --transport http
   https://mcp.linear.app/mcp`, puis authentification par le compte Linear.
   Claude peut alors lire et écrire features, tâches, statuts, commentaires.
5. **Verser le backlog existant** dans Linear (features pour ce qui est
   cadré, tâches isolées pour le reste).
6. **Déclarer le pilotage** dans le `CLAUDE.md` du dépôt (§ 10).
7. **Lancer la première feature** au niveau 1. Évaluer après quelques
   semaines s'il faut un déclencheur (§ 9).

---

## 12. Limites du plan gratuit de Linear

- Membres illimités.
- 250 tâches **non archivées** au maximum, terminées comprises. Blocage dur
  au-delà. Parade : l'archivage automatique des tâches terminées, réglé à un
  mois par `init`.
- 2 teams (= 2 projets pilotés) par workspace. Un workspace par contexte
  (perso, client) est une façon légitime de s'étendre. Supprimer une team
  libère sa place (délai de grâce de 30 jours) ; pour l'archivage, à vérifier.
- 10 Mo par pièce jointe.
- Initiatives, cycles, templates, intégration GitHub, API et agents : inclus.
- Pas de permissions fines.

Largement suffisant pour un projet personnel ou une petite équipe.

---

## 13. Checklist de cohérence

- [ ] Une livraison = une PR, qui cite toutes ses tâches ; une feature = une barre de roadmap de plusieurs livraisons.
- [ ] Le code d'une tâche Linear est dans le nom de la branche et le titre de
      la PR, pour les features comme pour les tâches isolées.
- [ ] Toutes les features du projet sont sur la roadmap dès le cadrage ; seule
      la feature en cours est découpée en tâches.
- [ ] Rien n'est créé dans Linear sans liste validée par un humain.
- [ ] Chaque fiche respecte le moule (titre-résultat, trois temps, cases).
- [ ] Aucune tâche n'est créée dans GitHub Issues.
- [ ] Les statuts de feature reflètent l'état réel du développement.
- [ ] Le cahier de recette vit hors de Linear, et la feature pointe vers lui.
- [ ] Le merge est une décision humaine, ou une autorisation explicite et
      conditionnée.
- [ ] La roadmap est relue par un humain au moins une fois par semaine.
- [ ] Le `CLAUDE.md` du dépôt déclare le pilotage Linear.

---

# Partie B — Ce que Claude fait entre vos validations

La Partie A dit *quoi* suivre et *où* (Linear, GitHub). Cette partie dit ce que
Claude fait entre deux moments où vous dites oui. Rien ici ne modifie la
Partie A : c'est le moteur qui remplit ses cases.

## B.1 Le circuit d'une feature

Vous intervenez à quatre moments, toujours pour valider ou trancher. Entre
deux, Claude travaille seul.

| # | Étape | Qui | Ce qui se passe | Statut Linear |
|---|---|---|---|---|
| 1 | **Cadrer** | Vous + Claude | Un entretien par rounds : les questions posables d'un coup, numérotées, chacune avec une réponse recommandée que vous acceptez ou corrigez. Il en sort les décisions produit et la liste « ce qui devra être vrai » à la fin (10 à 30 phrases, dont des refus), gravées dans la fiche feature ; les mots du produit se fixent dans `CONTEXT.md` au passage. Un agent relit le cadrage et dit ce qui manque. **Vous validez.** | À cadrer |
| 2 | **Découper** | Claude, puis vous | N livraisons qui ne touchent pas les mêmes fichiers ; chaque phrase de l'étape 1 affectée à une livraison ; une fiche Tâche par tâche, avec un « Terminé quand » dont au moins un refus. **Vous validez la liste** avant toute création dans Linear. | Planifiée |
| 3 | **Produire** | Agents, sans vous | Une copie isolée du dépôt par livraison, et dedans un agent (un par tâche, l'un après l'autre, sur une grosse livraison) — une livraison à la fois par défaut, plusieurs quand le projet a prouvé sa boucle. Puis **deux agents qui n'ont pas écrit le code** : l'un relit le diff et relance les tests, l'autre regarde les écrans livrés. Un correcteur si l'un des deux trouve quelque chose. Une PR par livraison, avec le rapport d'audit. Détail : `BOUCLE-AGENTS.md`. | En développement → En revue |
| 4 | **Merger** | Vous | Lire le rapport d'audit, merger. Trancher les décisions que les agents ont remontées sans les prendre. | Terminée |
| 5 | **Apprendre** | Claude | Chaque défaut trouvé à l'audit devient une règle dans le `CLAUDE.md` du dépôt ; les décisions tranchées sont gravées dans Linear, et celles qui sont dures à inverser, surprenantes sans contexte et issues d'un vrai arbitrage deviennent une ADR d'un paragraphe dans `docs/adr/`. | Rétro faite |

Au niveau du projet, deux moments de plus, une seule fois : le cadrage du
projet (PRD) et la roadmap (§ 4 bis). Même règle : Claude propose, vous validez.

## B.2 Vos commandes

Une commande par moment de validation. Vous n'en tapez jamais une pour « faire
avancer » ce qui peut avancer seul.

| Moment | Commande | Claude s'arrête quand |
|---|---|---|
| Début du projet | `/pilot init` | Le PRD est à valider |
| Après le PRD | `/pilot roadmap` | La liste des features est à valider |
| Début d'une feature | `/pilot feature <nom>` | Le cadrage, puis le découpage, sont à valider |
| Après le découpage | `/pilot run <feature>` | Les PR sont ouvertes, auditées, sans bloquant |
| Après les merges | `/pilot sync` | Linear et le `CLAUDE.md` sont à jour |
| Tâche isolée | `/pilot fix` | La PR est ouverte |
| N'importe quand | `/pilot next` | Voir B.3 |
| Une fois, à l'installation | `/pilot benchmark` | Le barème de charge est proposé |

Trois outils de plus, installés avec la méthode, pour les situations qui ne
sont pas une étape du circuit :

| Situation | Outil | Claude s'arrête quand |
|---|---|---|
| Un bug qui ne se reproduit pas du premier coup | `diagnosing-bugs`, se déclenche sur « diagnostique », « ça plante » | La cause est nommée, avec la commande qui la montre |
| Un merge ou un rebase bloqué sur un conflit | `resolving-merge-conflicts`, sur « le merge bloque » | Le merge est terminé, les deux intentions gardées |
| Une décision que seul le client peut prendre | `/to-questionnaire` | Le questionnaire à lui envoyer est écrit |

## B.3 `next` : l'étape logique, déduite de Linear

`/pilot next` lit le statut de la feature en cours et propose l'étape qui
suit. Aucun fichier d'état à entretenir : Linear le tient.

| Statut trouvé | Ce que `next` propose |
|---|---|
| Aucune feature | Cadrer le projet ou poser la roadmap |
| À cadrer | Le cadrage |
| Planifiée | Lancer la production (`run`) |
| En développement / En revue | Rien à lancer : la liste des PR à lire et à merger |
| Terminée | Apprendre, puis la feature suivante ; si elle appartient à un cap, les features du cap encore ouvertes |

Chaque commande finit en proposant la suivante (« Découpage ? », « Je lance ? »,
« Feature suivante : X, cadrage ? »). Dans l'usage courant, `next` est la seule
commande à connaître ; les autres servent à forcer une étape.

## B.4 Ce qui n'est pas automatique, par choix

- **Le merge**, à chaque livraison (§ 8). Le curseur pourra passer à « un merge
  par feature » le jour où deux garde-fous existent : un plafond de dépense par
  agent, et une vérification qui ouvre l'application et la fait fonctionner
  de bout en bout. Pas avant.
- **Les décisions de fond.** Un agent qui rencontre un choix produit ou
  d'architecture non couvert par sa fiche prend l'option la plus réversible et
  le signale ; il ne tranche pas.
- **L'enchaînement de plusieurs features sans vous.** Non prévu.

## B.5 Origine

Ce circuit absorbe l'ancien workflow FORGE : ses étapes de tête (cadrage,
découpage, pauses) sont B.1 étapes 1-2 ; ses étapes de production, vérification
et livraison sont remplacées par `BOUCLE-AGENTS.md` ; sa rétro est l'étape 5.
Le nom FORGE, ses fichiers de phase et son mode autonome disparaissent.

Le 14 septembre 2026, la méthode a été relue à la lumière du dépôt
`mattpocock/skills` (analyse dans `sources/`). Ce qu'elle en a pris : une façon
d'écrire les fiches (`GRILLE-DE-RELECTURE.md` : un critère de fin par étape, la
référence déportée, le test du no-op), trois skills importées telles quelles
(diagnostic, conflits, questionnaire), l'entretien par rounds, les douze odeurs
de code et les trois mauvais tests, le glossaire `CONTEXT.md` et les ADR, et le
verrou git. Ce qu'elle n'en a pas pris : la chaîne manuelle où l'humain tape
chaque étape, le suivi hors Linear, et le merge automatique.
