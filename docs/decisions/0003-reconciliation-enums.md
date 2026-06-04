# ADR-0003 — Réconciliation des énumérations (parcelles, sol, climat, localisation)

- **Statut** : Accepté
- **Date** : 2026-06-04
- **Contexte** : l'[audit pré-dev](../AUDIT_PRE_DEV.md) a relevé de multiples divergences
  `enum Domain ↔ CHECK SQL ↔ vocabulaire YAML`. Cet ADR tranche la **priorité 2** :
  C2 (`TypeParcelle`), C6 (source de localisation), M1 (sol & besoin en eau), M3 (climat) —
  et **résout au passage M4** (rusticité non persistée) et **M5** (traçabilité du sol).
- **Convention** : identifiants Dart en `camelCase`, valeurs YAML/SQL en `snake_case`
  (ex. enum `petitFruit` ↔ `petit_fruit`). Le mapper assure la correspondance.

---

## D1 — `TypeParcelle` : structure physique uniquement (résout C2)

La parcelle ne décrit plus que sa **structure physique**. Les techniques de gestion, le
contexte d'emplacement et l'orientation verticale sont sortis vers d'autres axes (D2, D3).

```dart
enum TypeParcelle { pleineTerre, bacSureleve, jardiniere, pot, serre, butte, autre }
```

**Changements vs l'existant** :
- `potEnPot` → `pot` ; **ajout** `jardiniere` ; **ajout** `autre`.
- **Retirés** : `chassis` (→ équipement, cf. D4), `balcon` (→ emplacement, cf. D3),
  `butteLasagne`/`hugelkultur` (→ `TechniqueSol`, cf. D2). `butte` (structure) **conservé**.

---

## D2 — `TechniqueSol` : nouvel enum **multi-valué** orthogonal (résout C2)

Une parcelle porte **0..N techniques** de gestion du sol, indépendantes de sa structure
(un `bacSureleve` peut être en `butteLasagne` **+** `hugelkultur`). Patron identique aux
`usages` de [ADR-0002](0002-arbitrages-structurants-pre-dev.md).

```dart
/// Techniques de culture / gestion du sol (multi-valué, optionnel).
/// Décrit un ÉTAT DURABLE de la parcelle, lu par le moteur (arrosage, fertilité,
/// structure) — pas une action ponctuelle (celles-ci relèvent de Tache/Traitement).
enum TechniqueSol {
  // Structure de sol
  butteLasagne, hugelkultur, butteRonde, buttePermanente,
  // Couverture / paillage
  paillage, brf, mulchVivant, engraisVertCouvert, paillageMineral, carton,
  // Sans travail / minimal
  noDig, grelinette, mulchDeFoin,
  // Amendement / fertilité
  compostageSurface, compostEnTrou, mycorhization, bokashi,
  // Gestion de l'eau / structure paysagère
  swales, keylineDesign
}
```

**Arbitrages de périmètre** :
- `semisDirect` **écarté** de `TechniqueSol` : collision avec `MethodeMiseEnPlace.semisDirect`
  et redondant avec `noDig`.
- `thePurin` **écarté** : c'est une **intervention ponctuelle répétée**, pas un état durable
  → relève de `Tache` / entité `Traitement` (V1.1), pas d'un attribut de parcelle.
- `ollas`, `gouttesAGoutte` **restent en `Equipement`** (objets physiques).
- `rotation`, `associationCultures` **ne sont pas des techniques de sol** (planning de plantation).
- `agroforesterie` **hors périmètre** (échelle non domestique).

**UX** : `swales`, `keylineDesign` (échelle paysagère) **masqués au niveau « débutant »**
(principe de progressivité, doc 09 §1.4). Le programme reste simple par défaut, complet à la demande.

**Persistance** : colonne `parcelles.techniques_sol TEXT` = **tableau JSON** de valeurs
`snake_case` (même patron que `rappels.jours_semaine`), nullable.

---

## D3 — Emplacement (Potager) & culture verticale (Parcelle) (résout C2)

- **`balcon`** n'est pas un type de parcelle mais un **contexte d'emplacement** du potager :

