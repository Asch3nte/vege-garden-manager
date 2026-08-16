# 01 — Écran Accueil

> Maquette : `Accueil.html` + `accueil-final.jsx` (export `PhoneAccueil`).
> Tableau de bord du jour. **Divulgation progressive** selon le niveau du jardinier.

## Rôle
Vue d'atterrissage : météo du jour, tâches du jour, alertes, aperçu des zones.
Le contenu affiché dépend du **niveau d'expérience** (réglage global, cf. Paramètres).

## État / entrées
```dart
// niveau ∈ Découverte | Apprenti | Jardinier | Expert  (vient des prefs globales)
final levels = ["Découverte","Apprenti","Jardinier","Expert"];
final idx = levels.indexOf(niveau);
final progress = [22,52,78,100][idx];      // % de la barre du pill niveau
final statsUnlocked = idx >= 2;            // bloc « Récoltes » visible dès « Jardinier »
```
Pas d'autre état local — c'est un écran de lecture (les interactions mènent ailleurs).

## Arborescence (de haut en bas, dans `.pscreen`)
1. **Header** (`.pbar`) — sur décor t2, texte **blanc** :
   - kicker « Mardi 6 juin », titre **« Mon potager »** (Manrope 26/800)
   - actions : cloche (avec pastille `warm`) + menu `dots-three-vertical`
2. **Ligne niveau** (`.levelrow`) :
   - pill niveau : icône `seal-check` + libellé + **barre de progression** (`width: progress%`)
   - pill « 3 zones » (icône `squares-four`)
3. **Météo** (`.weather`) — carte info : icône `cloud-sun`, **18°**, « Partiellement nuageux »,
   à droite **« Bon pour arroser »** / « Pluie demain matin ». Fond `info @14%`, bord `info @30%`.
4. **Tâches du jour** — label « Tâches du jour » + compteur `3`, puis carte avec lignes `.task` :
   - case ronde (22px, bord `primary @45%`) + libellé + tag de zone
   - une tâche `done` (case cochée, tag « Fait » `harvest`)
   - pied « Voir les 3 tâches » → `caret-right`
5. **Grille stats** (`.statgrid`, 2 colonnes) :
   - **Alerte** (toujours) : `warning-circle`, gros « 1 », « Alerte · risque pucerons »
   - si `statsUnlocked` → **Récoltes** : `basket`, « 12 », « Récoltes cette saison »
   - sinon → carte **verrouillée** : `lock-simple`, « Saison », « Stats au niveau Jardinier »
6. **Aperçu du potager** (`.garden`) — 3 tuiles `gtile` : vignette dégradée + légende
   (« Carré nord », « Bac aromates », « Serre »). Les vignettes `veg-1/2/3` sont des
   dégradés (placeholder photo) → à remplacer par de vraies photos de zone.

## Données (seed)
3 tâches du jour, 1 alerte, 3 zones en aperçu, compteur récoltes = 12. Météo : 18°, nuageux,
pluie demain. Toutes codées en dur dans la maquette → à brancher sur le vrai modèle
(tâches du jour = filtre `due == aujourd'hui` sur les tâches ; récoltes = somme saison).

## Interactions à câbler (Flutter)
| Élément | Action attendue |
|---|---|
| Case d'une tâche | cocher / décocher → maj état + animation (cf. Calendrier `done`) |
| « Voir les 3 tâches » | ouvrir le **Calendrier** (vue Agenda) |
| Tuile de zone | ouvrir le **détail de zone** (cf. `02-potager.md` `ZoneDetail`) |
| Carte alerte | ouvrir le détail de l'alerte / la culture concernée |
| Pill niveau | (optionnel) raccourci vers réglage Niveau |
| Cloche | écran notifications |
| Carte verrouillée | tooltip / lien « comment débloquer » |

## Mapping Flutter
- `.pbar` → `Padding` + `Row` (titre `Expanded`, actions `Row` d'`IconButton`).
- `.weather`, `.card` → `Container` `surface`, rayon `R.lg`, ombre `e2` (décor t2).
- `.statgrid` → `Row` de 2 `Expanded` (ou `GridView` 2 col, `shrinkWrap`).
- `.garden` → `Row` de 3 `Expanded` (gap `Sp.x2`).
- Le bloc qui change selon le niveau → simple `if (statsUnlocked)`.
