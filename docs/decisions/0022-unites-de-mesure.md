# ADR-0022 — Unités de mesure par grandeur

- **Statut** : **Accepté**
- **Date** : 2026-10-21

## Contexte

Le réglage « Métrique / Impérial » (Paramètres › Général) était stocké sans
effet. La V1 doit l'appliquer partout où une mesure est affichée ou saisie.

## Décision

- **Stockage inchangé, en métrique.** La conversion a lieu à l'affichage et à
  la saisie uniquement ; aucune donnée existante n'est réécrite.
- **Cinq grandeurs**, chacune réglée sur `SystemeUnites` (`metrique` |
  `imperial`) : température, longueur, surface, volume, masse. Le réglage
  global devient un **préréglage** qui fixe les cinq d'un coup ; un mélange
  s'affiche « Personnalisé ».
- **Rattachements** : précipitations (mm ↔ in) et vent (km/h ↔ mph) suivent
  la longueur ; l'arrosage détaillé (L/m²) s'affiche en impérial en **pouces
  d'eau** (1 L/m² = 1 mm), donc suit la longueur.
- **Impérial = mesures usuelles américaines** : °F, in/ft, ft², gal US
  (3,785 L) et fl oz US, lb/oz.
- **Formats impériaux** : longueur en pouces sous 1 ft, sinon pieds + pouces ;
  masse en oz sous 1 lb, sinon lb ; volume en fl oz sous 1 gal, sinon gal.
- **Domaine** : conversions pures dans un service du domaine
  (`ConvertisseurUnites`) ; préférences dans un objet valeur
  (`PreferencesUnites`). Mise en forme en présentation (ARB).
- **Base** : schéma v10, une colonne par grandeur sur `preferences`,
  initialisée depuis `systeme_unites`, qui n'est plus lue.

## Conséquences

- Saisie impériale : la valeur convertie est stockée en métrique ; un aller-
  retour peut arrondir (ex. 12 in → 30,48 cm).
- Les textes éditoriaux (glossaire, fiches) gardent leurs chiffres métriques.
