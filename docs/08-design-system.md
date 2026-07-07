# 08 — Design system « Carnet vivant »

> Source : CAHIER §4.1. Direction artistique et tokens visuels. La DA minimaliste
> de §1.5 est **superséd​ée** par celle-ci (plus complète et plus récente).

## 1. Concept & principes directeurs

Direction artistique **« Carnet vivant »**, 5 principes :

1. **Chaleur sans naïveté** — carnet de jardinier, jamais livre pour enfants.
2. **Rigueur scandinave** — espaces aérés, hiérarchie claire, une info à la fois.
3. **Matériaux naturels** — lin, terre, mousse, bois clair ; aucune surface plastique.
4. **Confort en toutes conditions** — lisible en plein soleil comme en soirée.
5. **Discrétion premium** — qualité dans les détails (courbes, espacements, transitions).

| Élément                 | Valeur                                                            |
|-------------------------|-------------------------------------------------------------------|
| Approche maquettage     | Hybride : specs textuelles → Penpot (2–3 écrans pivots) → Flutter |
| Typographie titres      | **Manrope**                                                       |
| Typographie corps & UI  | **Inter**                                                         |
| Iconographie            | **Phosphor Icons** (open source, MIT)                             |
| Formes                  | Rayons 6/8/12/24 px, ombres douces, espacements multiples de 4    |

## 2. Palette — Light mode

> 🎨 **Mise à jour (maquettes Claude Design).** Les valeurs ci-dessous reflètent
> les maquettes haute-fidélité validées (export `vege-garden-export/`,
> `bg-directions.css`). Elles **remplacent** les teintes initiales du CAHIER
> §4.1 (légèrement différentes), qui restent consultables dans l'historique Git.
> Le dark mode (§3) n'a **pas** été redécidé par les maquettes (palette A / light
> uniquement) : il conserve les valeurs du CAHIER en attendant une décision.

### 2.1 Rôles sémantiques

| Rôle              | Nom                 | Hex       | Token CSS        | Usage                       |
|-------------------|---------------------|-----------|------------------|-----------------------------|
| Fond principal    | Crème lin           | `#F6F2E9` | `--c-bg`         | Background app              |
| Fond élevé        | Blanc cassé         | `#FFFDF7` | `--c-surface`    | Cartes, modales             |
| Surface alternée  | Beige doux          | `#ECE6D6` | `--c-alt`        | Sections, séparateurs doux  |
| Texte principal   | Anthracite végétal  | `#241C28` | `--c-ink`        | Titres, corps               |
| Texte secondaire  | Taupe               | `#6E6357` | `--c-ink-2`      | Légendes, métadonnées       |
| Accent primaire   | Vert sauge profond  | `#2F7D4F` | `--c-primary`    | Boutons, liens, actions     |
| Accent secondaire | Vert mousse clair   | `#8FCB8E` | `--c-primary-2`  | Hover, badges               |
| Accent chaud      | Terracotta doux     | `#D6573D` | `--c-warm`       | Alertes douces, récoltes    |
| Accent info       | Bleu lin            | `#4E89B0` | `--c-info`       | Météo, infos                |
| Succès            | Vert tendre         | `#4CA464` | `--c-success`    | Validations                 |
| Attention         | Ambre doux          | `#E0A82E` | `--c-attention`  | Avertissements              |
| Erreur            | Brique douce        | `#B0463C` | `--c-error`      | Erreurs (jamais rouge vif)  |
| Bordure           | Beige ombré         | `#DBD2C0` | `--c-border`     | Traits, séparateurs         |

### 2.2 Palette décorative

> Couleurs **non sémantiques**, dédiées au décor « Carnet vivant » : dégradés des
> tuiles potager, séparateurs végétaux (trait · point · trait), blobs et arches
> organiques, micro-illustrations. À ne **jamais** utiliser pour véhiculer un
> état (succès/erreur…) — c'est le rôle de la palette §2.1.

