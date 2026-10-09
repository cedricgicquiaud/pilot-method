# Porter la boucle sur des modèles locaux ou hors Claude Code

**Refusé le 13/09/2026.** Analyse faite, rien construit : le portage sur Pi est faisable en
une semaine, mais le Mac actuel (16 Go) ne tient qu'un testeur en local, le palier utile est
128 Go de mémoire unifiée, et les rôles de relecture restent sur le meilleur modèle cloud
quoi qu'il arrive. Décision : rester sur le cloud.

**Ce qui ferait rouvrir** : un client qui exige que le code ne sorte pas (serveur GPU dédié,
facturé au client) ; la facture qui devient le frein (d'abord un modèle ouvert par API pour le
testeur) ; plusieurs runs par jour. Dans les trois cas, l'épreuve TST-B1 décide du modèle.
Détail : `.workflow/sessions/2026-09-13-cout-par-livraison-et-lead.md`.
