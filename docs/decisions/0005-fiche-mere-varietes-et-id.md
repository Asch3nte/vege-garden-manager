# ADR-0005 — Hiérarchie espèce/variété et format des IDs de fiches plantes

- **Statut** : Accepté
- **Date** : 2026-06-10
- **Contexte** : deux problèmes liés ont émergé lors de la phase de constitution
  de la base de connaissances.

  1. **Pas de distinction espèce / variété** : `tomate.yaml` et
     `tomate_coeur_de_boeuf.yaml` coexistent sans relation formelle. Le
     catalogue mélange des niveaux taxonomiques différents, ce qui complique
     la vue liste et la vue réseau neuronal (fiche et nœud de niveau
     hétérogène).

  2. **IDs dépendants du français** : l'[ADR-0001 §A6](archive/PRE_DEV/0001-arbitrages-de-coherence.md)
     avait choisi le format `snake_case` (ex. `aubergine_violette_de_florence`)
     pour sa lisibilité. Mais les noms de variétés sont par construction des
     noms communs dans une langue donnée. Un ID comme
     `tomate_coeur_de_boeuf` est opaque pour un locuteur anglais ou espagnol.
     Pour une base de connaissances multilingue et contributive, les IDs
     doivent être stables **indépendamment de la langue**.

  Ce présent ADR supersède partiellement l'ADR-0001 §A6 sur le seul point
  du **format des IDs** ; le reste (un fichier par plante, `i18n` inline,
  dossiers par catégorie) est conservé.

---

## Décision 1 — Hiérarchie : fiche mère (espèce) + fiche fille (variété)

### Principe

On distingue deux niveaux de fiche :

| Niveau | Objet | Exemple |
|---|---|---|
| **Fiche mère** (espèce ou sous-espèce cultivée) | Données agronomiques générales | Tomate (`LEG-001`) |
| **Fiche fille** (variété / cultivar) | Données de la variété — surcharge légère sur la mère | Tomate Cœur de Bœuf (`LEG-001-V001`) |

Une **fiche fille** ne répète pas les données de la mère : elle ne déclare que
les champs qui diffèrent (périodes légèrement différentes, température préférée
propre à la variété, conservation spécifique, etc.).  
Le **mapper** fusionne mère + fille à la lecture (la fille surcharge la mère).

### Format YAML d'une fiche fille

```yaml
# Fiche fille — hérite de sa fiche mère
id: LEG-001-V001
parent_id: LEG-001             # (requis sur une fiche fille) — référence la fiche mère
version_fiche: 1
schema_version: 1

# Seuls les champs qui diffèrent de la mère sont renseignés.
# Les champs absents sont hérités automatiquement.

i18n:
  fr:
    nom_commun: Tomate Cœur de Bœuf
    noms_alternatifs: [Cœur de Bœuf, Oxheart]
    description: >
      Variété ancienne à très gros fruits charnus en forme de cœur.
      Chair dense, peu juteuse, peu de graines — idéale pour les salades.
    conseils_culture: >
      Nécessite un tuteurage solide (fruits très lourds).
  en:
    nom_commun: Oxheart Tomato

# Surcharges agronomiques (optionnel — si la variété s'écarte de la mère)
besoins:
  temperature_optimale: 24    # légèrement plus élevée que la mère (22)

conservation:
  - methode: frais
    duree_jours: 5            # moins conservable (chair tendre)
    conditions_i18n: { fr: "Température ambiante, à consommer rapidement", en: "Room temperature, consume quickly" }

sources:
  - https://fr.wikipedia.org/wiki/Tomate_cœur_de_bœuf
contributeurs:
  - "@potagerer"
```

### Format YAML d'une fiche mère (complétée)

La fiche mère ajoute un champ `varietes_connues` informatif (non obligatoire,
dérivé du catalogue au chargement) :

```yaml
id: LEG-001
# ... champs habituels ...
varietes_connues: [LEG-001-V001, LEG-001-V002]   # liste des fiches filles connues
```

### Comportement du moteur