| Nom               | Hex       | Token CSS           | Usage                                  |
|-------------------|-----------|---------------------|----------------------------------------|
| Vert moyen        | `#4FA06A` | `--c-green-mid`     | Dégradés de tuiles, accents végétaux   |
| Vert profond      | `#1E4D33` | `--c-green-deep`    | Arches/en-têtes immersifs, dégradés    |
| Aubergine         | `#6A3D5B` | `--c-aubergine`     | Séparateurs végétaux, récoltes, décor  |
| Aubergine clair   | `#B98AAC` | `--c-aubergine-2`   | Variante claire de l'aubergine         |
| Aubergine profond | `#2C1A27` | `--c-aubergine-deep`| Fonds sombres ponctuels (chips)        |
| Bordeaux          | `#9B3B43` | `--c-bordeaux`      | Dégradés de tuiles, accents chauds     |
| Terre             | `#A9744B` | `--c-terre`         | Décor « terre », grimpantes            |
| Ocre              | `#E0A82E` | `--c-ocre`          | Décor chaud (≡ Attention sémantique)   |

## 3. Palette — Dark mode

> Bleu nuit **habité**, jamais noir. Même logique sémantique que le light mode.
>
> ⚠️ **Non revalidé par les maquettes Claude Design** (qui ne couvrent que le
> light mode, cf. §2). Ces valeurs sont celles du CAHIER §4.1 ; à confirmer ou
> à réviser quand un dark mode sera maquetté.

| Rôle              | Nom                 | Hex       |
|-------------------|---------------------|-----------|
| Fond principal    | Bleu nuit profond   | `#161D26` |
| Fond élevé        | Bleu nuit doux      | `#1E2733` |
| Surface alternée  | Bleu nuit clair     | `#26303D` |
| Texte principal   | Crème douce         | `#EAE6DC` |
| Texte secondaire  | Gris bleuté         | `#9AA3AE` |
| Accent primaire   | Vert sauge lumineux | `#7FB088` |
| Accent secondaire | Vert mousse         | `#5C8A6A` |
| Accent chaud      | Terracotta clair    | `#D89072` |
| Accent info       | Bleu lin clair      | `#8FA8C7` |
| Succès            | Vert tendre clair   | `#8BC487` |
| Attention         | Ambre clair         | `#E8B860` |
| Erreur            | Brique claire       | `#D17560` |
| Bordure           | Bleu nuit clair     | `#2F3A48` |

### 3.1 Couleurs des termes du glossaire (ADR-0017 D5)

> Un **terme cliquable** (lien wiki, `TermeCliquable`, puce, badge) est teinté
> par le **type** du terme visé — même grammaire visuelle partout dans l'app :
> texte semi-gras souligné (inline) ou puce bordée (chips). Implémentation :
> extension de thème `CouleursTermes` (`lib/app/theme/couleurs_termes.dart`),
> enregistrée dans les deux thèmes. **Aucune couleur inventée** : chaque type
> réutilise un token §2/§3 existant.

| Type de terme | Light (token §2)                       | Dark (token §3 — à revalider)       |
|---------------|----------------------------------------|-------------------------------------|
| **Famille**   | Vert sauge profond `#2F7D4F` (primaire)| Vert sauge lumineux `#7FB088`       |
| **Maladie**   | Brique douce `#B0463C` (erreur)        | Brique claire `#D17560`             |
| **Ravageur**  | Terre `#A9744B` (déco `--c-terre`)     | Terracotta clair `#D89072`          |
| **Outil**     | Bleu lin `#4E89B0` (info)              | Bleu lin clair `#8FA8C7`            |
| **Notion**    | Aubergine `#6A3D5B` (déco)             | Aubergine clair `#B98AAC`           |

## 4. Typographie

| Style       | Police          | Taille  | Graisse | Interligne  | Usage                 |
|-------------|-----------------|---------|---------|-------------|-----------------------|
| Display     | Manrope         | 32      | 700     | 1.2         | Titres d'écran        |
| H1          | Manrope         | 26      | 700     | 1.25        | Section majeure       |
| H2          | Manrope         | 22      | 600     | 1.3         | Titre de carte        |
| H3          | Manrope         | 18      | 600     | 1.35        | Titres mineurs        |
| Body Large  | Inter           | 16      | 400     | 1.5         | Corps de lecture      |
| Body        | Inter           | 14      | 400     | 1.5         | UI standard           |
| Body Small  | Inter           | 13      | 400     | 1.45        | Métadonnées           |
| Caption     | Inter           | 12      | 500     | 1.4         | Tags, badges          |
| Button      | Inter           | 14      | 600     | 1           | Texte de bouton       |
| Numeric     | Inter (tabular) | var.    | 500     | 1.3         | Chiffres, calendrier  |

