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

| Rôle              | Nom                 | Hex       | Usage                       |
|-------------------|---------------------|-----------|-----------------------------|
| Fond principal    | Crème lin           | `#F7F4EE` | Background app              |
| Fond élevé        | Blanc cassé         | `#FDFCF8` | Cartes, modales             |
| Surface alternée  | Beige doux          | `#EFEAE0` | Sections, séparateurs doux  |
| Texte principal   | Anthracite végétal  | `#1F2A24` | Titres, corps               |
| Texte secondaire  | Taupe               | `#6B6359` | Légendes, métadonnées       |
| Accent primaire   | Vert sauge profond  | `#3F6B4E` | Boutons, liens, actions     |
| Accent secondaire | Vert mousse clair   | `#A8C09A` | Hover, badges               |
| Accent chaud      | Terracotta doux     | `#C97B5A` | Alertes douces, récoltes    |
| Accent info       | Bleu lin            | `#6B8CAE` | Météo, infos                |
| Succès            | Vert tendre         | `#6FA86B` | Validations                 |
| Attention         | Ambre doux          | `#D9A441` | Avertissements              |
| Erreur            | Brique douce        | `#B5503F` | Erreurs (jamais rouge vif)  |
| Bordure           | Beige ombré         | `#DDD5C7` | Traits, séparateurs         |

## 3. Palette — Dark mode

> Bleu nuit **habité**, jamais noir. Même logique sémantique que le light mode.

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
