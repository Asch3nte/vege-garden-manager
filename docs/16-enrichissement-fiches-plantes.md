# 16 — Enrichissement des fiches plantes (moteur de recommandation)

> **Objet.** Recenser les champs manquants dans les fiches YAML pour que le
> moteur de recommandation puisse filtrer et scorer les plantes selon la
> localisation, le type de sol, l'ensoleillement, les équipements, les
> associations bénéfiques/nuisibles, les ravageurs et d'autres paramètres
> agro-écologiques. Ce document est la source de vérité pour les évolutions
> du schéma de fiche (`_schema/fiche_plante_schema.yaml`) et de l'entité
> `FichePlante`.
>
> Décision connexe : [ADR-0005](decisions/0005-fiche-mere-varietes-et-id.md)
> (hiérarchie espèce/variété + format des IDs).
>
> Convention : ✅ implémenté · 🔵 parsé mais non utilisé par le moteur ·
> ⚪ absent.

---

## 1. État actuel — ce qui existe et son utilisation

| Champ YAML | Entité Domain | Utilisé dans l'évaluateur |
|---|---|---|
| `besoins.ensoleillement` | `BesoinsCulture.soleil` | ✅ score soft 40% |
| `besoins.qualites_sol` | `BesoinsCulture.qualitesSol` | ✅ score soft 40% |
| `associations.beneficies / defavorables` | `_associationsBenefiques / Negatives` | ✅ filtre dur + score soft 20% |
| `rotation.famille + delai_retour_annees` | `rotationFamille + delaiRetourAnnees` | ✅ filtre dur rotation |
| `cycle.espacement_cm` | `espacementCm` | ✅ filtre dur surface libre |
| `periodes` | `_periodes` (hémisphère × TypeClimat) | ✅ filtre dur saison |
| `besoins.ph_min / ph_max` | `BesoinsCulture.phMin/Max` | 🔵 parsé, non utilisé |
| `besoins.temperature_min_germination` | — | 🔵 parsé, non utilisé |
| `besoins.temperature_optimale` | — | 🔵 parsé, non utilisé |
| `cycle.hauteur_adulte_cm` | — | 🔵 parsé, non utilisé |
| Rusticité USDA de la plante | — | ⚪ absent |
| Température de survie (gel) | — | ⚪ absent |
| Niveau de difficulté | — | ⚪ absent |
| Profondeur sol / contenant | — | ⚪ absent |
| Culture verticale | — | ⚪ absent |
| Équipements requis/recommandés | — | ⚪ absent |
| Ravageurs structurés | — | ⚪ absent |
| Maladies structurées | — | ⚪ absent |
| Fixateur d'azote / besoin azote | — | ⚪ absent |

---

## 2. Champs manquants — classés par priorité

### 🔴 Priorité 1 — Filtres durs absents (impact immédiat sur la pertinence)

#### A. Rusticité tolérée par la plante

**Problème.** `ZoneRusticite` (zone1–zone13) existe sur le `Potager` (ce que le
potager *subit*), mais aucun champ ne décrit ce que la plante *tolère*. Le moteur
ne peut pas filtrer les plantes selon la résistance au froid de l'utilisateur.

```yaml
# À ajouter dans le schéma — section besoins
rusticite:
  zone_min: zone6   # ZoneRusticite — limite froide supportée (USDA)
  zone_max: zone11  # optionnel — limite chaude (zones tropicales)
```

**Impact moteur.** Filtre dur : exclure les plantes dont `zone_min > zone potager`.
Concerne en particulier les vivaces (artichaut, asperge, lavande) et les plantes
semi-rustiques (basilic, aubergine).

---

#### B. Température minimale de survie (tolérance au gel)

**Problème.** `temperature_min_germination` couvre uniquement le semis. Une tomate
germe à 18 °C mais meurt à -1 °C. Sans cette donnée, les alertes gel ciblées par
plante (doc 02 §7) et le calcul de la date de repiquage sécurisée sont impossibles.

```yaml
# À ajouter dans besoins
temperature_min_survie: -2   # °C — seuil de mort par gel
gele_fatal: true             # bool — vrai si le moindre gel détruit la plante
```

**Impact moteur.** (1) Filtre dur : repiquage uniquement après `dateDernierGelEstimee`
du potager si `gele_fatal: true`. (2) Alertes gel depuis `EvaluateurAlertesMeteo`
ciblées par plante plutôt que génériques.

---

#### C. Niveau de difficulté

**Problème.** `NiveauExperience` (debutant/intermediaire/expert) est stocké sur le
profil utilisateur mais jamais croisé avec la fiche plante. Un débutant devrait
recevoir des recommandations filtrées sur les plantes faciles.

```yaml
# À ajouter en section racine
difficulte: 2   # int 1–3 : 1 = débutant, 2 = intermédiaire, 3 = expert
```

