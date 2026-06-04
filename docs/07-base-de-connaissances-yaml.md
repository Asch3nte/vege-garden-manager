# 07 — Base de connaissances (fiches plantes YAML)

> Source : CAHIER §1.6 & §3.5. **Format canonique = §3.5** (un fichier par plante,
> `i18n` imbriqué, `id` en `snake_case`). Le format alternatif de §1.6 (IDs codés
> `L0101-002`, fichiers data/i18n séparés) est **abandonné**.

## 1. Pourquoi YAML ?

| Critère | Verdict |
|-----------------------|-------------------------------------------------|
| Lisible par un humain | ✅ (mieux que JSON) |
| Contributif | ✅ diffable proprement sur GitHub (PR claires) |
| Multilingue | ✅ structure imbriquée naturelle |
| Pas de BDD requise | ✅ fichiers texte versionnables |
| Validable | ✅ schéma + validateur Dart |
| Performant | ⚠️ parsing → **cache mémoire obligatoire** |

**Conclusion** : fiches **embarquées** dans l'app, chargées au démarrage,
validées, puis mises en cache mémoire pour des accès instantanés.

## 2. Périmètre au lancement (~200 fiches)

La taxonomie suit **deux axes** : une **catégorie** de classement (exclusive,
= dossier) + des **usages** fonctionnels (multi-valués). « Médicinales » et « vivaces
comestibles » ne sont **pas** des catégories : ce sont respectivement un **usage**
(`medicinale`) et un **cycle** (`vivace`).

| Catégorie (`categorie`) | Exemples | Volume |
|-------------------------|-------------------------------------------|---------|
| `legume` | tomate, courgette, haricot, carotte… | ~80–100 |
| `aromatique` | basilic, thym, romarin, menthe… | ~30–40 |
| `fruit` (arbres) | pommier, figuier, cerisier… | ~10–15 |
| `petit_fruit` | fraisier, framboisier, groseillier… | ~10–15 |
| `fleur` | souci, capucine, bourrache, camomille… | ~20–30 |
| `cereale` | blé, seigle, sarrasin, quinoa… | ~10–15 |
| `engrais_vert` | moutarde, trèfle, phacélie, vesce… | ~10–15 |

> Les plantes **médicinales** (camomille, calendula, consoude, ortie…) portent l'usage
> `medicinale` dans **leur** catégorie (souvent `fleur` ou `aromatique`). Les **vivaces
> comestibles** (rhubarbe, artichaut, asperge, oseille…) sont des `legume`/`petit_fruit`
> avec `cycle.type: vivace`. Extensible sans limite.

## 3. Localisation dans le projet

```
assets/fiches_plantes/
├── _schema/
│ └── fiche_plante_schema.yaml # schéma de référence
├── legumes/ (tomate.yaml, courgette.yaml, …)
├── aromatiques/ (basilic.yaml, persil.yaml, …)
├── fruits/ (pommier.yaml, figuier.yaml, …) # arbres fruitiers
├── petits_fruits/ (fraise.yaml, framboise.yaml, …)
├── fleurs/ (souci.yaml, capucine.yaml, …)
├── cereales/ (sarrasin.yaml, …)
└── engrais_verts/ (phacelie.yaml, moutarde.yaml, …)
```

> Une fiche = un fichier. Une **catégorie** (`categorie`) = un dossier. Déclarés dans
> `pubspec.yaml` (`flutter: assets:`). Le dossier correspond à la `categorie` exclusive ;
> les `usages` (multi-valués) sont **dans** la fiche, pas dans l'arborescence.

## 4. Structure d'une fiche (exemple `legumes/tomate.yaml`)

> 📌 La fiche réelle [`assets/fiches_plantes/legumes/tomate.yaml`](../assets/fiches_plantes/legumes/tomate.yaml)
> sert de **golden file** (référence + test du pipeline de chargement). L'extrait ci-dessous
> en reprend la structure.