```dart
enum TypeEmplacement { jardin, balcon, terrasse, toit, cour, interieur, autre }
```
→ nouvelle colonne `potagers.emplacement TEXT NOT NULL DEFAULT 'jardin'` + CHECK.

- **Culture verticale** = **booléen** sur la parcelle (mur végétal, palissage, tour à
  fraises) : impacte le calcul d'espace (surface au sol ≠ surface cultivée).
→ nouvelle colonne `parcelles.culture_verticale INTEGER NOT NULL DEFAULT 0` (0/1).

---

## D4 — `serre` : parcelle **et** équipement (résout C2)

- **`TypeParcelle.serre`** = **grande serre permanente** où l'on cultive (tomates, thermophiles).
- Côté **équipement** (table `equipements`), on lève l'ambiguïté du `serre` actuel :
  `serre` → **`tunnel`** (tunnel/chenille), **`serreSemis`** (mini-serre / propagation), et
  `chassis` **devient un équipement** (sort de `TypeParcelle`).

> ⚠️ **Suivi** : l'enum `TypeEquipement` a ses propres incohérences et sera **réconcilié à
> son propre tour** (pass dédiée). D4 ne fixe ici que la **règle de répartition** serre/châssis.

---

## D5 — Source de localisation : un seul vocabulaire (résout C6)

On distingue **l'origine de la donnée** (par potager) de **la préférence globale** (mode souhaité) :

```dart
/// Origine des coordonnées d'un potager donné.
enum SourceLocalisation { nonDefinie, manuelle, gps }
```
- `potagers.localisation_source` CHECK → `('nonDefinie','manuelle','gps')`
  (défaut **`nonDefinie`** ; corrige aussi P5 : plus de `'manuelle'` par défaut sans coordonnées).
- La **préférence globale** reste séparée : `preferences.mode_geolocalisation`
  (`desactivee / manuelle / gps`) — `desactivee` est un *mode*, pas une *origine de donnée*.
- **Bannis** : `automatique`, `geolocalisation` (→ `gps` partout).

---

## D6 — `BesoinEau` : niveau de besoin (résout M1a)

