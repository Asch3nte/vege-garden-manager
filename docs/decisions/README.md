# Architecture Decision Records (ADR)

Ce dossier consigne les **décisions structurantes** du projet : leur contexte,
l'option retenue et ses conséquences. Une décision actée ici fait foi.

## Format

Chaque ADR est un fichier `NNNN-titre-court.md` avec :

- **Statut** : Proposé / Accepté / Superséd​é / Déprécié
- **Date**
- **Contexte** — le problème et les forces en présence
- **Décision** — l'option retenue
- **Conséquences** — impacts positifs et négatifs

## Index

| #                                       | Titre                                                  | Statut  |
|-----------------------------------------|--------------------------------------------------------|---------|
| [0001](archive/PRE_DEV/0001-arbitrages-de-coherence.md) | Arbitrages de cohérence lors du découpage documentaire | Accepté |
| [0002](archive/PRE_DEV/0002-arbitrages-structurants-pre-dev.md) | Arbitrages structurants pré-dev (taxonomie, surface, i18n des fiches) | Accepté |
| [0003](archive/PRE_DEV/0003-reconciliation-enums.md) | Réconciliation des énumérations (parcelles, sol, climat, localisation) | Accepté |
| [0004](archive/PRE_DEV/0004-entites-domain-et-perimetre.md) | Entités du Domain & périmètre (récolte, préférences, observations, sync) | Accepté |
| [0005](0005-fiche-mere-varietes-et-id.md) | Hiérarchie espèce/variété et format des IDs de fiches plantes | Accepté |
| [0006](0006-fiches-famille-botanique.md) | Fiches de famille botanique (type sœur, pas grand-mère) | Accepté |
| [0007](0007-vue-reseau-exploratoire.md) | Vue Réseau du Catalogue : modèle de transformation explicite et découpage en lots | Accepté |
| [0008](0008-vue-reseau-familles-et-focus.md) | Vue Réseau du Catalogue : layout par familles, mode focus, et résolveur d'associations unifié | Accepté |
| [0009](0009-paliers-experience-divulgation-progressive.md) | Paliers d'expérience et divulgation progressive (gating réversible, teaser, onboarding) | Accepté |
| [0010](0010-associations-multi-mecanismes.md) | Modèle d'associations multi-mécanismes (permaculture) : taxonomie typée + dérivation | Accepté |
| [0011](0011-scoring-ponderation-associations.md) | Scoring & pondération des associations (profil personnalisable, tri/élagage de la vue) | Accepté |
| [0012](0012-associations-directionnelles-refonte-vue.md) | Associations directionnelles & refonte de la vue Associations (sens, familles-labels, anti-chevauchement, bandeau fiche) | Accepté |

> Pour proposer une nouvelle décision, dupliquer un ADR existant, incrémenter le
> numéro, et ouvrir une PR.
