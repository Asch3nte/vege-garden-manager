# 04 — Écran Catalogue

> Maquette : `Catalogue.html` + `catalogue.jsx` (export `CatalogueApp`)
> + **données** `catalogue-data.jsx`. Bibliothèque de plantes :
> vue **Fiches** (recherche + filtres) · vue **Réseau** (associations) · **fiche détaillée** en overlay.

## Modèle de données (`catalogue-data.jsx` → `plante.dart`)
**18 plantes**, chacune :
```dart
class Plante {
  final String id, name, icon, cat;        // cat = clé de CATS
  final List<String> varietes;
  final String sol, expo, eau;
  final int diff;                          // 1 Facile · 2 Moyen · 3 Exigeant
  final String haut, espace;
  final List<int> semis, recolte;          // [moisDébut, moisFin] (0-11)
  final List<String> good, bad;            // ids de plantes compagnes / à éviter
  final String desc;
}
```
**Catégories (`CATS`, ordre `CAT_ORDER`)** :
| clé | label | couleur |
|-----|-------|---------|
| fl | Fruits-légumes | warm |
| aro | Aromates | greenMid |
| rac | Racines | terre |
| gri | Légumineuses | greenDeep |
| feu | Salades | primary |
| pf | Petits fruits | bordeaux |

`DIFF = ["", "Facile", "Moyen", "Exigeant"]`.
Plantes (à reprendre **intégralement**, c'est la donnée seed) : tomate, aubergine, poivron,
courgette, concombre, basilic, thym, persil, menthe, carotte, radis, betterave, poireau,
haricot, pois, laitue, mâche, fraise.

**Helpers à porter :**
- `plantById(id)` — accès direct.
- `plantMatches(p, q)` — recherche plein texte sur nom, sol, expo, eau, difficulté,
  catégorie, variétés **et noms des bons compagnons**. (insensible casse/espaces)
- `goodEdges()` — paires uniques d'associations `{a, b, type: good|bad}` pour la vue Réseau.

## État local (`CatalogueApp`)
```dart
String view = "fiches";   // "fiches" | "reseau"  (défaut tweakable)
String query = "";        // recherche
String cat = "tout";      // filtre catégorie : "tout" | clé CATS
String? sel;              // nœud sélectionné dans le Réseau
String? fiche;            // id de la plante ouverte en overlay (null = fermé)
bool showBad = true;      // afficher les liens « à éviter » dans le Réseau (tweakable)
```

## Header & filtres
- Header : kicker « 18 plantes » (= `PLANTS.length`), titre « Catalogue », action `heart` (favoris).
- **Recherche** (`csearch`) : champ `TextField` + icône loupe + bouton effacer (`x`) si texte.
  `onChange` met à jour `query` **et** réinitialise `sel`.
- **Chips catégorie** (`cchips`) : « Tout » + 6 catégories (puce couleur). → `ChoiceChip` / `Wrap`.
- **ViewSwitch** : Fiches (`squares-four`) / Réseau (`graph`).

## Vue FICHES (`FichesView`)
- Filtre = `(cat=="tout" || p.cat==cat) && plantMatches(p, query)`.
- Si « Tout » **sans** recherche → **groupé par catégorie** : pour chaque catégorie, en-tête
  (puce + label + compteur) puis **carrousel horizontal** de cartes (`carou`).
- Sinon → **grille** (`pgrid`) de cartes.
- État vide : icône loupe + « Aucune plante ne correspond. »
- **Carte plante** (`PlantCard`) : haut = points de difficulté (1-3) + icône ; corps = nom,
  « N variétés », méta (`sun` expo · `drop` eau). Couleur d'accent = couleur de catégorie.

## Vue RÉSEAU (`ReseauView`) — constellation d'associations
- Disposition en **spirale de Fermat** (angle d'or) : `n` nœuds répartis dans un disque,
  centre `(156,172)`, rayon max 116, viewBox `312 × 360`. Formule :
  `r = 116·√((i+0.5)/n)`, `ang = i·GA − π/2`, `GA = π·(3−√5)`.
- **Arêtes** (`<line>` SVG) entre compagnons (`good`) ; `bad` seulement si `showBad`.
- Sélection d'un nœud (`sel`) : il passe en `sel`, ses voisins en `linked`, les autres `dim` ;
  les arêtes liées deviennent `hot`, les autres `cold`. Re-toucher un nœud sélectionné →
  ouvre sa **fiche**.
- Panneau bas (`gpanel`) sur sélection : icône + nom + « N bons compagnons / N à éviter » +
  bouton « Fiche → ». Sinon hint « Touche une plante pour voir ses associations ».
- → En Flutter : `Stack` (nœuds = `Positioned` boutons) + `CustomPaint` pour les arêtes.
  Calcule les positions une fois (`useMemo` → champ calculé / `late final`).

## Fiche détaillée (`FicheDetail`, overlay plein écran)
Ouvre par-dessus l'écran (param `id`). Sections :
1. **Héro** teinté couleur de catégorie : retour (`caret-left`) + fermer (`x`), icône, nom, catégorie.
2. **Description** (`desc`).
3. **Faits** (grille) : Exposition · Arrosage · Sol · Gabarit · Espacement · Difficulté
   (icônes `sun/drop/mountains/arrows-out-*/gauge`).
4. **Semis & récolte** : 12 mois (J..D) + 2 bandes (`semis`, `recolte`) — même rendu que la
   vue Saison du Calendrier.
5. **Variétés** : chips.
6. **Associations** : compagnons `good` (chips tapables → ouvre leur fiche) + « À éviter » `bad`.
7. **Pied** : bouton plein « Ajouter au potager ».
→ `showModalBottomSheet` plein écran ou route `Navigator.push` avec transition.

## Interactions à câbler
| Élément | Action |
|---|---|
| Champ recherche | filtre live, reset `sel` |
| Chip catégorie | set `cat`, reset `sel` |
| ViewSwitch | bascule Fiches/Réseau |
| Carte plante / nœud | ouvrir la fiche (`fiche = id`) |
| Nœud (1er tap) | sélectionner (`sel`) ; 2e tap → fiche |
| Chip compagnon (fiche) | ouvrir la fiche du compagnon |
| « Ajouter au potager » | rattacher la plante à une zone (→ Potager) |
| `heart` header | favoris (à définir) |

## Mapping Flutter
- Données → `const` list de `Plante` (générer depuis `catalogue-data.jsx`).
- Recherche/filtre = pur Dart (`where` + `plantMatches`).
- Réseau = `CustomPaint` (arêtes) sous un `Stack` de nœuds ; états (sel/linked/dim) → opacité/échelle.
- Fiche = route/overlay ; `onOpen` ré-entrant (une fiche peut en ouvrir une autre).
