# 07 — Base de connaissances (fiches plantes YAML)

> Source : CAHIER §1.6 & §3.5. **Format canonique = §3.5** (un fichier par plante,
> `i18n` imbriqué, `id` en `snake_case`). Le format alternatif de §1.6 (IDs codés
> `L0101-002`, fichiers data/i18n séparés) est **abandonné** — voir
> [decisions/0001-arbitrages-de-coherence.md](decisions/0001-arbitrages-de-coherence.md).

## 1. Pourquoi YAML ?

| Critère               | Verdict                                         |
|-----------------------|-------------------------------------------------|
| Lisible par un humain | ✅ (mieux que JSON)                             |
| Contributif           | ✅ diffable proprement sur GitHub (PR claires)  |
| Multilingue           | ✅ structure imbriquée naturelle                |
| Pas de BDD requise    | ✅ fichiers texte versionnables                 |
| Validable             | ✅ schéma + validateur Dart                     |
| Performant            | ⚠️ parsing → **cache mémoire obligatoire**      |

**Conclusion** : fiches **embarquées** dans l'app, chargées au démarrage,
validées, puis mises en cache mémoire pour des accès instantanés.

## 2. Périmètre au lancement (~200 fiches)

| Catégorie                   | Exemples                                  | Volume  |
|-----------------------------|-------------------------------------------|---------|
| Légumes                     | tomates, courgettes, haricots, carottes…  | ~80–100 |
| Aromatiques                 | basilic, thym, romarin, menthe…           | ~30–40  |
| Médicinales                 | camomille, calendula, consoude, ortie…    | ~20–30  |
| Vivaces comestibles         | rhubarbe, artichaut, asperge, oseille…    | ~15–20  |
| Grains & céréales           | blé, seigle, sarrasin, quinoa…            | ~10–15  |
| Engrais verts / couvre-sols | moutarde, trèfle, phacélie, vesce…        | ~10–15  |

Extensible sans limite.

## 3. Localisation dans le projet

```
assets/fiches_plantes/
├── _schema/
│   └── fiche_plante_schema.yaml      # schéma de référence
├── legumes/      (tomate.yaml, courgette.yaml, …)
├── aromatiques/  (basilic.yaml, persil.yaml, …)
├── fruits/       (fraise.yaml, …)
└── fleurs_compagnonnage/ (soucis.yaml, capucine.yaml, …)
```

> Une fiche = un fichier. Une catégorie = un dossier. Déclarés dans `pubspec.yaml`
> (`flutter: assets:`).

## 4. Structure d'une fiche (exemple `legumes/tomate.yaml`)

```yaml
# Métadonnées techniques
id: tomate                 # unique, immuable, snake_case
version_fiche: 1
categorie: legume          # legume | aromatique | fruit | fleur_compagnonnage
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
  ensoleillement: plein_soleil   # plein_soleil | mi_ombre | ombre
  arrosage: regulier             # faible | regulier | abondant
  type_sol: [riche, bien_draine]
  ph_min: 6.0
  ph_max: 7.0
  temperature_min_germination: 18
  temperature_optimale: 22

# Cycle
cycle:
  type: annuelle                 # annuelle | bisannuelle | vivace
  duree_germination_jours: [6, 10]
  duree_avant_recolte_jours: [70, 90]
  hauteur_adulte_cm: [80, 200]
  espacement_cm: 60
  profondeur_semis_cm: 1

# Périodes (par hémisphère + zone climatique), mois en entiers 1–12
periodes:
  hemisphere_nord:
    zone_temperee:
      semis_interieur: [2, 4]
      semis_exterieur: [5, 6]
      plantation: [5, 6]
      recolte: [7, 10]
    zone_mediterraneenne:
      semis_interieur: [1, 3]
      plantation: [4, 5]
      recolte: [6, 10]
  hemisphere_sud:
    zone_temperee:
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

| Élément             | Règle                                                               |
|---------------------|---------------------------------------------------------------------|
| Nom de fichier      | `[id_plante].yaml`, `snake_case`, sans accents                      |
| `id`                | unique, immuable, `snake_case`, minuscules                          |
| Catégorie           | une seule : `legume`, `aromatique`, `fruit`, `fleur_compagnonnage`  |
| Champs `i18n`       | `fr` **obligatoire**, autres optionnelles                           |
| Périodes            | mois en entiers `1`–`12`                                            |
| Références croisées | par `id`, jamais par nom commun                                     |
| `schema_version`    | incrémenté à chaque évolution du format                             |
| Encodage            | UTF-8                                                               |
| Indentation         | 2 espaces (pas de tab)                                              |

## 6. Pipeline de chargement (Infrastructure)

```
1. YamlAssetLoader        → liste & lit les fichiers du bundle (AssetManifest, UTF-8)
2. YamlParser             → YAML → Map<String, dynamic> (capture erreurs de syntaxe)
3. FichePlanteValidator   → champs obligatoires, cohérence (ph_min < ph_max), unicité id,
                            validité des références croisées → FichePlanteInvalideException
4. FichePlanteMapper      → Map → FichePlante (Domain) + construction des Value Objects
5. FichePlanteCache       → Map<String, FichePlante> en mémoire + index (catégorie, famille…)
6. FichePlanteRepositoryImpl → implémente AbstractFichePlanteRepository depuis le cache
```

**Robustesse** : une fiche corrompue est **ignorée avec log d'erreur** (message
visible en debug) — l'app ne plante pas.

**Quand charger ?** Au démarrage, dans un **splash screen**, avant l'accueil
(chargement asynchrone ~150 fichiers → validation → cache).

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
