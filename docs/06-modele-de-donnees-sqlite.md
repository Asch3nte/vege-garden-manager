# 06 — Modèle de données SQLite (drift)

> Source : CAHIER §3.3. Schéma de la base locale, implémenté via **drift**.
> Le SQL ci-dessous est la **référence logique** ; l'implémentation réelle se
> fait en classes `Table` drift (génération de code).

## 1. Conventions transverses

| Convention | Règle |
|---------------|-----------------------------------------------------------------------------------------------------------------------------|
| Clé primaire | `id TEXT` = **UUID v4** généré côté app (sauf `parametres` = clé texte, `preferences` = singleton `id='singleton'`) |
| Value Objects | **aplatis** en colonnes (ex. `Surface` → `surface_valeur` + `surface_unite`) |
| Dates | **TEXT ISO 8601 UTC** |
| Booléens | `INTEGER` 0/1 |
| Enums | `TEXT` + contrainte **`CHECK`** exhaustive (défense en profondeur) |
| Soft delete | colonne `deleted_at` ; **jamais** de suppression physique automatique |
| Sync | colonnes `created_at`, `updated_at`, `deleted_at`, `sync_version` sur les tables **synchronisables** |
| Cascades | gérées **côté Dart** (cascade logique du soft delete), **pas** par `ON DELETE CASCADE` SQL → FK en **`ON DELETE RESTRICT`** |

> **Règle d'or** : avec le soft delete, les cascades SQL sont inutiles voire
> dangereuses (un appareil distant ne verrait pas les enfants supprimés). On
> propage les suppressions en cascade **logiquement** côté repository.

### Tables NON synchronisées (locales à l'appareil)
`meteo_cache`, `parametres`, `preferences` — pas de colonnes de sync.

> ⚠️ `fiches_plantes_personnelles` **est synchronisée** (donnée utilisateur)
> et porte donc les colonnes de sync.

## 2. Liste des tables (12)

| # | Table | Rôle |
|-----|-------------------------------|-----------------------------------------------|
| 1 | `potagers` | Racine : zones de jardinage |
| 2 | `parcelles` | Zones de culture homogènes |
| 3 | `plantations` | Mises en culture (cœur métier) |
| 4 | `recoltes` | Événements de récolte |
| 5 | `equipements` | Installations (oya, voile, tuteur…) |
| 6 | `taches` | Actions (occurrences unitaires) |
| 7 | `rappels` | Règles de planification (récurrentes) |
| 8 | `observations` | Journal de bord (maladies, ravageurs…) |
| 9 | `meteo_cache` | Cache Open-Meteo (local) |
| 10 | `parametres` | État applicatif technique (clé-valeur, local) |
| 11 | `fiches_plantes_personnelles` | Fiches créées par l'utilisateur |
| 12 | `preferences` | Préférences utilisateur (singleton, local) |

## 3. Schémas

### 3.1 `potagers`

