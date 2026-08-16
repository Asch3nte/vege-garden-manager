# 03 — Écran Calendrier

> Maquette : `Calendrier.html` + `calendrier.jsx` (export `CalendrierApp`).
> Une seule vue avec un **sélecteur 3 onglets** : Agenda · Mois · Saison.
> Contexte temporel de la maquette : **juin 2026, aujourd'hui = lundi 8**.

## État local
```dart
String view = "agenda";          // "agenda" | "mois" | "saison"  (défaut = tweakable)
int selected = 9;                // jour sélectionné dans la vue Mois
Map<String,bool> done = {"8-2": true}; // tâches cochées, clé = "jour-index"
// agendaScope = "semaine" | "mois"  (filtre de la vue Agenda)
```
`toggle(d,i)` inverse `done["$d-$i"]`. La clé `keyOf(d,i) = "$d-$i"`.

## Types de gestes (`T`) — couleur + icône + label
| clé | label | icône (Phosphor) | couleur |
|-----|-------|------------------|---------|
| semer | Semer | shovel | greenMid |
| planter | Planter | plant | primary |
| arroser | Arroser | drop | info |
| tailler | Tailler | scissors | ocre |
| tuteurer | Tuteurer | arrow-fat-up | terre |
| surveiller | Surveiller | eye | attention |
| recolter | Récolter | basket | aubergine |

Zones (`Z`) = mêmes 5 zones que Potager (nom + couleur).

## Données — `EVENTS` (clé = jour de juin 2026)
Carte `jour → [ {t:geste, z:zone, crop, v:variété} ]`. Reprendre l'objet `EVENTS`
intégralement depuis `calendrier.jsx` (jours 8→30, ~25 tâches). Exemples :
- **8** : Arroser Tomate (nord), Arroser Piment (serre), Récolter Fraise (bordure)
- **9** : Tuteurer Haricot (sud), Tailler Basilic (nord)
- **13** : Semer Radis (sud), Arroser Tomate (nord) … etc.

## Carte de tâche (`TaskCard`) — partagée Agenda + Mois
Bouton cochable : pastille colorée (couleur du geste) + icône · « <Label> — <crop> » ·
méta (puce couleur de zone + nom de zone + variété) · **check** à droite.
État `is-done` → barré / coché. → `InkWell` + `AnimatedContainer`.

## Vue AGENDA (`AgendaView`)
- **Bandeau résumé** (`summ`) : anneau de progression `doneCount/total` + « X tâches à faire
  cette semaine/ce mois-ci · N prévues sur 7 jours ». L'anneau utilise `--p` (%) →
  `CircularProgressIndicator` ou `CustomPaint`.
- **Timeline** : tâches groupées par jour (`tlgroup`), en-tête « Aujourd'hui / Demain / <jour> »
  + « N juin ». Filtre `scope` : semaine = jours 8..14, mois = 8..30.

## Vue MOIS (`MoisView`)
- Barre mois : ‹ **Juin 2026** › + pill « Aujourd'hui » (revient à `selected = 8`).
- **Grille** : en-tête Lun..Dim, 30 jours + cellules de débordement (`out`).
  Chaque jour : numéro + **points colorés** (jusqu'à 3 gestes, sinon `+N`).
  États : `today` (jour 8), `sel` (sélectionné), `alldone` (toutes tâches du jour cochées → ✓).
- Sous la grille : libellé du jour sélectionné + compteur `fait/total`, puis la liste
  `TaskCard` de ce jour (ou état vide « Rien de prévu — profitez du jardin », icône `coffee`).

## Vue SAISON (`SaisonView`) — lecture seule
Tableau **culture × 12 mois** (J..D). Données `SEASON` (8 cultures, ex. Tomate, Aubergine,
Courgette, Haricot, Basilic, Fraise, Radis, Mâche). Chaque culture a des **bandes** typées
`[kind, moisDébut, moisFin]` avec `kind ∈ semis | plant | recolte`. Colonne du mois courant
(juin, index 5) surlignée (`nowband`). Légende : Semis / Plantation / Récolte / Ce mois-ci.
→ En Flutter : un `Table` ou `GridView`, bandes = `Container` sur une piste 12 colonnes
(`gridColumn` CSS → calc d'offset/largeur). Couleurs : semis=greenMid, plant=primary, recolte=aubergine.

## Header & sélecteur
Header : kicker « Saison · été », titre « Calendrier », actions `funnel` (filtrer) + `plus` (ajouter).
**ViewSwitch** (`viewswitch`) : 3 onglets segmentés (Agenda `list-checks` / Mois `calendar-dots`
/ Saison `plant`), onglet actif rempli. → `SegmentedButton` ou `TabBar`.

## Interactions à câbler
| Élément | Action |
|---|---|
| `TaskCard` | toggle `done["$d-$i"]` + animation |
| Onglet ViewSwitch | changer `view` |
| Jour (Mois) | `selected = d` → liste du jour |
| ‹ › mois / pill Aujourd'hui | navigation mois (statique dans la maquette → à implémenter) |
| `plus` header | créer une tâche |
| `funnel` header | filtrer par zone/geste |

## Mapping Flutter
- `done` → `Set<String>` ou `Map`; persister par jour.
- Vues = 3 widgets sous un switch sur `view` (clé pour remonter l'anim, cf. `key={view}`).
- L'anneau et les bandes saison → `CustomPainter` (rendu fidèle au CSS).
