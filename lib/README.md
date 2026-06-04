# `lib/` — Organisation du code

Le code suit une **Clean Architecture à 4 couches**. Voir la spécification
complète : [`../docs/04-architecture-en-couches.md`](../docs/04-architecture-en-couches.md).

```
lib/
├── main.dart        # point d'entrée
├── app/             # bootstrap, router (go_router), thème (design system)
├── domain/          # Cœur métier — ne dépend de RIEN
│   ├── entities/        Potager, Parcelle, Plantation, Recolte, Tache, Rappel, Equipement…
│   ├── value_objects/   Surface, Periode, Quantite, Localisation, ZoneClimatique…
│   ├── enums/           TypeParcelle, StatutPlantation, TypeTache…
│   ├── repositories/    interfaces abstraites (Abstract*Repository, Abstract*Service)
│   └── exceptions/      PotagerException + sous-types typés
├── application/     # Orchestration — dépend de domain/
│   ├── use_cases/       une action métier = une classe
│   └── state/           Notifiers Riverpod
├── infrastructure/  # Techniques externes — implémente les interfaces du domain
│   ├── database/        drift (tables, DAOs, migrations)
│   ├── repositories/    implémentations concrètes
│   ├── mappers/         SQL <-> entités / Value Objects
│   ├── catalogue/       chargement + validation + cache des fiches YAML
│   ├── api/             client Open-Meteo
│   └── services/        notifications, géolocalisation, sync WiFi, backup
├── presentation/    # UI Flutter — dépend de application/
│   ├── screens/         pages par panel (accueil, potager, catalogue, calendrier, plus)
│   ├── widgets/         composants du design system
│   └── providers/       providers Riverpod
├── core/            # constants, extensions, utils (transverse, sans logique métier)
└── l10n/            # fichiers ARB (i18n)
```

**Règle de dépendance** : `presentation → application → domain ← infrastructure`.
Le `domain/` ne référence jamais Flutter, drift, http, etc.

> Les dossiers contiennent des `.gitkeep` en attendant le code. Ils seront
> peuplés au fil du développement (cf. ordre suggéré dans
> [`../docs/13-roadmap-et-versioning.md`](../docs/13-roadmap-et-versioning.md)).