```sql
CREATE TABLE potagers (
  id TEXT PRIMARY KEY NOT NULL,
  nom TEXT NOT NULL,
  emplacement TEXT NOT NULL DEFAULT 'jardin', -- enum TypeEmplacement
  -- Value Object Localisation (aplati)
  localisation_latitude REAL NULL,
  localisation_longitude REAL NULL,
  localisation_ville TEXT NULL,
  localisation_source TEXT NOT NULL DEFAULT 'nonDefinie', -- nonDefinie | manuelle | gps
  -- Value Object ZoneClimatique (aplati) — type + rusticité
  climat_type TEXT NOT NULL, -- enum TypeClimat (9 valeurs)
  zone_rusticite TEXT NULL, -- enum ZoneRusticite (zone1..zone13)
  climat_temp_moy_annuelle REAL NULL,
  climat_pluviometrie_annuelle REAL NULL,
  climat_source TEXT NOT NULL DEFAULT 'manuelle', -- manuelle | deduitDeLocalisation | openMeteo
  date_creation TEXT NOT NULL,
  notes TEXT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT NULL,
  sync_version INTEGER NOT NULL DEFAULT 1,
  CHECK (localisation_latitude IS NULL OR (localisation_latitude BETWEEN -90 AND 90)),
  CHECK (localisation_longitude IS NULL OR (localisation_longitude BETWEEN -180 AND 180)),
  CHECK (emplacement IN ('jardin','balcon','terrasse','toit','cour','interieur','autre')),
  CHECK (localisation_source IN ('nonDefinie','manuelle','gps')),
  -- cohérence opt-out : source 'nonDefinie' ⟺ pas de coordonnées
  CHECK ((localisation_source = 'nonDefinie') = (localisation_latitude IS NULL AND localisation_longitude IS NULL)),
  CHECK (climat_type IN ('tropical','subtropical','aride','semiAride','mediterraneen',
                         'oceanique','continental','montagnard','polaire')),
  CHECK (zone_rusticite IS NULL OR zone_rusticite IN ('zone1','zone2','zone3','zone4','zone5',
         'zone6','zone7','zone8','zone9','zone10','zone11','zone12','zone13')),
  CHECK (climat_source IN ('manuelle','deduitDeLocalisation','openMeteo'))
);
CREATE INDEX idx_potagers_deleted_at ON potagers(deleted_at);
CREATE INDEX idx_potagers_updated_at ON potagers(updated_at);
```

Lat/lon **nullables** (opt-out géoloc respecté). Colonnes `*_source` pour
tracer l'origine de la donnée (UX, re-calcul, opt-out).

### 3.2 `parcelles`

```sql
CREATE TABLE parcelles (
  id TEXT PRIMARY KEY NOT NULL,
  nom TEXT NOT NULL,
  potager_id TEXT NOT NULL,
  type TEXT NOT NULL, -- enum TypeParcelle (structure seule)
  surface_valeur REAL NOT NULL, -- VO Surface (aplati) — SAISIE
  surface_unite TEXT NOT NULL, -- m2 | cm2
  exposition TEXT NOT NULL, -- pleinSoleil | miOmbre | ombre
  -- Sol : texture possédée + pH + traçabilité
  texture_sol TEXT NULL, -- enum TextureSol (NULL = inconnue, sans friction)
  ph_sol TEXT NULL, -- enum PhSol (acide | neutre | alcalin)
  texture_sol_source TEXT NOT NULL DEFAULT 'manuelle', -- enum SourceTypeSol
  techniques_sol TEXT NULL, -- JSON : ["noDig","paillage",…] (enum TechniqueSol, multi)
  culture_verticale INTEGER NOT NULL DEFAULT 0, -- 0/1
  position_ordre INTEGER NOT NULL, -- ordre d'affichage (indépendant du plan)
  -- Coordonnées du « plan du potager » — OPTIONNELLES, vue V2
  position_x REAL NULL, position_y REAL NULL, -- coin haut-gauche (m)
  position_largeur REAL NULL, position_hauteur REAL NULL,
  position_rotation REAL NULL,
  date_creation TEXT NOT NULL,
  notes TEXT NULL,
  created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
  deleted_at TEXT NULL, sync_version INTEGER NOT NULL DEFAULT 1,
  FOREIGN KEY (potager_id) REFERENCES potagers(id) ON DELETE RESTRICT,
  CHECK (surface_valeur > 0),
  CHECK (surface_unite IN ('m2','cm2')),
  CHECK (exposition IN ('pleinSoleil','miOmbre','ombre')),
  CHECK (type IN ('pleineTerre','bacSureleve','jardiniere','pot','serre','butte','autre')),
  CHECK (texture_sol IS NULL OR texture_sol IN ('argileux','sableux','limoneux','calcaire','humifere','tourbeux','caillouteux')),
  CHECK (ph_sol IS NULL OR ph_sol IN ('acide','neutre','alcalin')),
  CHECK (texture_sol_source IN ('manuelle','deduitDeLocalisation','deduitDuClimat')),
  CHECK (culture_verticale IN (0,1)),
  CHECK (position_x IS NULL OR position_x >= 0),
  CHECK (position_y IS NULL OR position_y >= 0),
  CHECK (position_rotation IS NULL OR position_rotation >= 0 AND position_rotation < 360) -- P13
);
CREATE INDEX idx_parcelles_potager_id ON parcelles(potager_id);
CREATE INDEX idx_parcelles_deleted_at ON parcelles(deleted_at);
CREATE INDEX idx_parcelles_updated_at ON parcelles(updated_at);
CREATE INDEX idx_parcelles_potager_ordre ON parcelles(potager_id, position_ordre);
``` 

