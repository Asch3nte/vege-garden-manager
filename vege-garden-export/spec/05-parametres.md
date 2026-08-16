# 05 — Écran Paramètres (+ menu « Plus »)

> Maquette : `Paramètres.html` + `parametres.jsx` (export `PlusApp`).
> Un seul téléphone interactif : Accueil en base → onglet **Plus** → menu → **Paramètres**
> → 6 catégories → sous-panneaux fonctionnels. C'est l'écran le plus riche en logique.

## Navigation (modèle en pile)
```dart
bool plusOpen = false;        // menu « Plus » ouvert
List<String> stack = [];      // ex. ["parametres","general"] — pile de sous-écrans
// openStyle = "popover" | "sheet"  (présentation du menu Plus — tweakable)
```
- `Plus` (onglet nav) → ouvre **PlusPopover** ou **PlusSheet** (bottom-sheet) selon `openStyle`.
- Choix « Paramètres » → `stack = ["parametres"]` (écran racine).
- Ouvrir une catégorie → `stack.add(id)`. Retour → `stack.removeLast()`. Fermer → `stack = []`.
- → En Flutter : `Navigator` (routes) plutôt qu'une pile maison ; `Plus` = `showModalBottomSheet`.

## Menu « Plus » (`PLUS_ITEMS`)
4 entrées : **Paramètres** (sliders) · **Post-récolte** (package) · **Communauté** (users-three,
*badge V2, désactivé*) · **À propos** (info). Présentation popover (ancrée nav) ou sheet (poignée + titre).

## État des préférences (`DEFAULT_PREFS`)
```dart
final prefs = {
  "langue":"auto", "theme":"auto", "unites":"metrique", "swipe":"standard", "niveau":"debutant",
  "geo":"off", "meteoAuto":true, "sync":false, "lunaire":false,
  "notifMaster":true, "dnd":false,
  "notif": {"semis":true,"arrosage":true,"recolte":true,"meteo":true,"entretien":false,"rotation":false},
};
```
`set(k,v)` met à jour une clé ; `setNotif(k,v)` met à jour `notif[k]`.
→ Persister via `shared_preferences`. **`niveau` est global** : il pilote la divulgation
progressive de l'Accueil (cf. `01-accueil.md`).

## Écran racine Paramètres (`ParametresRoot`)
- Barre : fermer (`x`) + titre « Paramètres ».
- **Profil** : avatar feuille + « Mon carnet » + « Niveau <x> · 100 % local ».
- **6 catégories** (`CATEGORIES`) en lignes tapables (icône teintée + label + sous-titre + chevron) :
  1. Préférences générales · 2. Confidentialité & opt-outs · 3. Notifications ·
  4. Synchronisation & sauvegarde · 5. Transparence des données · 6. À propos.
- Pied : cadenas + « tout est stocké localement… ».

## Contrôles réutilisables (→ widgets Flutter)
- **`Toggle`** → `Switch` custom (role switch). États on/off/disabled.
- **`Segmented`** → `SegmentedButton` (options `[valeur, label]`).
- **`SwitchRow`** → `ListTile` : icône teintée + label + sous-titre + `Switch` à droite (peut être `disabled`).
- **`FieldStack`** → label + hint au-dessus d'un contrôle pleine largeur.
- **`SubPanel`** → écran enfant avec barre retour + titre.

## Sous-panneaux (6)
### 1. Préférences générales (`GeneralPanel`)
- **Langue** (Auto/Français/English), **Thème** (Auto/Clair/Sombre), **Unités** (Métrique/Impérial) — segmenté.
- **Sens des gestes** : Standard/Inversé + **démo** visuelle (flèches « glisse une tâche » + chips
  Faite/Reporter) qui s'inverse selon le choix.
- **Niveau d'expérience** : Débutant/Intermédiaire/Expert (impacte recommandations + déverrouillages).

### 2. Confidentialité & opt-outs (`ConfidentialitePanel`)
- **Géolocalisation** : ligne tapable qui **cycle** off → manuelle → gps (sous-titre adaptatif).
- Switches : Météo auto, Sync WiFi locale, Calendrier lunaire, **Communauté P2P** (disabled, V2).
- Pied « Règle d'or » : aucune désactivation ne casse une fonctionnalité (toujours un repli).

### 3. Notifications (`NotificationsPanel`)
- **Maître** « Toutes les notifications ». Quand off → toutes les catégories sont `disabled`.
- **6 catégories** (`NOTIF_CATS`) : Semis, Arrosage, Récolte, Météo critique, Entretien, Rotation
  (switches, `on = master && notif[key]`).
- **Ne pas déranger** : switch + (si actif) plage horaire 22:00 → 07:00 (`timepair`).

### 4. Synchronisation & sauvegarde (`SyncPanel`)
- Carte statut sync (point + « Activée/Désactivée » + détail) + `Toggle`. Si activée → liste
  d'appareils appairés + « Appairer un appareil ».
- **Export & import** : Exporter JSON / Exporter CSV (→ `onExport(fmt)` ⇒ snackbar) / Importer.
- **Zone sensible** : « Réinitialiser toutes les données » (danger) → ouvre **dialogue 2 étapes**.

### 5. Transparence des données (`TransparencePanel`)
- **Tableau** des données stockées (`DATA_TABLES`) : Potagers & zones, Plantations, Tâches,
  Récoltes, Photos, Catalogue perso — avec nb d'enregistrements + taille, **Total 7,2 Mo**.
- **Journal des accès sensibles** : Géoloc (jamais), Notifications (dernier accès).
- Lien « Politique de confidentialité ». Pied : « Aucune donnée ne quitte l'appareil. »

### 6. À propos (`AProposPanel`)
- Identité : feuille + « Carnet vivant » + « Version 1.0.0 · build 1042 » + « Licence MIT ».
- Liens : Code source (github), Documentation, Signaler un bug, Contribuer.
- Crédits (contributeurs, données plantes, icônes Phosphor) + raccourci Transparence.

## Dialogues & feedback
- **Dialogue reset** (`dialog.step` 1→2) : double confirmation avant suppression définitive.
  → `showDialog` x2 (ou un dialog à 2 états).
- **Snackbar** (`snack`) : message + bouton OK, auto-dismiss 2,6 s. → `ScaffoldMessenger.showSnackBar`.

## Interactions à câbler
| Élément | Action |
|---|---|
| Onglet Plus | ouvrir menu (popover/sheet selon `openStyle`) |
| Entrée menu | router vers la section (Paramètres / À propos ; autres = snackbar « à venir ») |
| Catégorie | push sous-panneau |
| Tout switch/segmented | `set`/`setNotif` + **persistance** |
| Géoloc | cycle off→manuelle→gps |
| Export JSON/CSV | générer le fichier + snackbar |
| Réinitialiser | dialogue 2 étapes → purge locale + snackbar |
| Niveau | met à jour la pref globale (impacte Accueil) |

## Mapping Flutter
- Pile `stack` → vraies routes `Navigator`. Menu Plus → `showModalBottomSheet`.
- `prefs` → un `ChangeNotifier`/`Riverpod` provider + `shared_preferences`.
- Les `tint-*` (prim/aub/ocre/info/deep/terre) = pastilles d'icône colorées (fond accent @ ~14 %).
