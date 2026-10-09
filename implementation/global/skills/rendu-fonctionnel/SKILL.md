---
name: rendu-fonctionnel
description: >-
  Format de restitution en deux niveaux (fonctionnel d'abord, technique ensuite)
  pour toute réponse qui rend compte d'un travail effectué. Utiliser cette skill
  à CHAQUE fois que tu termines une tâche et rédiges le compte-rendu final —
  feature ajoutée, bug corrigé, refactoring, configuration, diagnostic, revue de
  code — même si l'utilisateur ne demande pas explicitement un résumé « simple »
  ou « non technique ». Elle s'applique aussi quand l'utilisateur demande
  d'expliquer un changement, de résumer ce qui a été fait, ou de reformuler une
  réponse trop technique.
---

# Rendu fonctionnel

## Pourquoi

Les comptes-rendus de Claude sont lus par un public mixte : des développeurs et
des non-développeurs. Un rendu qui commence par des fichiers, des endpoints ou
du jargon perd la moitié des lecteurs dès la première ligne. Un rendu qui ne
parle jamais technique frustre l'autre moitié.

La solution : deux niveaux, toujours dans le même ordre. D'abord ce que le
changement apporte à l'utilisateur du produit. Ensuite, pour ceux qui veulent
vérifier ou creuser, le détail technique.

Le test de réussite : un non-développeur doit pouvoir reformuler le premier
niveau après une seule lecture. Un développeur doit trouver dans le second
niveau de quoi relire le changement sans poser de question.

## Structure

```markdown
## Ce qui change

[2 à 5 phrases en langage courant. Ce que l'utilisateur du produit peut
faire maintenant, ce qui est corrigé, ce qui est plus rapide. Si utile,
rappeler la situation d'avant en une phrase.]

## Détails techniques

- [Liste courte : fichiers touchés, choix d'implémentation, endpoints,
  dépendances ajoutées, résultat des tests.]
```

## Règles d'écriture du niveau 1 (« Ce qui change »)

- Parler de la **fonctionnalité**, jamais de l'implémentation. « Les visiteurs
  peuvent réinitialiser leur mot de passe », pas « j'ai ajouté un endpoint
  POST /auth/reset ».
- Rester bref et aéré : **une puce par changement**, une phrase par puce, 2 à
  5 puces. Un paragraphe compact se lit mal, même bien écrit ; la liste permet
  de compter ce qui change d'un coup d'œil.
- Une analogie au plus. Une image bien choisie éclaire ; en enchaîner
  plusieurs transforme le compte-rendu en récit et noie le message.
- Zéro jargon : pas de nom de fichier, de fonction, de librairie, de terme
  d'architecture. Si un concept technique est vraiment inévitable, le traduire
  par un mot courant ou une comparaison simple.
- Une idée par phrase. Commencer par le résultat, pas par le processus.
- Dire honnêtement l'état réel : « fonctionne et testé », « fonctionne mais
  non testé », « bloqué parce que… ». Le niveau 1 ne doit jamais enjoliver.
- Si rien ne change pour l'utilisateur du produit (refactoring interne,
  outillage), le dire tel quel : « Rien ne change à l'usage ; le code est
  réorganisé pour que les prochaines évolutions soient plus rapides et moins
  risquées. »

## Règles d'écriture du niveau 2 (« Détails techniques »)

- Liste à puces, courte : uniquement ce qui aide un développeur à relire ou
  reprendre le travail (fichiers modifiés, décisions d'implémentation et leur
  raison, commandes de vérification lancées et leur résultat réel).
- 4 à 8 puces d'une ou deux lignes chacune. Si un point mérite un long
  développement, le résumer en une puce et proposer d'approfondir sur demande
  — pas de sous-sections, de tableaux d'estimations ni d'extraits de code
  multiples dans un compte-rendu.
- Les termes techniques restent en anglais et sans vulgarisation : ce niveau
  est pour le lecteur technique.
- Ne pas répéter le niveau 1.

## Longueur totale

Le rapport entier doit tenir sur un écran, soit environ 30 lignes. Un
compte-rendu n'est pas un audit : il donne les 2 ou 3 points qui comptent et
propose d'approfondir si le lecteur le demande. L'exhaustivité qui noie le
lecteur fait perdre les deux publics à la fois : le non-développeur décroche,
le développeur ne trouve plus l'essentiel. Ce qui a été fait mais n'éclaire
pas la décision du lecteur (liste complète des cas de test, estimations
chiffrées spéculatives, points annexes hors périmètre) reste dans les
fichiers de travail, pas dans le rapport.

## Adapter selon le type de réponse

Le format complet à deux sections vaut pour les comptes-rendus de travail.
Pour les autres cas, garder l'esprit (fonctionnel d'abord) sans forcer la
structure :

- **Question simple** : répondre en prose, conclusion en première phrase,
  langage courant ; glisser la précision technique en fin de réponse si utile.
  Pas de titres de section.
- **Diagnostic / analyse** : titrer le niveau 1 « Ce qui se passe » plutôt
  que « Ce qui change » (rien n'a encore changé). Se limiter aux 2 ou 3
  causes principales, expliquées en langage courant ; niveau 2 = les preuves
  techniques essentielles. Les causes secondaires tiennent en une ligne
  chacune — le lecteur demandera le détail s'il en a besoin.
- **Échec ou blocage** : niveau 1 = ce qui ne marche pas et ce que ça empêche,
  sans dramatiser ni minimiser ; niveau 2 = l'erreur exacte et les pistes.
- **Discussion purement technique demandée par un développeur** (revue de code
  ligne à ligne, choix d'architecture) : le niveau 1 se réduit à une phrase de
  conclusion en langage courant, puis la technique prend toute la place.

## Exemples

**Exemple 1 — feature :**

Mauvais (technique d'abord) :
> J'ai créé le composant `ResetForm.tsx`, ajouté l'endpoint POST /auth/reset
> dans `auth.ts` et branché Resend pour l'email. Le token JWT expire en 15 min.

Bon :
> ## Ce qui change
> Les visiteurs peuvent maintenant réinitialiser leur mot de passe depuis la
> page de connexion. Avant, il fallait contacter le support. Le lien reçu par
> email est à usage unique et expire au bout de 15 minutes, comme un code de
> retrait de colis. Testé de bout en bout, tout fonctionne.
>
> ## Détails techniques
> - Nouveau endpoint POST /auth/reset (`auth.ts`), token JWT 15 min
> - Formulaire `reset-form.tsx`, email via le service existant (Resend)
> - Tests : `npm test` vert (34 tests, dont 4 nouveaux)

**Exemple 2 — bug fix :**

Mauvais :
> Fix du race condition dans le hook `useCart` : le state était stale car le
> useEffect ne listait pas `items` dans ses deps.

Bon :
> ## Ce qui change
> Le panier n'affiche plus un total faux quand on ajoute deux articles très
> vite à la suite. C'était un bug d'affichage : le paiement, lui, était déjà
> calculé sur le bon montant.
>
> ## Détails techniques
> - Race condition dans `useCart` : `items` manquant dans les deps du
>   `useEffect`, d'où un state stale
> - Fichier : `hooks/useCart.ts` ; test de non-régression ajouté
