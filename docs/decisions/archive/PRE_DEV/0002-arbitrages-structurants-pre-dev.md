# ADR-0002 — Arbitrages structurants pré-développement (taxonomie, surface, i18n des fiches)

- **Statut** : Accepté (directions) · concrétisation des listes de valeurs **à confirmer** (cf. fin)
- **Date** : 2026-06-04
- **Contexte** : l'[audit pré-dev](AUDIT_PRE_DEV.md) a identifié 6 incohérences
  critiques. Cet ADR tranche les **trois décisions structurantes** de priorité 1
  (C1, C3, M2) qui conditionnent les enums du Domain, le schéma SQL et les mappers.
  Les points C2, C4, C5, C6 et les majeurs/mineurs seront traités lors de la passe
  de correction des specs (ils découlent en partie des décisions ci-dessous).

---

## D1 — Taxonomie des plantes : **catégorie large + usages multi-valués** (résout C1)

### Décision

On remplace les trois taxonomies concurrentes par un modèle **à deux axes orthogonaux** :

1. **`categorie`** — classe primaire **exclusive**, sert au classement (1 fiche = 1 dossier).
2. **`usages`** — rôles fonctionnels **multi-valués** (≥ 1), transversaux à la catégorie.
3. **`sous_type`** — précision **optionnelle**, pertinente uniquement pour `categorie: legume`.

Ce modèle résout les cas réels où une plante cumule plusieurs rôles (le **souci** est
`fleur` **et** `medicinale` **et** sert au `compagnonnage`), ce qu'une catégorie unique
exclusive ne peut pas exprimer — cause racine de C1.

### Concrétisation proposée

> **Convention de nommage** : identifiants Dart en `camelCase`, valeurs YAML/SQL en
> `snake_case` (ex. enum `petitFruit` ↔ YAML `petit_fruit`). Le mapper assure la correspondance.

```dart
/// Classe primaire (exclusive) — correspond à un dossier asset.
/// petitFruit (fraisier, framboisier, groseillier) est distinct de fruit
/// (arbres fruitiers) : cycle, taille et gestion radicalement différents.
enum CategoriePlante { legume, aromatique, fruit, petitFruit, fleur, cereale, engraisVert }

/// Précision optionnelle, uniquement si categorie == legume.
/// Distinctions agronomiques réelles (organe récolté, rotation, maladies) :
///   legumeTige     → céleri-branche, rhubarbe, cardon, asperge (ni feuille ni racine)
///   legumeFleur    → chou-fleur, brocoli, artichaut (récolte = inflorescence)
///   legumeTubercule→ pomme de terre, topinambour (tige souterraine ≠ racine pivotante)
enum SousTypeLegume {
  legumeFruit, legumeFeuille, legumeRacine, legumeBulbe,
  legumeTige, legumeFleur, legumeTubercule
}

/// Rôles fonctionnels (multi-valués, au moins un).
enum UsagePlante {
  alimentaire, condimentaire, medicinale, compagnonnage, repulsif,
  mellifere, pollinisateur, engraisVert, couvreSol, briseVent,
  tuteurVivant, ornementale, fourrage
}
```

