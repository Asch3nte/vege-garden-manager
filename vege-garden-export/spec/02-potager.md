# 02 — Écran Potager

> Maquette : `Potager.html` + `potager.jsx`
> (exports `PotagerGrille`, `PotagerMap`, `PotagerListe`, `ZoneDetail`).
> Plan du potager vu de dessus, tapable → détail de zone.

## Rôle
Visualiser ses zones de culture et plonger dans le détail d'une zone (cultures, stades,
prochaines tâches). La maquette propose **3 traitements du plan** (à trancher) + **1 écran détail**.

## Données seed (à reprendre telles quelles — `ZONES`)
5 zones, chacune avec `id, name, dims, sun, water, color, icon, crops[]`.

| id | name | dims | sun | water | color |
|----|------|------|-----|-------|-------|
| nord | Carré nord | 1,2 × 1,2 m | Plein soleil | 1×/jour | warm |
| serre | Serre | 2 × 3 m | Abrité | Goutte-à-goutte | aubergine |
| sud | Carré sud | 1,2 × 1,2 m | Soleil | 1×/2 jours | greenDeep |
| aromates | Bac aromates | 0,8 × 0,4 m | Mi-ombre | 2×/semaine | greenMid |
| bordure | Bordure sud | 3 × 0,4 m | Soleil | 1×/jour | bordeaux |

**Cultures (`crops`)** — par zone, ex. Carré nord :
`{ name:"Tomate", variete:"Cœur de bœuf", stage:4, color:warm, icon:"orange-slice", task:"Arroser", due:"Aujourd'hui", ok:false }`,
`{ name:"Basilic", variete:"Grand vert", stage:3, ..., task:"Pincer les fleurs", due:"Dans 2 j", ok:true }`.
(Serre : Aubergine st.5 « Récolter », Piment st.4 « Arroser ». Sud : Courgette, Haricot.
Aromates : Romarin/Thym/Origan st.4-5. Bordure : Fraise st.5 « Récolter ».)
→ Reprendre l'intégralité depuis `potager.jsx` (objet `ZONES`).

Helpers : `dueToday(zone)` = une culture a `due` ≈ « aujourd'hui » ou « à maturité » →
affiche une **pastille goutte** (`drop`) sur la planche.

`stages = ["Semis","Jeune pousse","Croissance","Floraison","Récolte"]` — le champ `stage` (1..5)
est rendu par le composant **`Stage`** : 5 segments, les `n` premiers « allumés » + libellé.

## A · Plan en grille (`PotagerGrille`)
Grille de **planches** (`Bed`) — la Serre en pleine largeur (`span`), puis 4 zones en 2 colonnes.
Chaque planche : couleur de zone (bord/teinte `--bed`), nom, 3 puces de cultures (`cchip`),
pastille goutte si tâche du jour. Sous la grille : **légende** (Fruits-légumes / Aromates /
Sous serre / Tâche du jour).

## B · Plan spatial (`PotagerMap`)
Mêmes planches mais **positionnées en absolu** pour évoquer la disposition réelle du jardin
(coordonnées `top/left/right/width/height` dans l'objet `pos`). → En Flutter : `Stack` +
`Positioned`, ou un `CustomMultiChildLayout`. Mêmes data, même légende.

## C · Plan + liste (`PotagerListe`)
Mini-plan en haut (planches compactes) + **liste de zones** (`zrow`) : barre de couleur,
nom, méta (noms des cultures joints par « · »), statut tâche (« À jour » si rien d'urgent,
sinon le libellé de la prochaine tâche), chevron. Label « Zones · 5 ».

> **À trancher avec le PO** : garder A, B ou C comme vue principale (ou bascule). Les 3
> partagent header/nav/légende ; seul le corps du plan change.

## Détail de zone (`ZoneDetail`, param `zoneId`)
Écran à part entière (remplace le header par un header **avec retour**) :
1. Header retour : `caret-left` + kicker (= exposition `sun`) + nom de zone.
2. **Héro** (`zhero`, teinté couleur de zone) avec 3 puces info : `ruler` dims · `drop` water ·
   `plant` N cultures.
3. Label « Cultures · N », puis une **carte par culture** (`culture`) :
   - en-tête : pastille colorée + icône, nom, variété
   - rangée : composant `Stage` (5 segments + libellé du stade) + **pastille tâche**
     (`bell-ringing` si tâche à faire, `check-circle` si « À jour ») avec « tâche · échéance ».

## Interactions à câbler
| Élément | Action |
|---|---|
| Planche / ligne de zone | → ouvrir `ZoneDetail(zoneId)` |
| Bouton retour (détail) | revenir au plan |
| Recherche / `dots` (header) | recherche de zone / menu |
| (futur) tâche dans le détail | cocher → maj `done`, comme Calendrier |

## Mapping Flutter
- `Bed` → widget `ZonePlanche` réutilisable (param `zone`, `span`, `style`).
- `Stage` → `Row` de 5 `Container` (4×8 px) + `Text` du libellé ; segments allumés = couleur zone.
- Vue A → `Column`/`Wrap`. Vue B → `Stack`+`Positioned`. Vue C → `ListView` de `zrow`.
- `ZoneDetail` → route séparée (`Navigator.push`), reçoit l'objet `Zone`.
