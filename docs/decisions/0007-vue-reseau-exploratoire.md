# ADR-0007 — Vue Réseau du Catalogue : modèle de transformation explicite et découpage en lots

- **Statut** : Accepté
- **Date** : 2026-06-11
- **Contexte** : La vue **Réseau** du Catalogue
  (`lib/presentation/widgets/vue_reseau_catalogue.dart`) affiche les fiches en
  constellation (spirale de Fermat) avec les arêtes d'association. Aujourd'hui
  elle est **statique** : positions calculées une fois puis simplement mises à
  l'échelle de la largeur, nœuds en initiale, sélection → voisins + panneau.
  `docs/15` §8 **E** la fait évoluer en **vue exploratoire scalable** (points
  7–11) : zoom/déplacement, sélection enrichie (noms complets, recadrage,
  anti-chevauchement), variétés dépliables, réduction au scroll, sections
  compagnons avec raisons.

  C'est un **gros chantier** avec deux forces structurantes :
  1. Plusieurs exigences de #8 sont **en tension avec un zoom naïf** : les
     libellés doivent garder une **taille écran constante** (le zoom écarte les
     nœuds, ne grossit pas le texte), il faut un **recadrage programmatique**
     (zoom-to-fit d'un sous-ensemble) et, à terme, **déplacer des nœuds**
     (anti-chevauchement). `InteractiveViewer` zoome **tout son sous-arbre**
     (texte compris) et ne donne pas la main sur les positions des nœuds.
  2. L'ampleur impose un **découpage** en sous-lots livrables, sans régression,
     pour un widget aujourd'hui **sans aucun test**.

---

## Décision 1 — Un **modèle de transformation explicite**, pas `InteractiveViewer`

On introduit une transformation maison `{ echelle, offset }` projetant les
positions **virtuelles** (coordonnées de la spirale, inchangées) vers l'écran :

```
positionEcran = positionVirtuelle * echelle + offset
```

- Les **nœuds** sont posés (`Positioned`) en coordonnées écran avec un **rayon
  constant en pixels** → les libellés gardent une **taille constante** quel que
  soit le zoom (#8). Le rendu des nœuds existant (`_Noeud`, `_EtatNoeud`,
  `couleurCategorie`) est réutilisé tel quel.
- Les **arêtes** (`_PeintreAretes`, déjà paramétré par l'échelle) reçoivent la
  transformation complète et suivent.
- Le **geste** (#7) est un unique `GestureDetector(onScaleUpdate)` : **pan** via
  `focalPointDelta` (un doigt / souris) **et** zoom via `scale` (deux doigts)
  autour du `focalPoint` ; `echelle` est clampée. Des **boutons +/−/recentrer**
  doublent le geste (desktop sans pinch).
- Le **recadrage** (#8) et le « recentrer » sont **programmatiques** : on calcule
  l'`echelle`/`offset` qui tient une bbox virtuelle (le sous-ensemble
  sélection+liés, ou la constellation entière) dans le viewport, et on **anime**
  la transition (`AnimationController` + interpolation de la transformation).

**Rejeté — `InteractiveViewer`** : zoomerait le texte, et l'anti-chevauchement
(#8b, déplacer des nœuds) ainsi que le recadrage fin sortent de son périmètre.
Le modèle explicite est le seul à satisfaire *à la fois* police constante,
recadrage programmatique et future relocalisation de nœuds.

## Décision 2 — Découpage en **lots livrables**, filet de tests d'abord

Le chantier est découpé ; **chaque lot laisse l'app verte** (`flutter analyze` +
suite complète) et est livrable seul. La couche de transformation est **additive**
au-dessus du modèle existant (nœuds, arêtes, sélection, panneau conservés).

| Lot | Points | Contenu |
|---|---|---|
| **0** ✅ | — | Filet de **tests de caractérisation** de l'existant (préalable, le widget n'en avait aucun) |
| **Phase 1** ✅ | **#7 + #8a** | Zoom + déplacement x/y + contrôles ; sélection → noms complets (taille constante) + recadrage animé zoom-to-fit |
| **#8b** ✅ | **#8b** | Anti-chevauchement actif : décalage par nœud (virtuel, additif) par séparation AABB itérative des empreintes disque+libellé, animé avec le recadrage |
| **#9 + #10** ✅ | **#9 + #10** | Page scrollable (`CustomScrollView`) : variétés de l'espèce sélectionnée en `SliverList` (#9) ; constellation dans un `SliverPersistentHeader` réductible au scroll, nodes en initiale une fois réduit (#10) |
| Bloqué | **#11** | Sections « bon(s) compagnon(s) / à éviter » avec **raisons** — dépend du contenu éditorial famille (ADR-0006 **Lot 4**, aujourd'hui vide) et d'un référentiel maladies/ravageurs normalisé |

---

## Conséquences

- **Positif** : exigences de #8 satisfaites proprement (police constante,
  recadrage, futur anti-chevauchement) ; rayon d'impact confiné à un widget
  autonome consommé à un seul endroit (`ecran_catalogue.dart`, inchangé pour la
  Phase 1) ; progression sûre et vérifiable lot par lot ; le widget gagne enfin
  une couverture de tests.
- **Négatif / coût** : on réimplémente pan/pinch et le recadrage animé à la main
  (plus de code qu'un `InteractiveViewer`) ; l'anti-chevauchement (#8b) reste un
  problème de réglage, isolé exprès en lot de suivi.
- **Dépendances** : #11 reste bloqué tant qu'ADR-0006 Lot 4 (notes éditoriales
  famille) et un référentiel maladies/ravageurs n'existent pas.
