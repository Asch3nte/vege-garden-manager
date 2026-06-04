# Audit de cohérence pré-développement — Pot'à Gérer

> ## ✅ CLÔTURÉ — propagation effectuée le 2026-06-04
> Les **28 points** (6 critiques, 9 majeurs, 13 mineurs) ont été **tranchés puis propagés**
> dans les specs. Décisions : [ADR-0002](decisions/0002-arbitrages-structurants-pre-dev.md),
> [ADR-0003](decisions/0003-reconciliation-enums.md),
> [ADR-0004](decisions/0004-entites-domain-et-perimetre.md) — ce sont elles qui **font foi**.
> Les dossiers `assets/fiches_plantes/` ont été réorganisés et la fiche golden
> `legumes/tomate.yaml` créée. Ce document est conservé comme **trace de l'audit** ; il peut
> être archivé. *(Suivis reportés : réconciliation fine de `TypeEquipement`, entité `Traitement` V1.1.)*

> **Statut** : Brouillon de travail · **Date** : 2026-06-04
> **Portée** : audit de la **spécification** (le repo est à l'état documentation +
> ossature, aucun code Dart). L'objet est la **cohérence interne** de la spec, qui
> deviendra contraignante dès la première entité du Domain.
> **Méthode** : lecture croisée des 13 docs `docs/` + [ADR-0001](decisions/0001-arbitrages-de-coherence.md)
> + [schéma YAML](../assets/fiches_plantes/_schema/fiche_plante_schema.yaml) + méta-fichiers,
> en confrontant les **3 sources de vérité** qui doivent rester alignées :
> `enums Domain` (doc 05) ↔ `CHECK SQL` (doc 06) ↔ `vocabulaire YAML` (doc 07 / schema).
>
> Chaque point porte un **ID** (`C*` critique, `M*` majeur, `P*` mineur/pratique) servant
> de référence pour les corrections et un futur **ADR-0002**. Les cases `[ ]` suivent
> l'avancement.

## Sommaire