**Impact moteur.** Filtre dur ou pénalité de score : une plante `difficulte: 3`
est filtrée (ou déclassée) pour un utilisateur `NiveauExperience.debutant`.

---

#### D. Compatibilité contenant et profondeur de sol

**Problème.** `Parcelle` a un `TypeParcelle` (pleineTerre, bacSureleve, jardiniere,
pot…) mais la fiche plante ne déclare pas si elle convient à un pot de 30 cm. Une
carotte exige 30 cm de terre meuble ; un radis, 15 cm. Critique pour les utilisateurs
avec balcon/terrasse.

```yaml
# À ajouter dans cycle
profondeur_sol_min_cm: 30    # profondeur minimale de terre (cm)
compatible_hors_sol: true    # compatible bac/jardinière/pot — false = pleine terre uniquement
```

**Impact moteur.** Filtre dur : si `profondeur_sol_min_cm > profondeur de la parcelle`
ou si `compatible_hors_sol: false` et `TypeParcelle ∈ {jardiniere, pot}`.

---

### 🟠 Priorité 2 — Score enrichi et nouveaux axes de recommandation

#### E. Compatible culture verticale

**Problème.** `Parcelle.cultureVerticale` est persisté, mais la fiche ne déclare pas
si la plante supporte/requiert un support vertical. Le moteur ne peut pas valoriser
le fait qu'un utilisateur a un treillis.

```yaml
# À ajouter dans cycle
culture_verticale: true   # bool — haricot grimpant, concombre, courge sur treillis
```

**Impact moteur.** Bonus de score : si `culture_verticale: true` et
`parcelle.cultureVerticale = true`. Filtre informatif si la plante *nécessite* un
support (potentiellement relier à `equipements_requis`).

---

#### F. Équipements requis et recommandés

**Problème.** Aucun lien entre la fiche et `TypeEquipement`. Une aubergine exigeant
un semis en serre chauffée passe comme n'importe quel légume.

```yaml
# À ajouter en section racine
equipements:
  requis:
    - tuteur          # TypeEquipement — sans lui, la culture échoue
    - serre_semis     # obligatoire pour le semis intérieur
  recommandes:
    - filet_anti_insecte
    - voile_hivernage
```

**Impact moteur.** (1) Filtre dur : exclure les plantes dont un équipement requis
manque dans la parcelle ou le potager. (2) Score boost : `+0.1` par équipement
recommandé présent.

---

#### G. Ravageurs et maladies structurés

**Problème.** Ces informations sont aujourd'hui enfouies dans les textes libres
(`description`, `erreurs_frequentes`) et dans les raisons d'association. Les rendre
structurées ouvre trois usages moteur.

```yaml
# À ajouter en section racine
ravageurs:
  - id: puceron          # identifiant normalisé (liste fermée à définir)
    gravite: elevee      # faible | moderee | elevee
    periode: [4, 9]      # mois d'activité principale (optionnel)
  - id: doryphore
    gravite: moderee

maladies:
  - id: mildiou
    conditions: humide_chaud   # humide_froid | humide_chaud | sec | universel
    gravite: elevee
  - id: oïdium
    gravite: faible
```

**Impact moteur.**
1. **Alertes préventives ciblées** : conditions météo favorables au mildiou
   (`conditions: humide_chaud`) → alerte sur les plantes `gravite: elevee`.
2. **Enrichissement des associations** : « Le basilic repousse le puceron,
   ravageur critique de vos tomates » au lieu d'une raison générique.
3. **Croisement avec les observations** : l'utilisateur a observé une attaque de
   pucerons → le moteur déprioritise les plantes très sensibles et boost les
   compagnons répulsifs.

---

#### H. Fixateur d'azote et besoins NPK simplifiés

**Problème.** Le moteur gère la rotation par famille botanique mais ignore la
dynamique nutritive. `precedents_favorables: [legumineuses]` sur la tomate est
du texte non structuré pour le moteur.

```yaml
# À ajouter dans rotation
fixe_azote: true           # bool — légumineuses uniquement
besoin_azote: eleve        # faible | modere | eleve
besoin_phosphore: modere   # optionnel
besoin_potasse: faible     # optionnel
```

**Impact moteur.** (1) La rotation recommande d'alterner une plante à fort
`besoin_azote` avec une légumineuse (`fixe_azote: true`). (2) La raison
affichée devient pédagogique : « Idéal après vos pois — sol enrichi en azote. »

---

#### I. Plage d'ensoleillement tolérée

**Problème.** `ensoleillement` est une valeur unique, donc un écart de 1 niveau
donne un score de 0.5 quel que soit le contexte. Une tomate pousse (moins bien) en
mi-ombre ; une laitue peut y être optimale.

