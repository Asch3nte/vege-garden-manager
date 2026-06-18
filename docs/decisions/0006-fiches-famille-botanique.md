# ADR-0006 — Fiches de famille botanique (type sœur, pas grand-mère)

- **Statut** : Accepté
- **Date** : 2026-06-11
- **Contexte** : [ADR-0005](0005-fiche-mere-varietes-et-id.md) a formalisé la
  hiérarchie **espèce (mère) → variété (fille)**. Chaque fiche porte déjà la
  famille botanique sous deux champs redondants : `famille_botanique`
  (ex. `Solanaceae`) et `rotation.famille` (ex. `solanaceae`). Mais la famille
  n'est qu'une chaîne libre : ni objet, ni contenu, ni registre.

  Deux besoins concrets la réclament désormais comme entité de première classe :

  1. **Filtrage** — dans le Catalogue, sélectionner une catégorie (ex. *Légumes*)
     doit révéler une seconde ligne de filtres : les **familles botaniques** de
     cette catégorie (Solanacées, Cucurbitacées, Brassicacées…).
  2. **Éducation** — porter le contenu explicatif propre à une famille (pourquoi
     telle rotation, pourquoi ces ennemis/maladies partagés, pourquoi certaines
     associations fonctionnent) pour alimenter de futures bulles informatives.

---

## Décision 1 — La famille est un **type sœur**, pas une fiche « grand-mère »

On **n'étend pas** la chaîne d'héritage d'ADR-0005 vers le haut. Une fiche
« grand-mère » réutilisant la structure `FichePlante` serait une mauvaise
abstraction :

- le motif mère/fille marche parce que la fille hérite **des mêmes champs** que
  la mère (besoins, cycle, périodes, espacement…) — *même forme de données* ;
- une **famille n'a pas cette forme** : pas de `pH`, pas d'`espacement_cm`, pas
  de `periodes`, pas de `duree_avant_recolte`. La forcer dans le moule
  `FichePlante` casserait les invariants de l'entité, le validateur et le
  mapper, et ferait hériter vers le bas des champs vides de sens.

La famille est donc modélisée comme une **entité distincte**
(`FamilleBotanique`), à côté des fiches plantes, avec son propre petit schéma,
son entité, son mapper/loader et son validateur. Elle n'entre pas dans la
fusion mère/fille.

| Niveau | Objet | Type | Exemple |
|---|---|---|---|
| **Famille** | regroupement botanique + contenu éducatif | `FamilleBotanique` | Solanacées (`solanaceae`) |
| Espèce (mère) | données agronomiques générales | `FichePlante` | Tomate (`LEG-001`) |
| Variété (fille) | surcharge légère sur la mère | `FichePlante` | Tomate Cœur de Bœuf (`LEG-001-V001`) |

---

## Décision 2 — Identité : l'id de famille = **nom scientifique normalisé**

Contrairement aux fiches plantes (`CAT3-NNN`, numéros séquentiels), une famille
**n'a pas besoin** d'un numéro arbitraire ni d'un registre de numérotation :

- le nom de famille botanique (latin, ex. `Solanaceae`) est déjà **stable,
  unique et language-agnostic** — il satisfait l'invariant d'un id immuable ;
- il est **déjà présent** dans les données (`famille_botanique` /
  `rotation.famille`) → liaison triviale, lecture auto-évidente.

**Règle** : `id = normaliserCle(nom_scientifique)` = nom scientifique en
minuscules, sans accent ni espace (`Solanaceae` → `solanaceae`). Le fichier est
`assets/fiches_plantes/_familles/<id>.yaml`.

La normalisation canonique est centralisée dans
`FamilleBotanique.normaliserCle(...)`, réutilisée par le loader et le validateur.

---

## Décision 3 — Lien espèce → famille, sans nouvelle redondance

L'espèce déclare sa famille via le champ **déjà existant** `rotation.famille`
(slug). Aucun champ neuf, aucune édition de masse des fiches actuelles : la clé
de liaison est `normaliserCle(famille_botanique)`, qui est par construction
égale à `rotation.famille`.

> **Convergence (dette d'ADR-0005)** : `famille_botanique` (nom scientifique
> lisible) et `rotation.famille` (slug) restent tous deux présents — le premier
> est l'affichage humain dans la fiche, le second la clé. Leur cohérence
> (`normaliserCle(famille_botanique) == rotation.famille`) devient une règle
> vérifiée par le validateur (Lot 2). Une éventuelle fusion en un seul champ est
> hors périmètre de cet ADR.

---

## Décision 4 — Les familles sont **globales**, le filtre est **dérivé par catégorie**

Une même famille traverse plusieurs catégories (les Apiacées contiennent la
carotte — *légume* — **et** le persil/la coriandre — *aromatiques*). Donc :

- **une seule fiche par famille**, dans un dossier unique `_familles/`
  (non rangé par catégorie) ;