- [Points forts à préserver](#points-forts-à-préserver)
- [🔴 Incohérences critiques (C1–C6)](#-incohérences-critiques)
- [🟠 Incohérences majeures (M1–M9)](#-incohérences-majeures)
- [🟡 Incohérences mineures & pratiques (P1–P13)](#-incohérences-mineures--pratiques)
- [💡 Suggestions d'amélioration](#-suggestions-damélioration)
- [🎯 Plan d'action priorisé](#-plan-daction-priorisé)

---

## Points forts à préserver

- Architecture en couches claire, règle de dépendance bien posée, DI Riverpod cohérente.
- Stratégie **soft delete + RESTRICT + cascade logique** bien pensée et justifiée pour la sync.
- ADR-0001 résout déjà 10 contradictions réelles — la démarche est saine.
- Séparation `preferences` (utilisateur) / `parametres` (technique) nette.
- Cible polymorphe `taches`/`rappels` avec `CHECK exactement-une-cible` : élégant et correct.
- Conventions de confidentialité (arrondi ~1 km, opt-out systématique) appliquées jusqu'au schéma.

> ⚠️ La doc 05 §5 affirme : « chaque enum persistée a une contrainte `CHECK`
> correspondante en BDD ». **Cette règle est déjà violée** sur plusieurs enums
> (voir C2, C6, M1, M3) — c'est le fil rouge de l'audit.

---

## 🔴 Incohérences critiques

> À trancher **avant** d'écrire le Domain. Bloquent la génération cohérente des
> entités, mappers et tables.

### [~] C1 — Trois taxonomies de catégories de plantes incompatibles

> ✅ **Tranché** par [ADR-0002 / D1](decisions/0002-arbitrages-structurants-pre-dev.md) :
> catégorie large exclusive + `usages` multi-valués + `sous_type` légume optionnel.
> Propagation dans les specs encore à faire.

| Source | Valeurs |
|---|---|
| Enum Domain `CategoriePlante` (05 §5) | `legumeFruit, legumeFeuille, legumeRacine, legumeBulbe, legumineuse, aromatique, fleur, fruitier` (**8**) |
| YAML `categorie` + CHECK SQL `fiches_plantes_personnelles` | `legume, aromatique, fruit, fleur_compagnonnage` (**4**) |
| Périmètre doc 07 §2 | Légumes, **Aromatiques, Médicinales, Vivaces comestibles, Grains & céréales, Engrais verts** (**6 groupes**) |

Le `FichePlanteMapper` ne sait pas mapper `legume` (YAML) vers l'une des 4 sous-catégories
légume du Domain. Les ~200 fiches couvrent 6 familles thématiques (médicinales, vivaces,
céréales, engrais verts) **sans bucket** dans les 4 catégories.
**Décision requise** : une seule taxonomie, couvrant le périmètre réel.

### [~] C2 — `TypeParcelle` : Domain et SQL divergent de 5 valeurs

> ✅ **Tranché** par [ADR-0003 / D1–D4](decisions/0003-reconciliation-enums.md) :
> `TypeParcelle` = structure seule ; nouvel enum multi `TechniqueSol` ; `balcon`→emplacement
> Potager ; `cultureVerticale` booléen ; `serre`/`chassis` répartis parcelle/équipement.
> Propagation dans les specs encore à faire.

| Domain (05 §5) | SQL CHECK `parcelles` (06 §3.2) |
|---|---|
| `pleineTerre, bacSureleve, potEnPot, serre, butte, butteLasagne, hugelkultur` | `pleineTerre, bacSureleve, pot, serre, chassis, balcon, autre` |

Seuls 3/7 coïncident. L'ADR-0001 ne mentionne que `pot`/`potEnPot` et `balcon` comme
points ouverts, mais **5 valeurs divergent** (`butte/butteLasagne/hugelkultur` absents
du SQL ; `chassis/balcon/autre` absents du Domain). À réconcilier complètement.

### [~] C3 — `Parcelle.surface` : trois vérités contradictoires

> ✅ **Tranché** par [ADR-0002 / D2](decisions/0002-arbitrages-structurants-pre-dev.md) :
> surface saisie = source de vérité (V1) ; `position_*` nullable (vue plan V2).
> Propagation dans les specs encore à faire.

- **Domain (05 §3.2)** : surface **calculée** depuis `PositionParcelle` (largeur×hauteur)
  = « source de vérité unique », donc non stockée.
- **SQL (06 §3.2)** : `surface_valeur` + `surface_unite` **stockés** (NOT NULL, CHECK > 0),
  **et** `position_largeur`/`position_hauteur` stockés (NOT NULL) → dénormalisation, désync possible.
- **UX (parcours 2, doc 10)** : on demande **la surface directement** (« nom + surface +
  exposition »), jamais les dimensions/position.

Conséquence : `position_*` sont NOT NULL mais **jamais renseignés à l'onboarding** ; la
surface saisie peut contredire largeur×hauteur.
**Recommandation** : surface saisie en V1, `position_*` **nullable** (vue « plan » = V2).

### [~] C4 — `Recolte` : Domain et SQL se contredisent

> ✅ **Tranché** par [ADR-0004 / D1–D2](decisions/0004-entites-domain-et-perimetre.md) :
> `qualite` nullable, `destination` ajoutée au Domain, `UniteQuantite` fusionné
> (P2 résolu). Propagation à faire.

- `qualite` : Domain (05 §3.5) = **`QualiteRecolte?` nullable** ; SQL = **`NOT NULL DEFAULT 'bonne'`**.
- `destination` : **absent** de l'entité Domain (05 §3.5) mais **`NOT NULL`** en SQL
  (conservé par ADR-A8).

L'entité `Recolte` du doc 05 est incomplète/contradictoire vs la table.

### [~] C5 — `PreferencesUtilisateur.id` : String vs Integer

> ✅ **Tranché** par [ADR-0004 / D3](decisions/0004-entites-domain-et-perimetre.md) :
> SQL `id TEXT CHECK (id = 'singleton')`, aligné sur la convention String. Propagation à faire.

- Domain (05 §3.7) : `id == "singleton"` (String).
- SQL (06 §3.12) : `id INTEGER PRIMARY KEY CHECK (id = 1)`.

Type et valeur incompatibles. Trancher la valeur singleton et l'aligner.

### [~] C6 — Vocabulaire « source de localisation » : trois orthographes

> ✅ **Tranché** par [ADR-0003 / D5](decisions/0003-reconciliation-enums.md) :
> `SourceLocalisation { nonDefinie, manuelle, gps }` (origine donnée) + préférence globale
> séparée (`desactivee/manuelle/gps`). Propagation à faire.

| Source | Valeurs |
|---|---|
| Enum Domain `SourceLocalisation` (05 §4.3) | `desactivee, manuelle, gps` |
| CHECK `potagers.localisation_source` (06 §3.1) | `manuelle, geolocalisation, nonDefinie` |
| CHECK `preferences.mode_geolocalisation` (06 §3.12) | `desactivee, manuelle, automatique` |

Même concept, 3 vocabulaires (`gps`/`geolocalisation`/`automatique`,
`desactivee`/`nonDefinie`). À unifier.

---

## 🟠 Incohérences majeures

### [~] M1 — `BesoinsCulture` ↔ YAML : vocabulaires structurés divergents

> ✅ **Tranché** par [ADR-0003 / D6–D7](decisions/0003-reconciliation-enums.md) :
> `BesoinEau { faible, modere, eleve }` ; modèle de sol à 3 enums distincts
> (`TextureSol` parcelle / `QualiteSol` fiche / `PhSol`) + table de dérivation moteur.
> Propagation à faire.

- `BesoinEau` Domain = `{faible, moyen, eleve}` ; YAML `arrosage` = `{faible, regulier, abondant}`.
- `solPrefere` Domain = **un** `TypeSol` (`argileux…`) ; YAML `type_sol` = **liste** de
  qualités (`[riche, bien_draine]`) → vocabulaire **et** cardinalité différents.
- `TypeSol` Domain inclut `equilibre`, **absent** du CHECK SQL `parcelles.type_sol`.

Le moteur de recommandations ne peut pas croiser besoins YAML et `TypeSol` des parcelles
sans table de correspondance (inexistante).

### [~] M2 — `FichePlante` (Domain) ↔ structure YAML : modèles structurellement différents

> ✅ **i18n tranché** par [ADR-0002 / D3](decisions/0002-arbitrages-structurants-pre-dev.md) :
> texte localisé **inline** dans le YAML ; ARB réservé à l'UI. Restent à traiter en passe
> de correction : structure plate vs imbriquée (hémisphère/zone), `espaceRequisParPied`
> vs `espacement_cm`, `dureeAvantRecolte` scalaire vs intervalle.

| Domain (05 §3.6) | YAML (07) |
|---|---|
| `periodesSemis/Plantation/Recolte: List<Periode>` (plat) | `periodes.{hemisphere}.{zone}.{semis_interieur/exterieur/plantation/recolte}` (imbriqué) |
| `espaceRequisParPied: Surface` (aire m²) | `espacement_cm` (distance linéaire) |
| `dureeAvantRecolte` (scalaire) | `duree_avant_recolte_jours: [min, max]` (intervalle) |
| `conseils/conservation` = **clés i18n** (ARB) | texte **inline** `conditions_i18n: {fr, en}` |

Point conceptuel majeur : **doc 05 dit « clés i18n »**, **docs 07 + 12 disent texte inline
dans le YAML**. C'est l'un ou l'autre. La structure plate du Domain perd la dimension
hémisphère/zone pourtant nécessaire à `estPlantableEn(date, zone)`.
**Recommandation** : i18n **inline** (cohérent avec la philosophie « diffable sur GitHub »).

### [~] M3 — `enum TypeClimat` non défini + pas de CHECK SQL

> ✅ **Tranché** par [ADR-0003 / D8](decisions/0003-reconciliation-enums.md) :
> `TypeClimat` (9 valeurs) + `ZoneRusticite` (zone1–13) ; fiches indexées par
> `TypeClimat`+hémisphère ; CHECK `climat_type` ajouté. Propagation à faire.

- Domain : `enum TypeClimat { /* … commentaire … */ }` — **jamais défini**.
- SQL `potagers.climat_type` : `NOT NULL` mais **aucun CHECK**.

Premier contre-exemple direct de « chaque enum persistée a un CHECK ».

### [~] M4 — `ZoneClimatique` : rusticité USDA non persistée

> ✅ **Résolu** par [ADR-0003 / D8](decisions/0003-reconciliation-enums.md) :
> `ZoneRusticite` devient un enum (zone1–13) + colonne `potagers.zone_rusticite`.
> Propagation à faire.

Le VO (05 §4.6) porte une **zone de rusticité 1–11 (USDA)** + `supporteGel`, mais
`potagers` n'a **aucune colonne** de rusticité (seulement `climat_type`, temp moy,
pluviométrie). Donnée du Domain non stockable.

### [~] M5 — `parcelles` : colonne `type_sol_source` manquante

> ✅ **Résolu** par [ADR-0003 / D7](decisions/0003-reconciliation-enums.md) :
> colonne `texture_sol_source` (`SourceTypeSol`) ajoutée avec le nouveau modèle de sol.
> Propagation à faire.

Domain (05 §3.2) : `Parcelle` porte `typeSol` **+ `typeSolSource`** (`enum SourceTypeSol`).
Le SQL `parcelles` a `type_sol` mais **pas** `type_sol_source`. La traçabilité de
l'origine du sol (atout UX annoncé) est perdue en base.

### [~] M6 — Double modèle d'observations (V1 vs V1.1) conflictuel

> ✅ **Tranché** par [ADR-0004 / D6](decisions/0004-entites-domain-et-perimetre.md) :
> une seule entité `Observation` (V1, polymorphe), photos en V1.1, retrait de
> `Plantation._notes` (accès par repository). Propagation à faire.

- Entité `NoteObservation` marquée **V1.1** (05 §3.7), rattachée à `Plantation`, avec photos.
- **Mais** `Plantation` (05 §3.4, code V1) contient déjà `List<NoteObservation> _notes` et
  `ajouterNote(...)` → référence une entité V1.1 depuis du code V1.
- **Et** la table `observations` (V1, table 8) a un modèle **différent** (cible polymorphe
  potager/parcelle/plantation, `gravite`, `resolu`, `titre`) qui ne mappe pas sur `NoteObservation`.

Deux concepts (« note par plantation » et « journal de bord polymorphe ») conflés, l'un
V1 l'autre V1.1. Clarifier le périmètre V1 exact.

### [~] M7 — `sync.enabled` dupliqué entre `parametres` et `preferences`

> ✅ **Tranché** par [ADR-0004 / D4](decisions/0004-entites-domain-et-perimetre.md) :
> retrait de `sync.enabled` ; l'interrupteur vit dans `preferences.sync_locale_active`.
> Propagation à faire.

ADR-A10 statue : opt-out sync = réglage **utilisateur** → `preferences.sync_locale_active`.
Mais le registre `parametres.*` (doc 11 §8) liste encore `sync.enabled (bool, false)`.
État stocké à **deux endroits** = source de bug.

### [~] M8 — Niveau d'expérience : défaut contradictoire

> ✅ **Tranché** par [ADR-0004 / D5](decisions/0004-entites-domain-et-perimetre.md) :
> défaut `debutant` partout (corriger le parcours 1). Propagation à faire.

- Onboarding (parcours 1, doc 10) : **défaut Intermédiaire**.
- `preferences` SQL + doc 11 §2 : **défaut `debutant`**.
- Cible produit (01 §5) : « novice complet ».

Le défaut devrait être `debutant` (cible novice) ; corriger le parcours 1.

### [~] M9 — Tables « non synchronisées » : liste incohérente

> ✅ **Tranché** par [ADR-0004 / D7](decisions/0004-entites-domain-et-perimetre.md) :
> les fiches perso **se synchronisent** (ajout colonnes de sync) ; sortent de la liste
> non-synchronisée. Propagation à faire.

La liste (06 §1) cite 3 tables non synchronisées (`meteo_cache, parametres, preferences`).
Mais `fiches_plantes_personnelles` **n'a aucune colonne de sync** non plus → de facto non
synchronisée, alors qu'un contenu créé par l'utilisateur **devrait** se synchroniser.
Trancher : l'ajouter à la liste explicite, ou lui ajouter les colonnes de sync.

---

## 🟡 Incohérences mineures & pratiques

- [x] **P1 — `lib/app/` fantôme** → ✅ Propagé : `lib/app/` créé dans l'ossature + ajouté à `lib/README`.
- [x] **P2 — `UniteQuantite` vs `UniteRecolte`** → ✅ [ADR-0004 D2](decisions/0004-entites-domain-et-perimetre.md) : enum `UniteQuantite` unique, propagé (docs 05/06).
- [x] **P3 — ~200 vs « ~150 fichiers »** → ✅ Harmonisé à « ~200 » (doc 07 §6).
- [x] **P4 — Packages « à arbitrer »** → ✅ `phosphor_flutter`, `flutter_markdown`, `freezed` validés (doc 03 §4).
- [x] **P5 — `localisation_source DEFAULT 'manuelle'`** → ✅ [ADR-0003 D5](decisions/0003-reconciliation-enums.md) : défaut `nonDefinie` + CHECK de cohérence (doc 06).
- [x] **P6 — Récurrence `mensuel`** → ✅ Colonne `jour_du_mois` ajoutée à `rappels` + CHECK (doc 06).
- [x] **P7 — `pubspec.lock` ignoré** → ✅ Dé-ignoré dans `.gitignore` (sera versionné).
- [x] **P8 — `langue` autorise `'en'`** → ✅ CHECK conservé (`auto/fr/en`), `en` masqué dans l'UI V1 (docs 06/12).
- [x] **P9 — Types de service non définis** → ✅ `DonneesMeteo/PrevisionMeteo/NotificationLocale/AppareilDecouvert` définis (doc 05 §7).
- [x] **P10 — `date_creation` + `created_at`** → ✅ Conservés et documentés (date métier vs date technique de sync).
- [x] **P11 — Surface aplatie incohérente** → ✅ `plantations.surface_occupee_valeur`+`_unite` (convention homogène, doc 06).
- [x] **P12 — `equipements` « date de retrait »** → ✅ Colonne `date_retrait` ajoutée (doc 06).
- [x] **P13 — CHECK de plage manquants** → ✅ `position_rotation` ∈ [0,360[ + cohérence source/coords (doc 06).

---

## 💡 Suggestions d'amélioration

1. **Matrice unique « enum ↔ SQL ↔ YAML »** (tableau versionné) comme contrat de référence
   dont découlent tous les mappers. Aurait évité C1, C2, C6, M1.
2. **Générer les `CHECK` SQL depuis les enums Dart** (script utilitaire Dart, déjà dans la
   stack) pour qu'enum et CHECK ne divergent jamais. Élimine structurellement toute la classe C/M.
3. **Validateur YAML en CI** (le « FichePlanteValidator » prévu), dès maintenant, adossé à
   `_schema/` : unicité des `id`, intégrité référentielle (associations/rotation), `ph_min ≤ ph_max`,
   mois ∈ [1,12].
4. **ADR-0002** tranchant C1–C6 + M2/M6. L'ADR-0001 a sous-estimé C2 ; matérialiser les arbitrages.
5. **Au moins une fiche réelle complète** (`legumes/tomate.yaml`) conforme au schéma, comme
   golden file de test du pipeline et modèle pour contributeurs (CONTRIBUTING y renvoie déjà,
   mais le fichier n'existe pas).
6. **Décider la stratégie i18n des fiches** (M2) : inline YAML (recommandé) vs clés ARB.
7. **Clarifier position vs surface des parcelles** (C3) : surface saisie en V1, `position_*`
   nullable réservées à la vue « plan » V2.
8. **Définir les VO météo/sync manquants** (P9) pour rendre les interfaces de services implémentables.
9. **Tests de cohérence enum↔CHECK** (verrouille la suggestion 2), en plus de la cible 80 % `domain/`.
10. **Commit du `pubspec.lock`** et versions figées dès `flutter create` (tient mieux la contrainte n°6).

---

## 🎯 Plan d'action priorisé

| Priorité | Action | Points couverts | Nature |
|---|---|---|---|
| 1 | ADR-0002 : trancher catégories, surface/position, i18n fiches | C1, C3, M2 | Décision |
| 2 | Réconcilier tous les enums dans une matrice unique | C2, C6, M1, M3 | Doc |
| 3 | Corriger entités Domain incomplètes | C4, C5, M4, M5 | Doc |
| 4 | Lever l'ambiguïté observations V1/V1.1 et sync `fiches_perso` | M6, M9 | Décision |
| 5 | Corrections mineures rapides | P1, P3, P5, P7, M7, M8 | Doc |
| 6 | **Puis seulement** : `flutter create` + premiers VO/entités + tests | — | Code |

> ⚠️ **Recommandation principale** : ne pas démarrer le code du Domain (prochaine action
> prévue par `CLAUDE.md`) avant d'avoir tranché au moins **C1–C6** et **M2/M6**. Coder
> maintenant figerait dans le code des choix contradictoires que les mappers SQL/YAML
> rendraient douloureux à défaire.
