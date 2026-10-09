# Le merge automatique par un agent

**Refusé, décision du 27/08/2026, confirmée le 14/09.** Le merge est humain à chaque
livraison : c'est le moment où les décisions remontées par les agents se tranchent, et où un
relecteur qui n'a pas écrit le code décide. Les skills `implement-spec` de Matt Pocock et les
boucles « jalons sans humain » vues ailleurs merged par un sous-agent : non repris. Depuis le
14/09 un verrou technique refuse `gh pr merge` et tout push vers `main`.

**Ce qui ferait rouvrir** (B.4 de `PILOTAGE-…md`) : un plafond de dépense par agent, et une
vérification qui ouvre l'application et la fait fonctionner de bout en bout. Même alors, le
curseur irait à « un merge par feature », pas à zéro merge humain.