**Dissolutions** (groupes du périmètre doc 07 §2 qui n'étaient pas des catégories) :

| Groupe d'origine        | Désormais exprimé par                                            |
|-------------------------|-----------------------------------------------------------------|
| Médicinales             | `usages: [medicinale]` (+ sa vraie `categorie`)                 |
| Vivaces comestibles     | `cycle.type: vivace` + `usages: [alimentaire]` (pas une catégorie) |
| Grains & céréales       | `categorie: cereale`                                            |
| Engrais verts / couvre-sols | `categorie: engraisVert` (cas pur) **ou** `usages: [engraisVert, couvreSol]` (rôle secondaire) |
| Légumineuses            | `famille_botanique: Fabaceae` + `rotation.famille` (pas une catégorie) |

### Représentation YAML

```yaml
categorie: legume          # CategoriePlante (exclusive, = dossier)
sous_type: legume_fruit    # (optionnel — seulement si categorie: legume)
usages:                    # ≥ 1 valeur
  - alimentaire
```

### Conséquences (à propager en passe de correction)

- **Dossiers assets** : `fleurs_compagnonnage/` → `fleurs/` ; **ajouter** `petits_fruits/`,
  `cereales/`, `engrais_verts/`. Inchangés : `legumes/`, `aromatiques/`, `fruits/` (arbres).
  ⚠️ La fiche d'exemple `fruits/fraise.yaml` (doc 07) **migre** vers `petits_fruits/`.
- **Doc 05 §5** : remplacer l'ancien `CategoriePlante` (8 valeurs) par les trois enums ci-dessus.
- **Doc 06** : `fiches_plantes_personnelles.categorie` CHECK → 7 valeurs ; prévoir une
  colonne dénormalisée `usages` (texte) pour la recherche (source de vérité = `yaml_contenu`).
- **Doc 07 + `_schema/fiche_plante_schema.yaml`** : ajouter `sous_type` (opt.) et `usages` (requis),
  mettre à jour l'enum `categorie`, et le périmètre §2 (les 6 groupes → catégories + usages).
- **CONTRIBUTING.md** : mettre à jour la liste des catégories et des dossiers.

---

## D2 — Surface de parcelle : **surface saisie = source de vérité, position en V2** (résout C3)

### Décision

La **surface saisie** par l'utilisateur (Value Object `Surface`) est la **source de vérité
unique** en V1. Les coordonnées de plan (`position_x/y/largeur/hauteur/rotation`) deviennent
**optionnelles (nullables)** et sont réservées à la future **vue « plan du potager » (V2)**.

On abandonne la règle « surface calculée depuis la position » du Domain pour la V1 : elle
contredisait à la fois le schéma SQL (qui stocke la surface) et l'UX d'onboarding (qui
demande la surface, jamais les dimensions). Aligne Domain + SQL + UX, et respecte « zéro friction ».

### Conséquences (à propager)

- **Doc 05 §3.2 / §3.3** : `Parcelle.surface` = champ saisi (plus « calculée depuis
  `PositionParcelle` »). `PositionParcelle` devient optionnelle ; `redimensionner`,
  `deplacer`, `pivoter` → marquées **V2**.
- **Doc 06 §3.2** : `position_x`, `position_y`, `position_largeur`, `position_hauteur`,
  `position_rotation` → **`NULL`** (V2). `surface_valeur` + `surface_unite` restent NOT NULL.
  `position_ordre` (ordre d'affichage de la liste) reste NOT NULL — indépendant du plan.
- **Doc 13** : la vue « plan du potager » (déjà en V2) consommera ces colonnes.

---

## D3 — i18n des fiches plantes : **texte inline dans le YAML** (résout M2)

### Décision

Les **traductions des fiches** (descriptions, conseils, raisons d'association, conditions
de conservation, usages culinaires) vivent **dans le YAML lui-même** (`i18n: {fr, en}`,
`*_i18n: {fr, en}`), et **non** dans des fichiers ARB.

Les fichiers **ARB** (`l10n/`) sont réservés au **texte d'interface** (chrome de l'UI).
Cohérent avec la philosophie « base de connaissances contributive et diffable » : un
contributeur édite **un seul fichier autosuffisant**.

### Conséquences (à propager)

- **Doc 05 §3.6** : corriger « Conseils/conservation stockés en **clés i18n** » →
  **textes localisés inline** ; `FichePlante` porte des `Map<String, String>` (locale → texte),
  construits par le mapper depuis le YAML.
- **Doc 12 §1** : confirmer explicitement la séparation « UI → ARB / fiches → i18n inline YAML ».
- Aucun changement au format YAML (déjà inline en doc 07) — c'est le doc 05 qui était l'intrus.

---

## Listes de valeurs — validées (2026-06-04)

Les **directions** D1/D2/D3 **et** les listes de valeurs de D1 sont actées :

1. **`CategoriePlante`** (7) : `legume, aromatique, fruit, petitFruit, fleur, cereale, engraisVert`.
   `petitFruit` distinct de `fruit` (arbres). `engraisVert` = catégorie pour les engrais verts
   purs (moutarde, phacélie) **et** `usage` pour le rôle secondaire des autres (trèfle…).
2. **`UsagePlante`** (13) : `alimentaire, condimentaire, medicinale, compagnonnage, repulsif,
   mellifere, pollinisateur, engraisVert, couvreSol, briseVent, tuteurVivant, ornementale, fourrage`.
3. **`SousTypeLegume`** (7) : `legumeFruit, legumeFeuille, legumeRacine, legumeBulbe, legumeTige,
   legumeFleur, legumeTubercule` (sans `legumineuse`, géré par `famille_botanique`).

---

## Liens

- Audit source : [AUDIT_PRE_DEV.md](AUDIT_PRE_DEV.md) (points C1, C3, M2)
- Décisions antérieures : [ADR-0001](0001-arbitrages-de-coherence.md) (A6 sur le format des fiches)