`texture_sol` nullable (= inconnue, création sans friction). `techniques_sol` en
**tableau JSON** (multi-valué, orthogonal au `type`). `position_*` nullables :
réservées à la future vue « plan du potager » (V2).

### 3.3 `plantations` (cœur métier)

```sql
CREATE TABLE plantations (
  id TEXT PRIMARY KEY NOT NULL,
  parcelle_id TEXT NOT NULL,
  plante_id TEXT NOT NULL, -- réf. FichePlante YAML (pas de FK SQL)
  date_mise_en_place TEXT NOT NULL,
  methode TEXT NOT NULL,
  surface_occupee_valeur REAL NOT NULL, -- VO Surface aplati (convention homogène, P11)
  surface_occupee_unite TEXT NOT NULL DEFAULT 'm2', -- m2 | cm2
  nombre_pieds INTEGER NOT NULL,
  statut TEXT NOT NULL DEFAULT 'enCours',
  date_fin_reelle TEXT NULL,
  raison_fin TEXT NULL,
  notes_libres TEXT NULL,
  created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
  deleted_at TEXT NULL, sync_version INTEGER NOT NULL DEFAULT 1,
  FOREIGN KEY (parcelle_id) REFERENCES parcelles(id) ON DELETE RESTRICT,
  CHECK (nombre_pieds > 0),
  CHECK (surface_occupee_valeur > 0),
  CHECK (surface_occupee_unite IN ('m2','cm2')),
  CHECK (methode IN ('semisDirect','semisInterieur','repiquage','plantAchete','bouture','division')),
  CHECK (statut IN ('enCours','recoltee','echouee','arrachee')),
  CHECK ((statut = 'enCours' AND date_fin_reelle IS NULL)
      OR (statut IN ('recoltee','echouee','arrachee') AND date_fin_reelle IS NOT NULL)),
  CHECK (date_fin_reelle IS NULL OR date_fin_reelle >= date_mise_en_place)
);
CREATE INDEX idx_plantations_parcelle_id ON plantations(parcelle_id);
CREATE INDEX idx_plantations_plante_id ON plantations(plante_id);
CREATE INDEX idx_plantations_statut ON plantations(statut);
CREATE INDEX idx_plantations_deleted_at ON plantations(deleted_at);
CREATE INDEX idx_plantations_updated_at ON plantations(updated_at);
CREATE INDEX idx_plantations_dates ON plantations(date_mise_en_place, date_fin_reelle);
CREATE INDEX idx_plantations_actives ON plantations(parcelle_id, statut)
  WHERE deleted_at IS NULL AND statut = 'enCours';
```

**Pas de FK SQL sur `plante_id`** : les `FichePlante` vivent dans le catalogue
YAML, pas en base. Validation applicative (sinon `FichePlanteIntrouvableException`).
`ON DELETE RESTRICT` sur `parcelle_id` protège l'historique de rotation.

### 3.4 `recoltes`

