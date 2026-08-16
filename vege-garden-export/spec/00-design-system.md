# 00 — Design system partagé (à porter en Flutter/Dart)

Tokens communs aux 5 écrans. Source de vérité : `bg-directions.css` (`:root`).
À transposer dans un `ThemeData` + un fichier `tokens.dart`. **Thème clair uniquement**
pour l'instant (un thème sombre est listé dans les réglages mais non spécifié ici).

---

## 1. Couleurs

```dart
// tokens.dart — couleurs (hex tels quels depuis le CSS)
class AppColors {
  // Surfaces / fond
  static const bg        = Color(0xFFF6F2E9); // fond d'écran
  static const surface   = Color(0xFFFFFDF7); // cartes
  static const alt       = Color(0xFFECE6D6); // surface alternée
  static const border    = Color(0xFFDBD2C0);

  // Texte
  static const ink       = Color(0xFF241C28); // texte principal
  static const ink2      = Color(0xFF6E6357); // texte secondaire

  // Verts (marque)
  static const primary   = Color(0xFF2F7D4F);
  static const primary2  = Color(0xFF8FCB8E);
  static const greenMid  = Color(0xFF4FA06A);
  static const greenDeep = Color(0xFF1E4D33);

  // Aubergine (accent secondaire)
  static const aubergine     = Color(0xFF6A3D5B);
  static const aubergine2    = Color(0xFFB98AAC);
  static const aubergineDeep = Color(0xFF2C1A27);

  // Accents chauds (catégories / stades)
  static const warm     = Color(0xFFD6573D);
  static const ocre     = Color(0xFFE0A82E);
  static const bordeaux = Color(0xFF9B3B43);
  static const terre    = Color(0xFFA9744B);

  // Sémantique
  static const success   = Color(0xFF4CA464);
  static const attention = Color(0xFFE0A82E);
  static const error     = Color(0xFFB0463C);
  static const info      = Color(0xFF4E89B0);
}
```

### `color-mix` du CSS → Flutter
Beaucoup de fonds de tags/alertes sont des `color-mix(in srgb, <accent> X%, <base>)`.
Équivalent Dart : `Color.alphaBlend(accent.withOpacity(X/100), base)`.
Ex : tag « sage » = `Color.alphaBlend(AppColors.greenMid.withOpacity(.18), Colors.transparent)`
sur fond clair → en pratique `greenMid.withOpacity(.18)`, texte `greenDeep`.

---

## 2. Espacement & rayons

```dart
class Sp { static const x1=4.0, x2=8.0, x3=12.0, x4=16.0, x5=24.0, x6=32.0, x7=48.0, x8=64.0; }
class R  { static const sm=6.0, md=8.0, lg=12.0, xl=24.0, full=9999.0; }
```

## 3. Ombres (elevation)

```dart
// e-1 (cartes), e-2 (cartes flottantes t2), e-3 (frame téléphone)
const e1 = [BoxShadow(color: Color(0x0D1F1A16), blurRadius: 2, offset: Offset(0,1)),
            BoxShadow(color: Color(0x0D1F1A16), blurRadius: 8, offset: Offset(0,2))];
const e2 = [BoxShadow(color: Color(0x121F1A16), blurRadius: 6, offset: Offset(0,2)),
            BoxShadow(color: Color(0x121F1A16), blurRadius: 26, offset: Offset(0,10))];
const e3 = [BoxShadow(color: Color(0x291F1A16), blurRadius: 44, offset: Offset(0,16))];
```

## 4. Typographie

Polices : **Manrope** (titres, poids 500–800) + **Inter** (corps, 400–600).
Via `google_fonts` : `GoogleFonts.manrope(...)` / `GoogleFonts.inter(...)`.

| Rôle (classe CSS)        | Police   | Taille | Poids | Notes |
|--------------------------|----------|--------|-------|-------|
| Titre écran `.pbar h1`   | Manrope  | 26     | 800   | letter-spacing -.01em |
| Section `.slabel`        | Manrope  | 13     | 700   | |
| Label tâche `.lab`       | Inter    | 14     | 500   | |
| Tag `.tag`               | Inter    | 11     | 600   | |
| Température `.temp`      | Manrope  | 21     | 700   | |
| Légende/`.cap`/`.sub`    | Inter    | 11–12  | 400–600 | couleur ink2 |
| Nav bas `.nav`           | Inter    | 10     | 400/600 | actif = primary |

