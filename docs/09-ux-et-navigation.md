# 09 — UX & navigation

> Source : CAHIER §4.2. Principes UX, architecture de navigation, mapping des
> actions, patterns d'interaction et composants à créer.

## 1. Les 6 principes UX directeurs

1. **Zéro friction au démarrage** — aucun compte, aucune config obligatoire ;
   utilisable en 10 secondes après installation.
2. **Défauts intelligents** — tout est pré-rempli avec une valeur sensée.
   L'utilisateur *ajuste*, il ne *configure* pas.
3. **Une action = un endroit** — pas de duplication d'actions entre menus.
4. **Progressivité de la complexité** — vue simple par défaut, options avancées
   discrètes. Le débutant n'est jamais submergé.
5. **Réversibilité** — toute action destructive est annulable (undo) ou confirmée.
6. **Transparence des données** — l'utilisateur sait où sont ses données, peut
   les consulter, exporter, supprimer. Aucune opacité.

## 2. Navigation responsive

| Breakpoint            | Navigation                                          |
|-----------------------|-----------------------------------------------------|
| Mobile (< 600px)      | Bottom navigation bar 5 onglets + header contextuel |
| Tablette (600–1024px) | Navigation rail vertical (icônes + labels courts)   |
| Desktop (> 1024px)    | Sidebar latérale complète                           |

## 3. Les 5 sections principales

| # | Section           | Icône           | Contenu                                                                              |
|---|-------------------|-----------------|--------------------------------------------------------------------------------------|
| 1 | **Accueil**       | House           | Dashboard : météo, tâches du jour, alertes, aperçu potager                           |
| 2 | **Potager**       | Plant           | Zones, plantations, plan, historique. **FAB central** (action rapide)                |
| 3 | **Catalogue**     | BookOpen        | Base de connaissances, fiches, recherche                                             |
| 4 | **Calendrier**    | CalendarBlank   | Semis, tâches, rappels, calendrier lunaire (opt-in, V2)                              |
| 5 | **Plus** (`⋯`)    | DotsThree       | Paramètres (6 sous-sections), post-récolte, communauté (V2), à propos, transparence  |

## 4. Hiérarchie de l'AppBar

Ordre des actions (de droite à gauche) :

1. `⋮` — menu overflow (toujours présent)
2. `+` — création (si action de création disponible)
3. `?` — aide contextuelle (si `aide_contextuelle_active = true`)

## 5. Mapping des actions par panel

**Légende des patterns** : 🔵 AppBar `+` (action principale contextuelle) ·
⚫ AppBar `⋮` (actions secondaires) · 👆 Swipe / long press (item de liste) ·
📍 Inline (bouton/lien dans le contenu) · 🔄 Toggle (paramètres) · 👁️ Navigation pure.

### 🏠 Accueil
Consultation uniquement (👁️) : météo, tâches du jour, alertes, aperçu potagers.
**Pas de `+`** (aucune création depuis l'accueil). Actions rapides sur les
tâches via **swipe** (faite / reporter). Icône `Bell` (notifications) dans l'AppBar.

### 🌱 Potager (multi-niveaux)
| Niveau                      | Action principale (🔵 `+`)                             | Secondaires                                                                 |
|-----------------------------|--------------------------------------------------------|-----------------------------------------------------------------------------|
| 1 — Liste des potagers      | Créer un potager                                       | dupliquer/archiver (⚫), modifier/supprimer (👆 swipe), ouvrir (👁️)         |
| 2 — Vue d'un potager        | Créer une zone                                         | modifier/supprimer potager (⚫), plan/historique/rotation/équipements (📍)  |
| 3 — Vue d'une zone          | Ajouter une plantation                                 | modifier/supprimer zone, affecter équipement (⚫)                           |
| 4 — Vue d'une plantation    | **Mini-menu** (récolte / tâche / photo / observation)  | modifier/supprimer/terminer (⚫), historique (📍)                           |
| Transversal — Équipements   | Ajouter un équipement                                  | modifier/supprimer (👆), affecter à une zone                                |

> **Exception assumée** au principe « un `+` = une action » : la **vue plantation**
> ouvre un mini-menu (bottom sheet mobile / dropdown desktop) car 4 créations
> coexistent (récolte, tâche, photo, observation).

### 📖 Catalogue
Recherche (📍 barre) + filtres (📍 famille, période, expo, difficulté) ·
consulter une fiche (👁️) · favori (édition rapide) · **créer/modifier/dupliquer
une fiche perso** (🔵 `+`) · exporter/importer une fiche YAML · solutions à un
problème (mildiou, pucerons…). *La vue graphe des relations est reportée en V2.*

### 📅 Calendrier
Vues mois/semaine/jour (👁️) · tâches auto générées · créer/modifier/supprimer
tâche · marquer faite / reporter (👆 swipe) · créer un rappel · toggle calendrier
lunaire (V2) · filtres · planifier un semis depuis une recommandation. *Export
ICS : à confirmer.*

### ⋯ Plus
Paramètres généraux (langue, thème, unités, sens des gestes) · localisation ·
notifications · synchronisation · transparence des données · export/import ·
suppression totale (critique) · post-récolte · communauté (V2) · niveau
d'expérience · contenu éducatif · à propos · lien GitHub. Détail :
[11-parametres-et-opt-outs.md](11-parametres-et-opt-outs.md).

## 6. États d'écran (composants normalisés)

| Composant | Rôle |
|---|---|
| `AppSkeletonLoader` | Chargement initial d'écran (**jamais de spinner**) |
| `AppEmptyState` | État vide normalisé (illustration Duotone + CTA) |
| `AppErrorState` | Erreur avec remédiation (action + « Voir détails » repliable) |
| `AppOfflineBanner` | Indicateur offline contextuel |
| `AppSnackbar` | Feedback transitoire (4 variantes ; **pas de toast**) |
| `AppBottomSheet` | Confirmation modérée + formulaires |
| `AppDialog` | Confirmation critique |
| `AppDismissible` | Swipe unifié (respecte le paramètre `sens_swipe` global) |

## 7. Patterns d'interaction

- **Feedbacks gradués** par criticité : snackbar → bottom sheet → double dialog.
- **Réversibilité** : undo systématique (5 s) sur destruction standard ; soft
  delete (aucune donnée détruite physiquement sans action explicite).
- **Sauvegarde** : auto-save pour les paramètres ; submit explicite pour les
  formulaires.
- **Gestes** : swipe configurable globalement via `sens_swipe` (standard / inversé,
  avec aperçu interactif).
- **Accessibilité** : touch targets ≥ 48dp, contrastes ≥ 4.5:1, labels sémantiques.

## 8. Règles de cohérence globales

1. Skeleton, jamais spinner (chargement initial).
2. **Pas d'emoji dans l'UI**, jamais (ni messages, ni illustrations).
3. Snackbar unique (pas de toast), style cross-platform.
4. Undo systématique sur destruction standard (5 s).
5. Soft delete : aucune donnée détruite physiquement sans action explicite.
6. Auto-save pour les paramètres, submit explicite pour les formulaires.
7. Touch targets ≥ 48dp, contrastes ≥ 4.5:1, labels sémantiques systématiques.
8. `sens_swipe` global : tout composant swipeable lit le paramètre depuis le state.
9. Confirmations gradées selon criticité.
10. Pas d'erreur technique brute exposée : message clair + action + détails repliables.