```sql
CREATE TABLE recoltes (
  id TEXT PRIMARY KEY NOT NULL,
  plantation_id TEXT NOT NULL,
  date_recolte TEXT NOT NULL,
  quantite REAL NOT NULL,
  unite TEXT NOT NULL, -- enum UniteQuantite (unifié)
  qualite TEXT NULL, -- enum QualiteRecolte (NULL = non évaluée)
  destination TEXT NOT NULL DEFAULT 'consommationFraiche', -- enum DestinationRecolte
  date_creation TEXT NOT NULL,
  notes TEXT NULL,
  created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
  deleted_at TEXT NULL, sync_version INTEGER NOT NULL DEFAULT 1,
  FOREIGN KEY (plantation_id) REFERENCES plantations(id) ON DELETE RESTRICT,
  CHECK (unite IN ('g','kg','piece','botte','litre','ml')),
  CHECK (qualite IS NULL OR qualite IN ('excellente','bonne','moyenne','mediocre')),
  CHECK (destination IN ('consommationFraiche','conservation','don','semences','compost','autre')),
  CHECK (quantite > 0),
  CHECK (date_recolte <= date_creation) -- pas de récolte future
);
CREATE INDEX idx_recoltes_plantation_id ON recoltes(plantation_id);
CREATE INDEX idx_recoltes_date_recolte ON recoltes(date_recolte);
CREATE INDEX idx_recoltes_destination ON recoltes(destination);
CREATE INDEX idx_recoltes_plantation_date ON recoltes(plantation_id, date_recolte);
```

Une récolte = un événement daté unique. `destination = compost` trace les
pertes sans biaiser les totaux consommables. Pas de prix, pas de photo en V1.

### 3.5 `equipements`

```sql
CREATE TABLE equipements (
  id TEXT PRIMARY KEY NOT NULL,
  nom TEXT NOT NULL,
  potager_id TEXT NOT NULL, -- toujours obligatoire
  parcelle_id TEXT NULL, -- NULL = équipement transverse
  type TEXT NOT NULL, -- enum TypeEquipement
  etat TEXT NOT NULL DEFAULT 'bon', -- enum EtatEquipement
  marque_modele TEXT NULL,
  date_installation TEXT NOT NULL,
  date_remplacement_prevue TEXT NULL,
  date_retrait TEXT NULL, -- retrait effectif (équipement conservé pour historique, P12)
  date_creation TEXT NOT NULL,
  notes TEXT NULL,
  created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
  deleted_at TEXT NULL, sync_version INTEGER NOT NULL DEFAULT 1,
  FOREIGN KEY (potager_id) REFERENCES potagers(id) ON DELETE RESTRICT,
  FOREIGN KEY (parcelle_id) REFERENCES parcelles(id) ON DELETE RESTRICT,
  -- enum TypeEquipement (réconciliation fonctionnelle fine en passe dédiée)
  CHECK (type IN ('oya','gouttesAGoutte','tuteur','treillis','tunnel','serreSemis','chassis',
                  'cloche','voileHivernage','filetAntiInsecte','hotelInsectes',
                  'composteur','recuperateurEau','autre')),
  CHECK (etat IN ('neuf','bon','use','aRemplacer','horsService'))
);
CREATE INDEX idx_equipements_potager_id ON equipements(potager_id);
CREATE INDEX idx_equipements_parcelle_id ON equipements(parcelle_id);
CREATE INDEX idx_equipements_type ON equipements(type);
CREATE INDEX idx_equipements_etat ON equipements(etat);
```