```yaml
# Métadonnées techniques
id: tomate # unique, immuable, snake_case
version_fiche: 1
categorie: legume # legume | aromatique | fruit | petit_fruit | fleur | cereale | engrais_vert
sous_type: legume_fruit # (optionnel, si categorie: legume) SousTypeLegume
usages: [alimentaire] # UsagePlante (≥ 1)
schema_version: 1

# Identification botanique
nom_scientifique: Solanum lycopersicum
famille_botanique: Solanaceae

# Contenu multilingue (fr obligatoire, autres optionnelles)
i18n:
  fr:
    nom_commun: Tomate
    noms_alternatifs: [Pomme d'amour]
    description: >
      Plante annuelle de la famille des Solanacées…
    conseils_culture: >
      Gourmande en eau et en soleil. Tuteurer dès la plantation.
    conseils_recolte: >
      Récolter à pleine maturité, ferme et coloré.
    erreurs_frequentes:
      - Arrosage du feuillage (favorise le mildiou)
      - Plantation trop précoce (gel)
  en:
    nom_commun: Tomato
    description: >
      Annual plant from the Solanaceae family…

# Besoins (données structurées pour le moteur)
besoins:
  ensoleillement: plein_soleil # plein_soleil | mi_ombre | ombre
  arrosage: eleve # BesoinEau : faible | modere | eleve
  qualites_sol: [riche, bien_draine, frais] # QualiteSol (liste)
  ph_min: 6.0
  ph_max: 7.0
  temperature_min_germination: 18
  temperature_optimale: 22

# Cycle
cycle:
  type: annuelle # annuelle | bisannuelle | vivace
  duree_germination_jours: [6, 10]
  duree_avant_recolte_jours: [70, 90]
  hauteur_adulte_cm: [80, 200]
  espacement_cm: 60
  profondeur_semis_cm: 1

# Périodes : par hémisphère puis TypeClimat, mois en entiers 1–12.
# Clés climat : oceanique | continental | mediterraneen | … (les 9 TypeClimat).
periodes:
  hemisphere_nord:
    oceanique:
      semis_interieur: [2, 4]
      plantation: [5, 6]
      recolte: [7, 10]
    mediterraneen:
      semis_interieur: [1, 3]
      plantation: [4, 5]
      recolte: [6, 10]
  hemisphere_sud:
    oceanique:
      semis_interieur: [8, 10]
      plantation: [11, 12]
      recolte: [1, 4]

# Associations & rotation (références par id, jamais par nom)
associations:
  beneficies:
    - id: basilic
      raison_i18n: { fr: "Repousse les pucerons, améliore le goût", en: "Repels aphids, enhances flavor" }
    - id: soucis
      raison_i18n: { fr: "Repousse les nématodes", en: "Repels nematodes" }
  defavorables:
    - id: pomme_de_terre
      raison_i18n: { fr: "Même famille, partage le mildiou", en: "Same family, shares blight" }
    - id: fenouil
rotation:
  famille: solanaceae
  delai_retour_annees: 4
  precedents_favorables: [legumineuses, engrais_verts]
  precedents_defavorables: [solanaceae]

# Post-récolte
conservation:
  - methode: frais
    duree_jours: 7
    conditions_i18n: { fr: "Température ambiante, à l'abri de la lumière", en: "Room temperature, away from light" }
  - methode: conserves
    duree_mois: 12
  - methode: lactofermentation
    duree_mois: 6
  - methode: sechage
    duree_mois: 12
utilisations_culinaires_i18n:
  fr: [Crue en salade, cuite en sauce, farcie, confite, séchée]
  en: [Raw in salads, cooked in sauces, stuffed, candied, dried]

# Source & contribution
sources:
  - https://fr.wikipedia.org/wiki/Tomate
contributeurs:
  - "@github_username"
```

## 5. Conventions structurelles strictes

| Élément | Règle |
|---------------------|---------------------------------------------------------------------|
| Nom de fichier | `[id_plante].yaml`, `snake_case`, sans accents |
| `id` | unique, immuable, `snake_case`, minuscules |
| `categorie` | une seule : `legume`, `aromatique`, `fruit`, `petit_fruit`, `fleur`, `cereale`, `engrais_vert` |
| `sous_type` | optionnel, **seulement si** `categorie: legume` (`SousTypeLegume`) |
| `usages` | liste, **≥ 1** valeur (`UsagePlante`) |
| Champs `i18n` | `fr` **obligatoire**, autres optionnelles, **texte inline** |
| Périodes | par hémisphère puis `TypeClimat` ; mois en entiers `1`–`12` |
| Références croisées | par `id`, jamais par nom commun |
| `schema_version` | incrémenté à chaque évolution du format |
| Encodage | UTF-8 |
| Indentation | 2 espaces (pas de tab) |

## 6. Pipeline de chargement (Infrastructure)

```
1. YamlAssetLoader → liste & lit les fichiers du bundle (AssetManifest, UTF-8)
2. YamlParser → YAML → Map<String, dynamic> (capture erreurs de syntaxe)
3. FichePlanteValidator → champs obligatoires, cohérence (ph_min < ph_max), unicité id,
                            validité des références croisées → FichePlanteInvalideException
4. FichePlanteMapper → Map → FichePlante (Domain) + construction des Value Objects
5. FichePlanteCache → Map<String, FichePlante> en mémoire + index (catégorie, famille…)
6. FichePlanteRepositoryImpl → implémente AbstractFichePlanteRepository depuis le cache
```

**Robustesse** : une fiche corrompue est **ignorée avec log d'erreur** (message
visible en debug) — l'app ne plante pas.

**Quand charger ?** Au démarrage, dans un **splash screen**, avant l'accueil
(chargement asynchrone ~200 fichiers → validation → cache).

## 7. Fiches créées par l'utilisateur

- Éditeur in-app : formulaires guidés (pas besoin de connaître le YAML),
  duplication d'une fiche existante comme base.
- Stockées en base, table `fiches_plantes_personnelles` — **source de vérité =
  `yaml_contenu` brut** (cf. [06](06-modele-de-donnees-sqlite.md)).
- ID logique distinct ; en cas de collision avec une fiche embarquée, **priorité
  à la fiche perso**.
- **Export YAML** → soumission en Pull Request GitHub (URL pré-remplie, zéro
  serveur intermédiaire).

## 8. Modes d'exploration (côté utilisateur)

Recherche libre · filtres combinables (catégorie, famille, période, difficulté,
exposition, associations, bienfaits) · vue calendrier (frise semis→récolte) ·
vue associations · vue rotation · fiche détaillée pédagogique.
