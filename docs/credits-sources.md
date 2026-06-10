# Crédits & sources de données — Pot'à Gérer

Les fiches plantes embarquées (`assets/fiches_plantes/`) sont rédigées à partir
de **données factuelles** (taxonomie, besoins agronomiques, périodes de culture)
issues de bases de connaissances ouvertes, puis vérifiées et reformulées. Seuls
des **faits** sont repris (non soumis au droit d'auteur) ; aucun texte n'est
copié verbatim. Chaque fiche cite ses sources dans son champ `sources:`.

Cette page alimente l'écran **« À propos »** de l'application.

## Bases de données consultées

| Source | Usage | URL | Licence / statut |
|---|---|---|---|
| **GBIF** (Global Biodiversity Information Facility) | Taxonomie de référence : nom scientifique, famille, genre | https://www.gbif.org | Données ouvertes (CC-BY / CC0 selon jeux) |
| **Wikidata** | Contre-vérification taxonomique (famille par nom scientifique) | https://www.wikidata.org | CC0 |
| **Wikipédia** (fr / en) | Descriptions d'espèces | https://fr.wikipedia.org · https://en.wikipedia.org | CC BY-SA — faits repris, texte reformulé |

> Bases envisagées mais non retenues : **OpenFarm** (projet arrêté, API hors
> service). Sources extensibles : voir `tool/scrap_fiche.dart` (ajouter une
> implémentation de `SourceBotanique`).

## Outil de collecte

Les fiches **mères** (espèces) sont amorcées par `tool/scrap_fiche.dart`, qui
croise les sources ci-dessus pour remplir taxonomie et descriptions, puis signale
les divergences (ex. familles botaniques discordantes). Les champs agronomiques,
sans source ouverte fiable, sont complétés à la main (généralisation des fiches
variétés + références horticoles) et tracés ici.

## Remarques

- Le poireau illustre une divergence taxonomique connue : **Amaryllidaceae**
  (classification APG actuelle, retenue) vs **Alliaceae** (ancienne).
