# Un second audit du verifier après le correcteur

**Refusé le 15/09/2026, après mesure.** Sur la livraison 3.0 du projet CRM, la session a
relancé le verifier sur le diff du correcteur, poussée par sa boucle d'objectif (« goal not
yet met ») et non par la méthode. L'idée : les corrections ne sont relues par personne avant
le relecteur humain. Le run a coûté 1 h 30 d'horloge pour 40 min de production ; la moitié
en contrôle, incidents et repasses.

Ce qui tient lieu de second audit, et suffit : le correcteur a une liste fermée et ne touche
à rien d'autre ; chaque correction de code porte son test, commité avant elle ; la CI de la
branche rejoue toutes les suites ; le relecteur humain relit le diff de la PR, corrections
comprises. La règle est dans `implementation/skills/pilot/reference/produire.md`, point 4.

**Ce qui ferait rouvrir** : un défaut introduit par une correction qui passe la CI et le
relecteur humain, et se retrouve en production. Un cas suffit, s'il est daté et nommé.