Double rattachement : `potager_id` obligatoire + `parcelle_id` optionnel
(équipement transverse = composteur, récupérateur d'eau…).

### 3.6 `taches` & 3.7 `rappels` — cible polymorphe

Les deux partagent le **même motif de cible** : 4 colonnes nullables
(`potager_id`, `parcelle_id`, `plantation_id`, `equipement_id`) + un `CHECK`
garantissant qu'**exactement une** est renseignée (FK natives + intégrité SQL).

```sql
CREATE TABLE taches (
  id TEXT PRIMARY KEY NOT NULL,
  titre TEXT NOT NULL,
  description TEXT NULL,
  type TEXT NOT NULL, -- enum TypeTache
  etat TEXT NOT NULL DEFAULT 'aFaire', -- enum EtatTache
  priorite TEXT NOT NULL DEFAULT 'normale', -- enum PrioriteTache
  potager_id TEXT NULL, parcelle_id TEXT NULL,
  plantation_id TEXT NULL, equipement_id TEXT NULL, 
  date_prevue TEXT NOT NULL,
  date_realisation TEXT NULL,
  duree_reelle_minutes INTEGER NULL,
  rappel_origine_id TEXT NULL, -- FK logique vers rappels (cf. note)
  date_creation TEXT NOT NULL,
  notes TEXT NULL,
  created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
  deleted_at TEXT NULL, sync_version INTEGER NOT NULL DEFAULT 1,
  FOREIGN KEY (potager_id) REFERENCES potagers(id) ON DELETE RESTRICT,
  FOREIGN KEY (parcelle_id) REFERENCES parcelles(id) ON DELETE RESTRICT,
  FOREIGN KEY (plantation_id) REFERENCES plantations(id) ON DELETE RESTRICT,
  FOREIGN KEY (equipement_id) REFERENCES equipements(id) ON DELETE RESTRICT,
  CHECK ((CASE WHEN potager_id IS NOT NULL THEN 1 ELSE 0 END
        + CASE WHEN parcelle_id IS NOT NULL THEN 1 ELSE 0 END
        + CASE WHEN plantation_id IS NOT NULL THEN 1 ELSE 0 END
        + CASE WHEN equipement_id IS NOT NULL THEN 1 ELSE 0 END) = 1),
  CHECK (etat IN ('aFaire','enCours','terminee','annulee')),
  CHECK (priorite IN ('basse','normale','haute','urgente')),
  CHECK (duree_reelle_minutes IS NULL OR duree_reelle_minutes > 0),
  CHECK ((etat = 'terminee' AND date_realisation IS NOT NULL) OR (etat != 'terminee'))
  -- + CHECK type IN (… 16 valeurs de TypeTache …)
);
CREATE INDEX idx_taches_etat_date_prevue ON taches(etat, date_prevue); -- requête la plus fréquente
-- (+ index sur etat, date_prevue, type, chaque cible, rappel_origine_id, deleted_at, updated_at)
```

`rappels` reprend la même cible polymorphe, plus la **planification** :

```sql
CREATE TABLE rappels (
  id TEXT PRIMARY KEY NOT NULL,
  titre TEXT NOT NULL, description TEXT NULL,
  type_tache_generee TEXT NOT NULL, -- enum TypeTache
  priorite TEXT NOT NULL DEFAULT 'normale',
  potager_id TEXT NULL, parcelle_id TEXT NULL,
  plantation_id TEXT NULL, equipement_id TEXT NULL,
  date_debut TEXT NOT NULL,
  date_fin TEXT NULL, -- NULL = indéfini
  type_recurrence TEXT NOT NULL, -- enum TypeRecurrence
  intervalle_jours INTEGER NULL, -- requis si 'personnalise'
  jours_semaine TEXT NULL, -- JSON, requis si 'hebdomadaire'
  jour_du_mois INTEGER NULL, -- 1–31, requis si 'mensuel'
  etat TEXT NOT NULL DEFAULT 'actif', -- enum EtatRappel
  generer_x_jours_avance INTEGER NOT NULL DEFAULT 7, -- horizon de génération des tâches
  date_creation TEXT NOT NULL, notes TEXT NULL,
  created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
  deleted_at TEXT NULL, sync_version INTEGER NOT NULL DEFAULT 1,
  FOREIGN KEY (potager_id) REFERENCES potagers(id) ON DELETE RESTRICT,
  FOREIGN KEY (parcelle_id) REFERENCES parcelles(id) ON DELETE RESTRICT,
  FOREIGN KEY (plantation_id) REFERENCES plantations(id) ON DELETE RESTRICT,
  FOREIGN KEY (equipement_id) REFERENCES equipements(id) ON DELETE RESTRICT,
  CHECK ((CASE WHEN potager_id IS NOT NULL THEN 1 ELSE 0 END
        + CASE WHEN parcelle_id IS NOT NULL THEN 1 ELSE 0 END
        + CASE WHEN plantation_id IS NOT NULL THEN 1 ELSE 0 END
        + CASE WHEN equipement_id IS NOT NULL THEN 1 ELSE 0 END) = 1),
  CHECK (type_recurrence IN ('ponctuel','quotidien','hebdomadaire','personnalise','mensuel')),
  CHECK (etat IN ('actif','enPause','termine')),
  CHECK ((type_recurrence = 'personnalise' AND intervalle_jours IS NOT NULL AND intervalle_jours > 0)
      OR (type_recurrence = 'hebdomadaire' AND jours_semaine IS NOT NULL AND jours_semaine != '[]')
      OR (type_recurrence = 'mensuel' AND jour_du_mois IS NOT NULL AND jour_du_mois BETWEEN 1 AND 31)
      OR (type_recurrence IN ('ponctuel','quotidien'))),
  CHECK (date_fin IS NULL OR date_fin >= date_debut),
  CHECK (generer_x_jours_avance BETWEEN 0 AND 365)
);
CREATE INDEX idx_rappels_etat_date_debut ON rappels(etat, date_debut);
```

- `jours_semaine` stocké en **JSON** (`["lundi","mercredi"]`), parsé côté Dart.
- `generer_x_jours_avance` : un job de maintenance (au lancement) génère les
  `Tache` concrètes sur cet horizon glissant → pas d'explosion du nombre de tâches.
- `taches.rappel_origine_id` : FK **différée** (matérialisée côté code / migration,
  car la table `rappels` est créée après `taches`).

### 3.8 `observations`

```sql
CREATE TABLE observations (
  id TEXT PRIMARY KEY NOT NULL,
  date_observation TEXT NOT NULL,
  type TEXT NOT NULL, -- enum TypeObservation
  gravite TEXT NOT NULL DEFAULT 'info', -- enum GraviteObservation
  titre TEXT NOT NULL, description TEXT NULL,
  potager_id TEXT NULL, parcelle_id TEXT NULL, plantation_id TEXT NULL, -- cible (1 parmi 3)
  resolu INTEGER NOT NULL DEFAULT 0,
  date_resolution TEXT NULL,
  actions_realisees TEXT NULL,
  date_creation TEXT NOT NULL, notes TEXT NULL,
  created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
  deleted_at TEXT NULL, sync_version INTEGER NOT NULL DEFAULT 1,
  FOREIGN KEY (potager_id) REFERENCES potagers(id) ON DELETE RESTRICT, -- ⚠ aligné sur RESTRICT
  FOREIGN KEY (parcelle_id) REFERENCES parcelles(id) ON DELETE RESTRICT,
  FOREIGN KEY (plantation_id) REFERENCES plantations(id) ON DELETE RESTRICT,
  CHECK (type IN ('maladie','ravageur','carence','meteo','croissance','floraison','fructification','general','autre')),
  CHECK (gravite IN ('info','faible','modere','eleve','critique')),
  CHECK (resolu IN (0,1)),
  CHECK ((CASE WHEN potager_id IS NOT NULL THEN 1 ELSE 0 END
        + CASE WHEN parcelle_id IS NOT NULL THEN 1 ELSE 0 END
        + CASE WHEN plantation_id IS NOT NULL THEN 1 ELSE 0 END) = 1),
  CHECK ((resolu = 0 AND date_resolution IS NULL) OR (resolu = 1 AND date_resolution IS NOT NULL)),
  CHECK (date_observation <= date_creation)
);
```

> La source utilisait `ON DELETE CASCADE` ici ; on aligne
> sur `RESTRICT` + cascade logique, comme le reste du schéma.

### 3.9 `meteo_cache` (local, non synchronisé)

```sql
CREATE TABLE meteo_cache (
  id TEXT PRIMARY KEY NOT NULL,
  latitude REAL NOT NULL, longitude REAL NOT NULL,
  date TEXT NOT NULL, -- YYYY-MM-DD
  type TEXT NOT NULL, -- 'observe' | 'prevu'
  temp_min REAL NULL, temp_max REAL NULL, temp_moyenne REAL NULL,
  precipitations_mm REAL NULL, heures_ensoleillement INTEGER NULL,
  vent_vitesse_max REAL NULL, vent_direction INTEGER NULL,
  risque_gel INTEGER NOT NULL DEFAULT 0, -- pré-calculé : temp_min <= 0
  risque_canicule INTEGER NOT NULL DEFAULT 0, -- pré-calculé : temp_max >= 35
  date_recuperation TEXT NOT NULL,
  source_api TEXT NOT NULL DEFAULT 'open-meteo',
  CHECK (type IN ('observe','prevu')),
  CHECK (risque_gel IN (0,1)), CHECK (risque_canicule IN (0,1)),
  CHECK (latitude BETWEEN -90 AND 90), CHECK (longitude BETWEEN -180 AND 180),
  CHECK (vent_direction IS NULL OR vent_direction BETWEEN 0 AND 360),
  CHECK (precipitations_mm IS NULL OR precipitations_mm >= 0),
  CHECK (heures_ensoleillement IS NULL OR heures_ensoleillement BETWEEN 0 AND 24),
  UNIQUE (latitude, longitude, date, type)
);
```

Pas de colonnes de sync (chaque appareil interroge Open-Meteo lui-même). MAJ
des prévisions via `INSERT OR REPLACE`. **Purge côté code** : garder les
`observe`, supprimer les `prevu` passés > 7 j. Pas de FK vers `potagers`
(liaison logique au runtime par coordonnées).

### 3.10 `parametres` (état technique, clé-valeur, local)

```sql
CREATE TABLE parametres (
  cle TEXT PRIMARY KEY NOT NULL,
  valeur TEXT NOT NULL, -- toujours TEXT, parsé selon `type`
  type TEXT NOT NULL CHECK (type IN ('booleen','entier','decimal','texte','json')),
  description TEXT,
  date_creation TEXT NOT NULL,
  date_modification TEXT NOT NULL
);
```

Clés en **namespace hiérarchique** : `app.*` (first_launch, db_version),
`sync.*` (port, device_name, last_sync_at), `meteo.*` (coords manuelles,
refresh_hours)…

> Pour éviter le doublon avec `preferences`, **`parametres`
> est réservé à l'état applicatif technique** (versions, état machine, config
> sync/météo non-utilisateur). Les **réglages utilisateur** (thème, langue,
> unités, opt-outs, notifications) vivent dans `preferences`.

