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

> Pour proposer une nouvelle décision, dupliquer un ADR existant, incrémenter le
> numéro, et ouvrir une PR.
