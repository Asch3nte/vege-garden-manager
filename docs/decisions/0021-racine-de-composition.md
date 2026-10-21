# ADR-0021 — Racine de composition dans `lib/app/`

- **Statut** : **Accepté**
- **Date** : 2026-10-21

## Contexte

Les providers d'`application/providers/` instanciaient directement les
implémentations d'`infrastructure/` : la couche Application dépendait de
l'Infrastructure, contrairement à docs/04. L'audit d'octobre 2026 demandait
d'acter cette exception ou de déplacer le branchement (option retenue par le dev).

## Décision

- `application/providers/` ne déclare que des **ports** typés par les
  abstractions du Domain ; leur valeur par défaut échoue explicitement
  (`nonBranche`).
- `lib/app/composition.dart` (`Composition.surcharges(base)`) branche chaque
  port sur son implémentation ; `Bootstrap` l'applique à la racine
  `ProviderScope`.
- Les caches du catalogue (types d'infrastructure) vivent dans `composition.dart` ;
  l'Application et la Présentation passent par les repositories et par
  `famillesParIdProvider` / `bioagresseursParIdProvider`.
- Un test d'architecture (`test/unit/architecture_test.dart`) interdit à
  `domain/` toute autre couche, à `application/` l'infrastructure, la
  présentation et `app/`, et à `presentation/` l'infrastructure.

## Conséquences

- Un test qui veut les vraies implémentations utilise `Composition.surcharges(db)`
  ; un test qui omet un port reçoit une erreur explicite au lieu de charger
  silencieusement les vraies données du bundle.
- Ajouter un port : le déclarer dans `application/providers/`, le brancher dans
  `composition.dart`.