| Contexte | Comportement |
|---|---|
| Recommandation de plantes | Le moteur évalue toujours au niveau **espèce** (fiche mère). |
| Plantation d'une variété spécifique | `Plantation.planteId` référence la **fiche fille** ; le moteur résout la mère via `parent_id` pour l'agronomie. |
| Vue Catalogue — liste | Affiche uniquement les **fiches mères** par défaut ; expandable pour voir les variétés. |
| Vue Catalogue — réseau | Nœuds = **fiches mères** uniquement. Les variétés n'apparaissent pas comme nœuds. |
| Associations croisées | Les associations (`beneficies`, `defavorables`) sont toujours déclarées sur la **mère**, jamais sur la fille. |

### Champs non surchargeables par la fille

Les champs suivants sont fixés par la mère et ne peuvent pas être surchargés :

- `categorie`, `sous_type`
- `famille_botanique`, `nom_scientifique`
- `usages`
- `rotation` (famille, délai, précédents)
- `associations` (beneficies, defavorables)

---

## Décision 2 — Format des IDs (supersède ADR-0001 §A6 sur ce seul point)

### Problème

Les IDs `snake_case` sont lisibles en français mais opaques dans d'autres
langues. `aubergine_violette_de_florence` n'a pas de sens pour un contributeur
anglophone. Ils sont en pratique des **noms vernaculaires français** encodés
comme identifiants techniques, ce qui viole l'invariant d'un ID stable et
language-agnostic.

### Format retenu : `[CAT3]-[NUM3]` pour les espèces, `[CAT3]-[NUM3]-V[NUM3]` pour les variétés

```
LEG-001          → Tomate (espèce)
LEG-001-V001     → Tomate Cœur de Bœuf (variété)
LEG-001-V002     → Tomate Cerise

LEG-002          → Carotte
LEG-002-V001     → Carotte Nantaise Améliorée

ARO-001          → Basilic
FLE-001          → Souci
```

#### Codes de catégorie (3 lettres, invariants)

| Code | `CategoriePlante` |
|---|---|
| `LEG` | `legume` |
| `ARO` | `aromatique` |
| `FRU` | `fruit` (arbre fruitier) |
| `PFR` | `petit_fruit` |
| `FLE` | `fleur` |
| `CER` | `cereale` |
| `ENG` | `engrais_vert` |

#### Règles de numérotation

- Les numéros sont **séquentiels** par catégorie, attribués à l'ajout de la fiche.
- Le **registre des IDs** est le fichier
  `assets/fiches_plantes/_schema/id_registry.yaml` — liste plate
  `id → nom_commun_fr` (une ligne par fiche). Maintenu à la main par les
  contributeurs.
- Un numéro attribué est **immuable** : si une fiche est supprimée, son numéro
  n'est pas réattribué.
- Les variétés sont numérotées **dans l'espace de leur espèce** (V001, V002…).

#### Registre (format)

```yaml
# assets/fiches_plantes/_schema/id_registry.yaml
# Registre des IDs — une ligne par fiche, ordre numérique par catégorie.
# Ne PAS réattribuer un numéro supprimé.

legumes:
  LEG-001: Tomate
  LEG-001-V001: Tomate Cœur de Bœuf
  LEG-001-V002: Tomate Cerise
  LEG-002: Carotte
  LEG-002-V001: Carotte Nantaise Améliorée
  # ...

aromatiques:
  ARO-001: Basilic
  # ...
```

### Plan de migration des IDs existants

Les ~30 fiches existantes utilisent des IDs `snake_case`. La migration se fait
**en une seule passe** avant d'enrichir le catalogue davantage.

#### Tableau de migration (fiches actuelles)