**Règles** : taille mini UI **12px** ; texte long en **Body Large 16px** ;
max **3 niveaux hiérarchiques** par écran.

## 5. Espacement (base 4px)

`4 / 8 / 12 / 16 / 24 / 32 / 48 / 64` → tokens `space-1` … `space-8`.
**Aucune valeur arbitraire** (pas de 17px, 22px…).

| Token   | px  | Usage                           |
|---------|-----|---------------------------------|
| space-1 | 4   | icône ↔ texte                   |
| space-2 | 8   | padding compact (badges)        |
| space-3 | 12  | padding boutons, listes denses  |
| space-4 | 16  | padding standard cartes         |
| space-5 | 24  | entre sections                  |
| space-6 | 32  | marges latérales d'écran        |
| space-7 | 48  | séparation de blocs             |
| space-8 | 64  | écrans vides, onboarding        |

## 6. Élévation & rayons

Style « papier posé sur table » : ombres très diffuses, faible opacité, **pas
d'inset, pas d'ombres colorées**.

| Token       | Usage                     |
|-------------|---------------------------|
| elevation-0 | surfaces plates           |
| elevation-1 | cartes au repos           |
| elevation-2 | cartes actives, dropdowns |
| elevation-3 | modales, popovers         |
| elevation-4 | tooltips, notifications   |

| Rayon       | px    | Usage                       |
|-------------|-------|-----------------------------|
| radius-sm   | 6     | chips, tags, inputs petits  |
| radius-md   | 8     | boutons, inputs standards   |
| radius-lg   | 12    | cartes, listes, conteneurs  |
| radius-xl   | 24    | modales, sheets, popovers   |
| radius-full | 9999  | avatars, FAB, ronds         |

## 7. Iconographie (Phosphor Icons)

> ⚠️ **Implémentation en attente.** Le package `phosphor_flutter` (2.1.0, dernier
> publié) est **incompatible avec Flutter 3.44.1** : il étend `IconData`, devenue
> une classe `final`, donc il ne compile pas. Aucun correctif en amont (ni publié,
> ni sur la branche `main`). En attendant, l'app utilise les **icônes Material**
> comme substituts (cf. note dans `pubspec.yaml`). Phosphor reste la cible : à
> rebrancher via un wrapper local (fichiers `.ttf` Phosphor, MIT, + nos propres
> `IconData const`) ou dès qu'une version compatible paraît.

| Variante        | Usage                                   |
|-----------------|-----------------------------------------|
| Regular (1.5px) | Par défaut partout                      |
| Bold (2px)      | État actif/sélectionné                  |
| Duotone         | États vides, illustrations, onboarding  |
| Fill            | Indicateurs critiques uniquement        |

Tailles : `icon-sm` 16 · `icon-md` 20 (défaut) · `icon-lg` 24 · `icon-xl` 32 ·
`icon-2xl` 48+. **Une icône est toujours accompagnée d'un label ou tooltip.**

## 8. Accessibilité

- Conformité **WCAG AA minimum** (AAA si possible).
- Texte courant ≥ **4.5:1** ; texte large (≥18px) ≥ **3:1** ; composants ≥ **3:1**.
- Couleurs sémantiques (succès/attention/erreur) **jamais seules** → toujours
  doublées d'une icône ou d'un texte.
- Cible tactile minimale **44×44 px** (visée projet : **48dp**).

## 9. Touches signature (à affiner en maquettage)

- Séparateurs végétaux subtils (trait · point · trait) sur écrans clés.
- Micro-illustrations Duotone pour les états vides (graine, arrosoir…).
- Transitions douces : **200–300 ms**, easing `ease-out`, sans rebond.
- Photos de fiches plantes légèrement désaturées pour s'harmoniser à la palette.

> Composants UI normalisés à créer (skeleton, empty/error states, snackbar,
> bottom sheet, dialog, dismissible swipe…) : voir [09-ux-et-navigation.md](09-ux-et-navigation.md).