### 3.11 `fiches_plantes_personnelles`

```sql
CREATE TABLE fiches_plantes_personnelles (
  id TEXT PRIMARY KEY NOT NULL, -- UUID, préfixé "perso_" en mémoire
  id_fiche TEXT NOT NULL UNIQUE, -- id logique (= champ `id:` du YAML)
  yaml_contenu TEXT NOT NULL, -- SOURCE DE VÉRITÉ (export 1:1)
  schema_version INTEGER NOT NULL,
  categorie TEXT NOT NULL
    CHECK (categorie IN ('legume','aromatique','fruit','petit_fruit','fleur','cereale','engrais_vert')),
  sous_type TEXT NULL, -- enum SousTypeLegume (si categorie='legume')
  usages TEXT NOT NULL DEFAULT '[]', -- JSON dénormalisé (enum UsagePlante) pour la recherche
  nom_commun_fr TEXT, nom_commun_en TEXT, -- ≥ 1 non NULL (contrainte applicative)
  famille_botanique TEXT,
  -- (+ autres champs dénormalisés pour recherche)
  date_creation TEXT NOT NULL,
  -- Colonnes de sync (les fiches perso se synchronisent)
  created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
  deleted_at TEXT NULL, sync_version INTEGER NOT NULL DEFAULT 1
);
```