`-webkit-font-smoothing:antialiased`, `line-height:1.5` par défaut.

---

## 5. Icônes
**Phosphor Icons** (MIT). En Flutter : package `phosphor_flutter`.
Le CSS utilise les styles `regular` / `ph-bold` / `ph-fill` / `ph-duotone` →
`PhosphorIconsRegular/Bold/Fill/Duotone`. Les noms (`ph-leaf`, `ph-drop`,
`ph-basket`, `ph-sun`, `ph-plant`…) se mappent 1:1 sur le package.

---

## 6. Coquille « téléphone » (commune aux 5 écrans)

Toutes les maquettes sont rendues dans un cadre fixe **344 × 716**, rayon 32,
bordure 1px `border`, ombre `e3`. **C'est un artefact de maquette** : dans l'app
Flutter réelle, supprime le cadre et laisse chaque écran remplir le `Scaffold`.
Garde par contre la structure interne, identique partout :

```
Scaffold
 ├─ (status bar simulée — À SUPPRIMER, fournie par l'OS)
 ├─ Header  .pbar  → kicker/greet + titre Manrope 26/800 + actions (IconButtons)
 ├─ Corps   .pscreen  → contenu scrollable, gap vertical = Sp.x3 (12)
 └─ BottomNavigationBar  .bnav  → 5 onglets : Accueil · Potager · Catalogue · Calendrier · Plus
```

### Barre de navigation (identique partout)
5 items, icône Phosphor + label, item actif en `primary` (icône `fill` + label semi-bold) :
`["house","Accueil"]`, `["plant","Potager"]`, `["book-open","Catalogue"]`,
`["calendar-blank","Calendrier"]`, `["dots-three","Plus"]`.
Hauteur 62, fond `surface`, bord haut 1px `border`. → `BottomNavigationBar` ou `NavigationBar`.

### Décor « t2 » (Accueil + Paramètres seulement)
Ces 2 écrans posent un décor derrière le contenu (`data-variant="t2"` + `SceneAromates`) :
- une **arche verte** en haut (dégradé `greenDeep → primary`, coin bas arrondi) qui passe
  sous le header → le texte du header devient **blanc** sur ces écrans ;
- des **taches organiques** (blobs) ocre / aubergine / vert en fond ;
- un décor botanique léger (tapis d'aromates + grimpante).
→ En Flutter : un `Stack` avec un `CustomPainter` de fond (dégradé + formes) sous le contenu.
  Traite-le comme purement décoratif ; aucune logique ne s'y rattache.

---

## 7. Modèles de données partagés

Les zones du potager et les types de gestes sont réutilisés par **Potager** et **Calendrier**.
Définis-les une fois :

```dart
enum Geste { semer, planter, arroser, tailler, tuteurer, surveiller, recolter }
// couleur + icône + label par geste : cf. 03-calendrier.md (table T)

class Zone {
  final String id, name, dims, sun, water;
  final Color color;        // warm / aubergine / greenDeep / greenMid / bordeaux
  final List<Crop> crops;
}
class Crop {
  final String name, variete, task, due;
  final int stage;          // 1..5 (cf. STAGES)
  final Color color;
  final bool ok;            // true = pas d'urgence
}
const stages = ["Semis","Jeune pousse","Croissance","Floraison","Récolte"];
```

> Les 5 zones de référence (Carré nord, Serre, Carré sud, Bac aromates, Bordure sud)
> sont détaillées dans `02-potager.md` — c'est la donnée seed à reprendre telle quelle.

---

## 8. Principe produit à respecter (transversal)
**100 % local, aucun compte, aucun traceur.** Chaque opt-out a un mode de repli
(rien ne casse si on désactive géoloc / météo / sync). Persistance locale
(ex. `shared_preferences` pour les prefs, `sqflite`/`isar` pour les données).
Ce principe est visible dans l'UI (Paramètres) — ne pas le contredire côté code.
