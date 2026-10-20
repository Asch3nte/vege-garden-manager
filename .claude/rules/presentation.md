---
paths:
  - "lib/presentation/**"
  - "lib/l10n/**"
---

# Presentation et i18n

- Tout texte visible passe par l'ARB, clés `fr` et `en` ajoutées ensemble.
- Fonctionnalité de palier : gating via `AccesNiveau` (ADR-0009).
- Terme technique affiché : lien vers le glossaire quand l'entrée existe (ADR-0017).
- Couleurs, typo, espacements : thème « Carnet vivant » (`lib/app/theme/`, docs/08), jamais de valeur en dur.
