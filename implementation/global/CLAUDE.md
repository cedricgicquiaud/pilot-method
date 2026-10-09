# Preferences

- Langue : francais. Termes techniques et identifiants de code en anglais.
- Reponses concises, pas de resume en fin de reponse, pas d'emojis.
- Explications claires et comprehensibles, meme sur des sujets techniques :
  commencer par la conclusion en une phrase simple ; une idee par phrase ;
  expliquer chaque terme technique a sa premiere apparition (ou le remplacer
  par un mot courant) ; illustrer par un exemple concret des que le concept
  est abstrait ; jamais deux niveaux de subordonnees dans la meme phrase.
  Un avis doit etre reformulable par un non-developpeur apres une lecture.
- Restitution : appliquer la skill `rendu-fonctionnel` (~/.claude/skills/rendu-fonctionnel/SKILL.md)
  a chaque compte-rendu de travail — fonctionnel d'abord (« Ce qui change »),
  technique ensuite (« Details techniques »).
- Toujours lire un fichier avant de le modifier.
- Commits atomiques, messages conventionnels en anglais (feat:, fix:, refactor:).
- Aucune signature "Generated with Claude Code" / "Co-Authored-By: Claude" dans les commits ni PR.
- Ne jamais push sur main/master, meme avec ordre explicite. Sur branche feature, push et
  ouverture de PR autorises. Claude ne merge jamais une PR : le merge est humain
  (decision du 2026-08-27, qui annule l'exception `gh pr merge` du 2026-07-31).

# Pilotage de projet (Linear + GitHub)

- Un projet est **pilote par Linear** si son `CLAUDE.md` contient une section `## Pilot`.
  Dans ce cas, appliquer la skill `pilot` (`.claude/skills/pilot/SKILL.md`, dans le projet) :
  aucun developpement sans fiche Linear, rien de cree dans Linear sans liste validee, code
  Linear dans la branche et le titre de PR.
- **La methode vit dans le projet, pas ici.** Chaque projet pilote porte sa copie dans son
  `.claude/` : les six fiches d'agent, la skill `pilot`, les outils. Elle est versionnee avec
  lui, donc identique pour tous ceux qui clonent. La version de reference est dans le depot
  `~/Desktop/PILOT`, dossier `implementation/`.
- **On ne modifie jamais la copie d'un projet.** Une amelioration se fait dans `~/Desktop/PILOT`,
  sur une branche, avec une PR. Le projet la recoit en relancant `./install.sh <projet>`.
- Sans section `## Pilot` : projet non pilote, ne rien faire dans Linear ; le backlog
  reste dans le fichier prevu par le projet (`BACKLOG.md` ou autre).
- **Proposer le pilotage sur un projet neuf.** Deux moments, et deux seulement :
  quand l'utilisateur demande de creer un projet ou un depot (`git init`, « on demarre une
  app qui… ») ; quand il annonce, dans un depot sans section `## Pilot`, un travail qui va
  durer — une roadmap, plusieurs features, plusieurs ecrans.
  Poser la question **une fois, en une phrase** : « Je le pilote avec `pilot` — Linear pour le
  suivi, la boucle d'agents pour produire ? »
  Rien sur un dossier d'essai, un script isole, un depot ouvert pour une correction ponctuelle.
  Le signal est ce que l'utilisateur annonce, jamais l'etat du depot : « depot vide » ou « peu
  de commits » declencherait sur les bancs d'essai.
- **Oui** : `cd ~/Desktop/PILOT && ./install.sh <projet>`, puis `/pilot init` dans le projet.
- **Non** : ecrire la trace dans le `CLAUDE.md` du projet, sans quoi la question revient a
  chaque session. Sous un titre `## Suivi`, jamais `## Pilot` — ce titre-la est le marqueur
  d'un projet pilote, il declarerait l'inverse de ce qu'on ecrit :
  `Projet non pilote par Linear (decision du <AAAA-MM-JJ>). Backlog dans <fichier>.`
  Elle dit aussi ou vit le backlog a qui ouvre le depot.

# Circuit d'une feature (projets pilotes)

Le circuit complet — cadrer, decouper, produire, merger, apprendre — est decrit dans la
Partie B de `~/Desktop/PILOT/PILOTAGE-LINEAR-GITHUB-CLAUDE.md` ; la production en
parallele (worktrees, MISSION.md, tdd-writer, verifier) dans `BOUCLE-AGENTS.md` du meme dossier.
L'ancien workflow FORGE est absorbe par ce circuit ; ne pas le reintroduire.

- Claude s'arrete a chaque validation : PRD, roadmap, cadrage (avec contrat de validation),
  decoupage en livraisons disjointes. Entre deux, il travaille seul.
- Le merge est humain, a chaque livraison. Pas de merge automatique.
- Trois invariants de la boucle : merge humain ; decisions de fond remontees, jamais tranchees
  en chemin ; pas de code sans test prealable (producteur `tdd-writer`, preuve dans les commits).
- Une tache isolee (`/pilot fix`, un fichier, changement evident) ne passe pas par la boucle :
  branche, test, PR.
- Projets non pilotes : pas de circuit impose ; appliquer les preferences ci-dessus et le
  CLAUDE.md du projet.

# Gestion du contexte

- /compact apres chaque etape terminee ou quand le contexte est lourd
- /context si doute sur ce que Claude voit
- /cost pour suivre la consommation

# Gestion des sessions

- Fin de session > produire un resume (travail fait, decisions, prochaines etapes) et l'ecrire dans `.workflow/sessions/YYYY-MM-DD-description.md`
- Debut de session > lire le dernier fichier de `.workflow/sessions/` pour reprendre le contexte
- Sur projet pilote, `/pilot next` indique ou reprendre
