# ADR-0023 — Sélecteur de position : globe rotatif et recherche de localité

- **Statut** : **Accepté**
- **Date** : 2026-10-22

## Contexte

Le sélecteur de position était une carte plane zoomable avec six raccourcis de
régions. Placer un potager précisément demandait de zoomer longtemps sur une
image floue (~20 km/px), et la position enregistrée portait des coordonnées
en guise de nom (`48.2° N, 2.4° E`).

## Décision

- **Globe orthographique rotatif** à la place de la carte plane : glisser
  pour tourner (inertie à friction exponentielle), pincer ou molette pour
  zoomer (×1 à ×30), toucher pour poser le pin.
- **Rendu GPU** par un fragment shader Flutter (`shaders/globe.frag`,
  déclaré dans `pubspec.yaml`) ; aucune dépendance ajoutée. Repli : disque
  uni si le shader ou la texture ne se chargent pas. Mesuré à la fréquence
  maximale de l'écran (90 fps) sur un téléphone Android.
- **Texture** : NASA Blue Marble Next Generation, juillet 2004, domaine
  public, 4096 × 2048 px (~10 km/px, ~0,9 Mo). Au-delà de 4096 px, certains
  téléphones refusent la texture et la mémoire GPU devient lourde (128 Mo en
  8192 px). Provenance : `assets/images/globe_terre.SOURCE.txt`.
- **Recherche de localité** (Nominatim `/search`, ADR-0016) à la place des
  raccourcis de régions : une requête par validation du champ, jamais à la
  frappe (politique OSM) ; localités seulement (`featureType=settlement`),
  5 résultats au plus. Un résultat : le globe tourne vers lui et le pin s'y
  pose. Plusieurs : liste de suggestions avec région et pays.
- **Nom du point touché** (Nominatim `/reverse`) : une requête par point,
  après 500 ms sans nouveau toucher ; coordonnées arrondies à ~1 km avant
  envoi.
- **Pied de l'écran** : nom de la localité, région, pays et coordonnées, à
  gauche de « Valider ».
- **Enregistrement** : `Localisation.ville` reçoit le nom de la localité ;
  à défaut (hors connexion, lieu sans nom), les coordonnées comme avant.

## Conséquences

- Le texte saisi dans la recherche est envoyé à Nominatim, à l'initiative de
  l'utilisateur ; la politique de confidentialité le mentionne.
- Hors connexion, la recherche affiche un message et le globe reste
  utilisable ; le point est alors enregistré sous ses coordonnées.
- Le shader ne se teste pas en widget test : la géométrie (projection
  orthographique, caméra, inertie, visée) est extraite en classes pures et
  testée unitairement.
- Netteté limitée à ~10 km/px au zoom fort ; la recherche par nom compense.
  Un découpage en tuiles embarquées reste possible si cela ne suffit pas.
