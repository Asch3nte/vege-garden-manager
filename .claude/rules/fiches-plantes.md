---
paths:
  - "assets/fiches_plantes/**"
  - "FICHES A CREER.md"
---

# Fiches plantes YAML

- Hiérarchie ADR-0005 : famille → espèce (mère) → variétés (filles).
- IDs : mère `[CAT3]-[NUM3]`, fille `[CAT3]-[NUM3]-V[NUM3]` ; séquentiels, immuables, jamais réattribués.
- `_schema/id_registry.yaml` fait foi ; le mettre à jour avec chaque fiche.
- La famille doit exister dans `_familles/*.yaml` avant toute espèce.
- Références croisées (associations, rotation) par id, jamais par nom.
- Données chiffrées sourcées à la création, jamais déduites ni inventées ; champ laissé vide sans source.
- Une fille ne surcharge pas `nom_scientifique` : hybride d'une autre espèce → mère distincte.
- Après un lot : `dart run tool/verifier_referentiels.dart` + tests catalogue, puis mise à jour de `FICHES A CREER.md`.
