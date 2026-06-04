# ADR-0004 — Entités du Domain & périmètre (récolte, préférences, observations, sync)

- **Statut** : Accepté
- **Date** : 2026-06-04
- **Contexte** : suite de l'[audit pré-dev](../AUDIT_PRE_DEV.md). Cet ADR tranche la
  **priorité 3** : entités du Domain incomplètes/contradictoires (C4, C5) et points de
  périmètre (M6 observations, M9 sync des fiches perso), plus deux corrections mécaniques
  (M7, M8) et l'unification des unités (P2).
- **Convention** : identifiants Dart `camelCase`, valeurs YAML/SQL `snake_case`.

---

## D1 — `Recolte` : alignement Domain ↔ SQL (résout C4)

- **`qualite`** : **nullable des deux côtés** — `QualiteRecolte?` (Domain) / `qualite TEXT NULL`
  **sans défaut** (SQL). `null` = *qualité non encore évaluée* (la qualité est ajoutable a
  posteriori, doc 05 §3.5) — plus honnête que forcer `'bonne'`.
- **`destination`** : **ajoutée à l'entité Domain** (elle manquait) — `DestinationRecolte`,
  `NOT NULL DEFAULT consommationFraiche` (le SQL faisait foi, cf. ADR-0001 A8).

L'entité `Recolte` complète :

```dart
class Recolte {
  final String _id, _plantationId;
  final DateTime _date;
  final Quantite _quantite;
  final DestinationRecolte _destination;   // ajouté (NOT NULL)
  final QualiteRecolte? _qualite;           // nullable
  final String? _notes;
  // …getters…
}
```

## D2 — Unités : un seul enum (résout P2)

`Quantite` (VO) utilisait `UniteQuantite` tandis que la table `recoltes` stockait des valeurs
`UniteRecolte` (deux enums redondants : `kilogrammes`/`kg`). → **Fusion en un seul** :

```dart
enum UniteQuantite { g, kg, piece, botte, litre, ml }
```
- `UniteRecolte` **supprimé**. `recoltes.unite` CHECK → `('g','kg','piece','botte','litre','ml')`.
- `Quantite` ne convertit qu'entre unités de **même nature** (masse↔masse, volume↔volume),
  sinon exception métier (inchangé).

---

## D3 — `PreferencesUtilisateur.id` : String partout (résout C5)

Aligner le SQL sur le Domain **et** sur la convention « tous les IDs sont des `String` » :

- SQL : `id TEXT PRIMARY KEY CHECK (id = 'singleton')` (au lieu de `INTEGER CHECK (id = 1)`).
- Domain : `id == "singleton"` (inchangé).
- Seed : `INSERT INTO preferences (id) VALUES ('singleton');`

---

## D4 — `sync.enabled` : une seule source de vérité (résout M7)

L'interrupteur de synchronisation vit **uniquement** dans `preferences.sync_locale_active`
(réglage utilisateur, ADR-0001 A10). → **Retrait de `sync.enabled`** du registre
`parametres.*` (doc 11 §8). `parametres.sync.*` ne conserve que le **technique** :
`sync.port`, `sync.device_name`, `sync.last_sync_at`.

---

## D5 — Défaut du niveau d'expérience : `debutant` (résout M8)

Cible « novice complet » (doc 01 §5) + principe de progressivité → **`debutant`** partout.
→ Corriger le **parcours 1** (doc 10), qui indiquait « défaut : Intermédiaire ».
`preferences.niveau_experience DEFAULT 'debutant'` est déjà correct.

---

## D6 — Observations : une seule entité `Observation` en V1 (résout M6)

Deux concepts se chevauchaient : l'entité `NoteObservation` (V1.1, rattachée à `Plantation`,
photos) et la table `observations` (V1, journal de bord polymorphe). On **unifie** :

- **Une seule entité `Observation` (V1)**, à **cible polymorphe** (potager / parcelle /
  plantation), portant `type` (`TypeObservation`), `gravite` (`GraviteObservation`),
  `resolu`, `titre`, `description` → mappe directement la table `observations` existante.
- **Le nom `NoteObservation` est abandonné** (c'était le même concept).
- **Photos reportées en V1.1** (cohérent avec le report photos pour alléger sync & stockage).
- **`Observation` n'est PAS embarquée dans l'agrégat `Plantation`** : on **retire
  `Plantation._notes` / `ajouterNote(...)`**. Les observations se récupèrent **par requête**
  (`AbstractObservationRepository.obtenirParCible(...)`) → agrégat `Plantation` léger,
  chargement maîtrisé (perf + Clean Architecture).

**Impacts** :
- Doc 05 : remplacer `NoteObservation` (V1.1) par `Observation` (V1) ; retirer la composition
  `Plantation (1) ──▶ (N) NoteObservation` du diagramme ; retirer `_notes` de `Plantation`.
- Ajouter l'interface `AbstractObservationRepository` (§6).
- La table `observations` (doc 06 §3.8) reste telle quelle (déjà conforme).

---

## D7 — Les fiches perso se synchronisent (résout M9)

Une fiche perso est une **donnée utilisateur** au même titre qu'un potager : elle doit
**suivre les appareils** de l'utilisateur. La soumission **GitHub PR** est un canal
*orthogonal* (partage **public**), pas le mécanisme multi-appareils personnel.

- **`fiches_plantes_personnelles` devient synchronisable** : ajout de
  `created_at`, `updated_at`, `deleted_at`, `sync_version`.
- Elle **sort** de la liste des tables non-synchronisées (qui reste `meteo_cache`,
  `parametres`, `preferences`).
- Source de vérité = `yaml_contenu` brut (inchangé) ; la ligne entière est synchronisée.

---

## Conséquences — propagation à faire (passe de correction des specs)

| Cible | Modifications |
|---|---|
| **Doc 05** | `Recolte` : `+destination`, `qualite` nullable. `UniteQuantite` fusionné, `UniteRecolte` supprimé. `NoteObservation` → `Observation` (V1) ; retrait `Plantation._notes` ; `+AbstractObservationRepository`. |
| **Doc 06** | `recoltes.qualite` → `NULL` sans défaut ; `recoltes.unite` CHECK (6 valeurs). `preferences.id` → `TEXT CHECK ('singleton')` + seed. `fiches_plantes_personnelles` : `+created_at/updated_at/deleted_at/sync_version` ; retrait de la liste non-synchronisée. |
| **Doc 10** | Parcours 1 : défaut niveau d'expérience → **Débutant**. |
| **Doc 11** | Registre `parametres.*` : retirer `sync.enabled`. |
| **Roadmap (13)** | Photos d'observations confirmées en V1.1 (cohérent). |

---

## Liens

- Audit source : [AUDIT_PRE_DEV.md](../AUDIT_PRE_DEV.md) (C4, C5, M6, M7, M8, M9, P2)
- Décisions liées : [ADR-0001](0001-arbitrages-de-coherence.md) (A8 récolte, A10 préférences/paramètres)