```dart
enum BesoinEau { faible, modere, eleve }
```
- Sémantiquement un **niveau de besoin** (pas un mélange fréquence/quantité comme
  l'ancien `regulier/abondant` du YAML).
- Cohérent avec les autres échelles du Domain (`GraviteObservation`…).
- YAML `besoins.arrosage` adopte `faible | modere | eleve`. Le libellé « parlant »
  (« arrosage régulier ») va dans le texte `i18n` de la fiche (affichage).

---

## D7 — Modèle de sol : trois axes distincts + dérivation (résout M1b, M5)

Le sol **possédé** (parcelle) et le sol **recherché** (fiche) sont **deux vocabulaires
différents** : un sol `argileux` est justement *mal drainé*. On ne fusionne pas.

```dart
/// Texture/nature du sol — attribut de la PARCELLE (ce que le jardinier possède).
enum TextureSol { argileux, sableux, limoneux, calcaire, humifere, tourbeux, caillouteux }

/// Qualités recherchées — besoin de la FICHE (ce que la plante préfère, multi-valué).
enum QualiteSol { riche, pauvre, bienDraine, malDraine, frais, sec, lourd, leger }

/// pH qualitatif (complète le pH numérique phMin/phMax des fiches).
enum PhSol { acide, neutre, alcalin }
```

**Dérivation (moteur de recommandation)** : table `TextureSol → {QualiteSol}` + `PhSol`,
p. ex. `argileux → {lourd, malDraine, frais}` ; `sableux → {leger, bienDraine, sec}` ;
`humifere → {riche, frais}`. Calibrée à l'étape moteur. Le pH qualitatif mappe le numérique
(`acide < 6.5 ≤ neutre ≤ 7.5 < alcalin`).

**Persistance** :
- `parcelles` : `type_sol` (ancien) → **`texture_sol`** (TextureSol, **nullable** = inconnu,
  création sans friction) + **`ph_sol`** (PhSol, nullable) + **`texture_sol_source`**
  (`SourceTypeSol`, **résout M5** : traçabilité de l'origine du sol).
- `fiches` (YAML) : `besoins.type_sol` → liste de `QualiteSol` ; `ph_min/ph_max` numériques **conservés**.

---

## D8 — Climat : `TypeClimat` + `ZoneRusticite` (résout M3, M4)

Köppen simplifié seul est **insuffisant** (un océanique breton, hivers doux, ≠ un océanique
belge, gelées fréquentes). On combine **deux dimensions** :

```dart
/// Classification climatique (Köppen simplifié).
enum TypeClimat {
  tropical, subtropical, aride, semiAride, mediterraneen,
  oceanique, continental, montagnard, polaire
}

/// Zone de rusticité (USDA) — tolérance au froid, par tranche de T° minimale.
enum ZoneRusticite {
  zone1,  // < -45 °C
  zone2,  // -45 à -40
  zone3,  // -40 à -34
  zone4,  // -34 à -29
  zone5,  // -29 à -23
  zone6,  // -23 à -18
  zone7,  // -18 à -12  (Bretagne, sud UK)
  zone8,  // -12 à -7   (Paris, ouest France)
  zone9,  // -7 à -1    (côte méditerranéenne)
  zone10, // -1 à 4     (sud Espagne, Floride)
  zone11, // 4 à 10
  zone12, // 10 à 16
  zone13  // > 16       (tropical)
}
```

**Indexation des périodes des fiches** (supprime la 4ᵉ taxonomie bricolée
`zone_temperee/zone_mediterraneenne`) :
- Les périodes sont rangées **par `TypeClimat`** (+ hémisphère). Le contributeur ne remplit
  que les climats qu'il connaît.
- La **`ZoneRusticite`** sert d'**affinage moteur** : décalage de quelques semaines + barrière
  anti-gel (date de dernier gel déduite de la rusticité → pas de recommandation de plantation
  d'une thermophile avant cette date).

```yaml
periodes:
  hemisphere_nord:
    oceanique:     { semis_interieur: [2,4], plantation: [5,6], recolte: [7,10] }
    continental:   { ... }
    mediterraneen: { ... }
  hemisphere_sud:
    ...
```

**Persistance** :
- `potagers.climat_type` CHECK → **les 9 `TypeClimat`** (corrige M3 : `climat_type` n'avait
  **aucun** CHECK).
- `potagers` : **nouvelle colonne `zone_rusticite`** (CHECK `zone1..zone13`) → **résout M4**
  (la rusticité, portée par le VO `ZoneClimatique`, devient persistable).

---

## Conséquences — propagation à faire (passe de correction des specs)

| Cible | Modifications |
|---|---|
| **Doc 05** | Remplacer/ajouter les enums : `TypeParcelle`, `TechniqueSol`, `TypeEmplacement`, `SourceLocalisation`, `BesoinEau`, `TextureSol`, `QualiteSol`, `PhSol`, `TypeClimat`, `ZoneRusticite`. `Parcelle` : `+techniquesSol`, `+cultureVerticale`, `texture/ph/source` ; `Potager` : `+emplacement`, `ZoneClimatique` porte la rusticité. |
| **Doc 06** | `parcelles` : CHECK `type` (7), `+techniques_sol` (JSON), `+culture_verticale`, `type_sol`→`texture_sol`+`ph_sol`+`texture_sol_source`. `potagers` : CHECK `localisation_source` (3), `+emplacement`, CHECK `climat_type` (9), `+zone_rusticite`. |
| **Doc 07 + `_schema/`** | `besoins.arrosage` (BesoinEau), `besoins.type_sol` (liste QualiteSol), `periodes` indexées par `TypeClimat`+hémisphère. |
| **Doc 11** | `mode_geolocalisation` aligné (`desactivee/manuelle/gps`). |
| **Suivi séparé** | Réconciliation `TypeEquipement` (tunnel/serreSemis/chassis, retrait du `serre` dupliqué, ollas) ; entité `Traitement` accueillera `thePurin` (V1.1). |

---

## Liens

- Audit source : [AUDIT_PRE_DEV.md](../AUDIT_PRE_DEV.md) (C2, C6, M1, M3, M4, M5, P5)
- Décision liée : [ADR-0002](0002-arbitrages-structurants-pre-dev.md) (patron catégorie + multi-valué)