- la fiche famille déclare `categories: [...]` — les catégories du projet où
  elle est **pertinente** (sert de référence complète et permet d'afficher la
  famille même avant qu'une espèce n'existe) ;
- dans le Catalogue, la 2ᵉ ligne de filtres liste les familles **présentes
  parmi les espèces de la catégorie choisie** (dérivé à l'exécution). Sous
  *Tout*, pas de ligne familles.

---

## Format YAML d'une fiche famille

```yaml
# assets/fiches_plantes/_familles/solanaceae.yaml
id: solanaceae                 # nom scientifique normalisé (slug) — immuable
nom_scientifique: Solanaceae
schema_version: 1
categories: [legume, fleur]    # catégories du projet où la famille est pertinente
i18n:
  fr:
    nom_commun: Solanacées
    description: >
      Famille de plantes souvent gourmandes en éléments nutritifs et sensibles
      au mildiou ; comprend tomate, aubergine, poivron, pomme de terre.
    # Champs éditoriaux (éducation) — optionnels, enrichis ultérieurement :
    pourquoi_rotation: ~
    ennemis_communs_note: ~
    associations_note: ~
  en: { ... }                  # (optionnel)
maladies_communes: [mildiou]   # (optionnel) structuré, réutilisable par le moteur
ravageurs_communs: [doryphore] # (optionnel)
delai_retour_annees: 4         # (optionnel) défaut de rotation au niveau famille
sources: [ ... ]
contributeurs: [ ... ]
```

---

## Plan par lots

| Lot | Périmètre |
|---|---|
| **1 — Fondations données** | schéma `famille_schema.yaml` ; entité `FamilleBotanique` + tests ; jeu complet de fiches famille (toutes les familles connues et pertinentes des 7 catégories) ; registre index. |
| **2 — Chargement & validation** | loader/mapper familles ; intégrité référentielle (toute `rotation.famille` d'espèce pointe une fiche famille ; cohérence `famille_botanique`↔slug) ; `tool/scrap_fiche.dart` émet/rattache la clé famille normalisée. |
| **3 — Catalogue (filtrage)** | 2ᵉ ligne de chips familles sous la catégorie choisie (notifier + vue + écran + tests widget). |
| **4 — Éducation** | bulles info au niveau famille (`pourquoi_rotation`, ennemis/maladies, associations) — différable (`docs/15`). **Lot 4a (socle data) ✅** : **référentiel normalisé des bioagresseurs** `_referentiels/bioagresseurs.yaml` (entité `Bioagresseur` + enum `TypeBioagresseur` + pipeline source/validator/mapper/cache/loader/repo + providers), **intégrité référentielle** des slugs `maladies_communes`/`ravageurs_communs` (`VerificateurIntegriteBioagresseurs`, gardée par `bioagresseurs_reel_test.dart`). **Lot 4b (champs éditoriaux) ✅** : `pourquoi_rotation`/`ennemis_communs_note`/`associations_note` (localisés) sur `FamilleBotanique` + mapper + validateur ; 2 familles seedées en exemple. **Lot 4c (outillage) ✅** : `tool/sources_botaniques.dart` (factorisé), `tool/scrap_famille.dart` (brouillon de fiche famille), `tool/verifier_referentiels.dart` (lint pur Dart CI-able réutilisant les vérificateurs). **Lot 4d (contenu + UI) ✅** : 12 familles utilisées remplies + 47 bioagresseurs décrits ; `_SectionFamille` dans la fiche plante (notes + chips maladies/ravageurs nommés). Restent : `code_eppo`/descriptions des bioagresseurs restants, familles non utilisées, traductions `en`, et les **raisons typées par association** (ADR-0010). |

---

## Conséquences

### Positives
- Bonne abstraction : la famille porte exactement ses champs, sans polluer la
  fiche plante ni la fusion mère/fille.
- Filtrage **et** éducation servis par la même entité, sans nouveau champ sur
  les espèces.
- Id stable/language-agnostic sans registre de numérotation à maintenir.
- Staturé : le filtre (Lot 3) est livrable avant l'enrichissement éditorial
  (Lot 4), sans changement de structure.

### Négatives / risques
- Un nouveau type de fiche = nouveau schéma, entité, mapper, loader, validateur
  (mais petits et isolés).
- Le jeu de fiches famille doit être tenu à jour quand une espèce d'une famille
  non encore couverte est ajoutée (mitigé par le contrôle d'intégrité du Lot 2).
- Redondance `famille_botanique`/`rotation.famille` conservée (cohérence
  désormais vérifiée, fusion repoussée).

---

## Liens
- ADR parent : [ADR-0005](0005-fiche-mere-varietes-et-id.md)
- Schéma fiche famille : [`assets/fiches_plantes/_schema/famille_schema.yaml`](../../assets/fiches_plantes/_schema/famille_schema.yaml)
- Registre des familles : [`assets/fiches_plantes/_familles/familles_registry.yaml`](../../assets/fiches_plantes/_familles/familles_registry.yaml)
