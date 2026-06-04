# ADR-0001 — Arbitrages de cohérence lors du découpage documentaire

- **Statut** : Accepté
- **Date** : 2026-06-04
- **Contexte** : refactor du `CAHIER_DES_CHARGES.md` (9396 lignes, export ODT) et
  d'`ARCHITECTURE.md` en documents spécialisés (`docs/`). L'analyse a révélé des
  contradictions internes (le document a évolué dans le temps) et des doublons.

## Décision générale

En cas de contradiction, **la version la plus récente / la plus détaillée du
CAHIER fait foi**, et les sections périmées sont écartées. Les anciens fichiers
`CAHIER_DES_CHARGES.md` / `ARCHITECTURE.md` sont conservés **hors du repo** comme
sources historiques.

## Arbitrages

### A1 — Licence : **MIT**
Le CAHIER §1.2 fixe MIT. `CLAUDE.md`/`ARCHITECTURE.md` laissaient « à choisir ».
→ **MIT confirmé** (fichier `LICENSE`).

### A2 — Mode sombre : **inclus en V1**
§1.5 (ancienne DA) disait « mode sombre → V2 », mais §4.1 spécifie une palette
dark complète et §2 le liste en V1. → **Mode sombre en V1.**

### A3 — Direction artistique : **« Carnet vivant » (§4.1)**
La DA minimaliste de §1.5 (icônes outline, « aucun emoji ») est **superséd​ée**
par le design system complet §4.1 (Manrope/Inter, Phosphor, palettes, tokens).
La règle « pas d'emoji dans l'UI » de §1.5 est **conservée** (reprise en §4.2.3.8).

### A4 — Communauté P2P : **V2** (opt-in, désactivée par défaut)
Contradiction `ARCHITECTURE §7.1` (« implémentée en V1 ») vs CAHIER §1.11.2
(« V2 »). → **V2**, conformément à la philosophie opt-in strict et pour alléger
le scope V1. *(Décision validée avec le mainteneur.)*

### A5 — Calendrier lunaire : **V2** (opt-in)
§1.2 le listait en « optionnel V1 », §1.11/§7 en V2. → **V2.**

### A6 — Format des fiches YAML : **§3.5** (un fichier par plante)
Deux designs incompatibles coexistaient :
- §1.6 : IDs codés (`L0101-002`), fichiers `data/` + `i18n/<lang>/` séparés.
- §3.5 : `id` en `snake_case`, **un fichier par plante** avec `i18n` imbriqué,
  dossiers par catégorie.
→ **§3.5 retenu** : cohérent avec la table `fiches_plantes_personnelles`
(`id_fiche` logique, `categorie ∈ {legume, aromatique, fruit,
fleur_compagnonnage}`, `yaml_contenu` brut comme source de vérité). Le système
d'IDs codés et les registres `categories/families/species.yaml` sont abandonnés.

### A7 — Architecture : **4 couches**
`ARCHITECTURE.md` décrivait 3 couches (domain/data/presentation + services/core) ;
le CAHIER §3.4 décrit **4 couches** (Presentation → Application → Domain ←
Infrastructure). → **4 couches** retenues (cf. [04](../../../04-architecture-en-couches.md)).
`services` devient `infrastructure/services`, `data` devient `infrastructure`.

### A8 — Table `recoltes` définie deux fois
La source la déclare en « table 4/12 » (brouillon : `date`, sans `destination`)
et en « table 8 » (complète : `date_recolte`, `unite`, `qualite`, `destination`).
→ **Une seule table `recoltes`**, version complète (avec `destination`). Le
nombre réel de tables passe de « 13 » à **12**.

### A9 — `observations` : `ON DELETE RESTRICT` (au lieu de `CASCADE`)
La source utilisait `ON DELETE CASCADE` sur les FK d'`observations`, en
contradiction avec la stratégie soft delete + RESTRICT du reste du schéma.
→ **Aligné sur `RESTRICT`** + cascade logique côté Dart.

### A10 — Réglages : séparation `preferences` / `parametres`
Deux tables se recouvraient (`parametres` clé-valeur §3.3.11 ; `preferences`
singleton §3.3.13), toutes deux porteuses des opt-outs/thème/langue.
→ **`preferences`** = réglages **utilisateur** (langue, thème, unités, swipe,
niveau, opt-outs, notifications, NPD). **`parametres`** = **état applicatif
technique** uniquement (`app.*`, `sync.*`, `meteo.*`). Les clés `ui.*`,
`optout.*`, `notif.*`, `community.*` de §3.3.11.5 sont migrées vers `preferences`.

## Conséquences

- Les `docs/` reflètent ces arbitrages ; `CLAUDE.md` pointe vers `docs/` comme
  source de vérité.
- Points laissés **ouverts** (à trancher à l'implémentation, non bloquants) :
  export ICS du calendrier (« à confirmer » dans la source), nommage exact de
  certains enums (`TypeParcelle` : `pot`/`potEnPot`, `balcon` présent côté SQL
  mais absent de l'enum Domain — à harmoniser), valeurs précises des
  modificateurs `EffetEquipement` (calibrées à l'étape moteur de recommandations).