```yaml
# Remplacement de ensoleillement par deux champs
besoins:
  ensoleillement_prefere: plein_soleil   # remplace l'actuel ensoleillement
  ensoleillement_min: mi_ombre           # tolérance minimale (optionnel)
```

**Impact moteur.** Score exposition : 1.0 si `prefere`, 0.5 si entre `min` et
`prefere`, 0.0 dessous. Migration non-breaking : si `ensoleillement_min` absent,
comportement identique à aujourd'hui.

---

### 🟡 Priorité 3 — Affichage enrichi et préparer V2

#### J. Variétés connues (liste informative)

Lié à [ADR-0005](decisions/0005-fiche-mere-varietes-et-id.md). La fiche mère liste
les IDs de ses fiches filles — donnée dérivée du catalogue, mais utile pour l'affichage.

```yaml
varietes_connues: [LEG-001-V001, LEG-001-V002]   # IDs des fiches filles
```

---

#### K. Période de floraison

Pertinent pour les fleurs de compagnonnage. Le moteur peut recommander un souci qui
fleurit *pendant* la période de culture des tomates.

```yaml
floraison:
  hemisphere_nord:
    oceanique: [6, 9]   # [mois_debut, mois_fin]
```

---

#### L. Sensibilité météo (pont V1 → V2)

Champs optionnels préparés maintenant pour ne pas casser le schéma en V2. Voir aussi
[`docs/13 §2.1`](13-roadmap-et-versioning.md) et la mémoire projet.

```yaml
sensibilite_meteo:
  chaleur: moderee           # faible | moderee | elevee — stress > temperature_max_stress
  temperature_max_stress: 35 # °C
  humidite: elevee           # risque fongique en atmosphère humide persistante
  vent: faible               # sensibilité (casse tiges, dessèchement)
```

---

## 3. Ce qui n'a pas besoin d'être ajouté

| Point | Raison |
|---|---|
| `texture_sol` préférée dans la fiche | `DerivationSol` mappe déjà `TextureSol → QualiteSol` — la fiche ne doit pas décrire la texture qu'elle préfère, mais les qualités |
| `surface_min_m2` | Calculée depuis `espacement_cm²` dans l'évaluateur |
| Pollinisateurs attirés (struct.) | Couvert par `usages: [mellifere, pollinisateur]` déjà dans le schéma |
| NPK précis (mg/g, ratio) | `besoin_azote` simplifié (§H) suffit pour V1 |

---

## 4. Récapitulatif priorisation

| # | Champ | Priorité | Effort ajout YAML | Impact moteur |
|---|---|---|---|---|
| A | `rusticite.zone_min/max` | 🔴 | Faible | Filtre dur hivernal |
| B | `temperature_min_survie` + `gele_fatal` | 🔴 | Faible | Alertes gel + filtre repiquage |
| C | `difficulte` (1–3) | 🔴 | Triviale | Filtre/score niveau utilisateur |
| D | `profondeur_sol_min_cm` + `compatible_hors_sol` | 🔴 | Faible | Filtre dur contenants/balcons |
| E | `culture_verticale` | 🟠 | Triviale | Bonus score treillis |
| F | `equipements.requis / recommandes` | 🟠 | Moyenne | Filtre dur + bonus score |
| G | `ravageurs` + `maladies` (structurés) | 🟠 | Moyenne | Alertes ciblées + associations enrichies |
| H | `fixe_azote` + `besoin_azote` | 🟠 | Faible | Rotation nutritive pédagogique |
| I | `ensoleillement_min` (plage tolérée) | 🟠 | Triviale | Score exposition plus précis |
| J | `varietes_connues` | 🟡 | Triviale | Affichage catalogue |
| K | `floraison` | 🟡 | Faible | Synchronisation fleurs compagnons |
| L | `sensibilite_meteo` | 🟡 | Faible | Alertes météo par plante (V2) |

---

## 5. Ordre d'implémentation recommandé

1. **Valider l'ADR-0005** (hiérarchie espèce/variété + nouveau format des IDs) —
   prerequis car il change `id` et ouvre le champ `parent_id`.
2. **Mettre à jour `_schema/fiche_plante_schema.yaml`** avec les champs A–D.
3. **Enrichir les fiches existantes** avec ces champs (commencer par les
   ~10 fiches de test, puis le reste par catégorie).
4. **Mettre à jour `FichePlante` (domain) et `BesoinsCulture`** pour porter
   les nouveaux champs.
5. **Mettre à jour `FichePlanteMapper`** pour les parser.
6. **Mettre à jour `EvaluateurRecommandations`** pour utiliser les filtres
   durs A–D et les nouvelles contributions au score E–I.
7. **Tests en parallèle** à chaque étape (schéma → mapper → évaluateur).