| Ancien ID | Nouveau ID | Niveau |
|---|---|---|
| `tomate` | `LEG-001` | mère |
| `tomate_coeur_de_boeuf` | `LEG-001-V001` | fille |
| `aubergine_violette_de_florence` | `LEG-002-V001`* | fille |
| `betterave_chioggia` | `LEG-003-V001`* | fille |
| `carotte` | `LEG-004` | mère |
| `carotte_nantaise_amelioree` | `LEG-004-V001` | fille |
| `celeri_rave_brilliant` | `LEG-005-V001`* | fille |
| `chou_brocoli_calabrese` | `LEG-006-V001`* | fille |
| `chou_cabus_rouge` | `LEG-007-V001`* | fille |
| `chou_fleur_de_bretagne` | `LEG-008-V001`* | fille |
| `concombre_marketmore` | `LEG-009-V001`* | fille |
| `courge_butternut_ponca` | `LEG-010-V001`* | fille |
| `courgette_black_beauty` | `LEG-011-V001`* | fille |
| `epinard_geant_dhiver` | `LEG-012-V001`* | fille |
| `haricot_vert_fin_de_bagnols` | `LEG-013-V001`* | fille |
| `laitue` | `LEG-014` | mère |
| `laitue_batavia_rouge_grenobloise` | `LEG-014-V001` | fille |
| `navet_boule_dor` | `LEG-015-V001`* | fille |
| `oignon_rouge_de_florence` | `LEG-016-V001`* | fille |
| `poireau_bleu_de_solaise` | `LEG-017-V001`* | fille |
| `pois_mangetout_carouby` | `LEG-018-V001`* | fille |
| `poivron_corno_di_toro` | `LEG-019-V001`* | fille |
| `pomme_de_terre_charlotte` | `LEG-020-V001`* | fille |
| `potimarron_rouge_vif_etampes` | `LEG-021-V001`* | fille |
| `radis_cherry_belle` | `LEG-022-V001`* | fille |
| `artichaut_vert_de_laon` | `LEG-023-V001`* | fille |
| `basilic` | `ARO-001` | mère |

> `*` = la fiche est aujourd'hui une variété sans fiche mère générique.
> **Action** : créer la fiche mère correspondante (espèce) avant ou en même
> temps que la migration. La fiche mère porte les données agronomiques
> communes ; la fiche fille ne garde que les spécificités de la variété.

#### Étapes de la migration

1. Créer le fichier `id_registry.yaml` avec la table ci-dessus complétée.
2. Renommer les fichiers YAML (`tomate.yaml` → `LEG-001.yaml`, etc.).
3. Mettre à jour les champs `id:` dans chaque fichier.
4. Créer les fiches mères manquantes (`LEG-002.yaml` aubergine, etc.).
5. Convertir les anciennes fiches variétés : ajouter `parent_id:`, supprimer
   les champs hérités de la mère.
6. Mettre à jour toutes les références croisées dans `associations.beneficies`
   et `associations.defavorables` (ex. `id: basilic` → `id: ARO-001`).
7. Mettre à jour `FichePlanteValidator`, `FichePlanteMapper`, et les tests.

---

## Conséquences

### Positives

- IDs stables, language-agnostic, non ambigu entre deux plantes homonymes.
- Relation espèce/variété formelle : le catalogue est structuré, les vues
  (liste + réseau) peuvent filtrer par niveau.
- Moins de duplication dans les fiches filles (sparse inheritance).
- Le registre `id_registry.yaml` sert d'index humain lisible et d'outil de
  contribution (« quel est le prochain ID disponible ? »).

### Négatives / risques

- **Rupture** : tous les IDs existants changent. Toutes les références croisées
  dans les fiches et dans la BDD utilisateur (`fiches_plantes_personnelles.id_fiche`)
  doivent être migrées.
- **Coût de contribution** : un contributeur doit consulter le registre pour
  connaître le prochain numéro disponible (mitigé par le registre YAML simple).
- **Fiches mères à créer** : les ~25 fiches actuellement au niveau variété
  nécessitent chacune une fiche mère générique (données agronomiques communes),
  soit ~25 fichiers supplémentaires à rédiger.

---

## Liens

- Rapport enrichissement : [16-enrichissement-fiches-plantes.md](../16-enrichissement-fiches-plantes.md)
- Décision partiellement superséd​ée : [ADR-0001 §A6](archive/PRE_DEV/0001-arbitrages-de-coherence.md)
- Schéma de fiche : [`assets/fiches_plantes/_schema/fiche_plante_schema.yaml`](../../assets/fiches_plantes/_schema/fiche_plante_schema.yaml)