Source de vérité = **YAML brut** (export GitHub 1:1, mêmes parsers que les
fiches embarquées). En cas de collision d'`id_fiche` avec une fiche embarquée,
**priorité à la fiche perso** (géré au repository). Cf.
[07-base-de-connaissances-yaml.md](07-base-de-connaissances-yaml.md).

### 3.12 `preferences` (singleton, local)

```sql
CREATE TABLE preferences (
  id TEXT PRIMARY KEY CHECK (id = 'singleton'), -- singleton (String)
  langue TEXT NOT NULL DEFAULT 'auto' CHECK (langue IN ('auto','fr','en')), -- 'en' masqué dans l'UI V1
  theme TEXT NOT NULL DEFAULT 'auto' CHECK (theme IN ('auto','clair','sombre')),
  systeme_unites TEXT NOT NULL DEFAULT 'metrique' CHECK (systeme_unites IN ('metrique','imperial')),
  sens_swipe TEXT NOT NULL DEFAULT 'standard' CHECK (sens_swipe IN ('standard','inverse')),
  niveau_experience TEXT NOT NULL DEFAULT 'debutant'
    CHECK (niveau_experience IN ('debutant','intermediaire','expert')),
  mode_geolocalisation TEXT NOT NULL DEFAULT 'desactivee'
    CHECK (mode_geolocalisation IN ('desactivee','manuelle','gps')),
  notifications_globales_actives INTEGER NOT NULL DEFAULT 1 CHECK (notifications_globales_actives IN (0,1)),
  sync_locale_active INTEGER NOT NULL DEFAULT 0 CHECK (sync_locale_active IN (0,1)),
  communaute_opt_in INTEGER NOT NULL DEFAULT 0 CHECK (communaute_opt_in IN (0,1)), -- V2
  calendrier_lunaire_opt_in INTEGER NOT NULL DEFAULT 0 CHECK (calendrier_lunaire_opt_in IN (0,1)),
  notifications_par_categorie TEXT NOT NULL DEFAULT '{}', -- JSON
  ne_pas_deranger_debut TEXT, ne_pas_deranger_fin TEXT, -- 'HH:MM' ou NULL (les deux ou aucun)
  schema_version INTEGER NOT NULL DEFAULT 1,
  derniere_modification TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK ((ne_pas_deranger_debut IS NULL AND ne_pas_deranger_fin IS NULL)
      OR (ne_pas_deranger_debut IS NOT NULL AND ne_pas_deranger_fin IS NOT NULL))
);
INSERT INTO preferences (id) VALUES ('singleton'); -- init au premier lancement
```

Reflète l'entité `PreferencesUtilisateur` (cf. [05](05-modele-de-domaine.md)).
Défauts intelligents (principe UX n°2). Influence logique sur toute l'app
(géoloc, notifications, unités, langue, thème, swipe…), gérée en couche
Application. Détail des opt-outs : [11-parametres-et-opt-outs.md](11-parametres-et-opt-outs.md).

## 4. Hiérarchie d'agrégation

```
Potager ──▶ Parcelle ──▶ Plantation ──▶ Recolte
                  └──▶ Equipement
   Observation : cible polymorphe (potager | parcelle | plantation), non embarquée
   (référence externe : FichePlante depuis le catalogue YAML, jamais en SQL)
```

## 5. Migrations

Gérées par **drift** (versionnées). Chaque évolution de schéma incrémente la
version drift ; `parametres.app.db_version` et `preferences.schema_version`
tracent l'état applicatif.
