# 04 — Architecture en couches

> Source : CAHIER §3.1 & §3.4. **Clean Architecture adaptée Flutter, en 4 couches.**

## 1. Les 4 couches

```
┌────────────────────────────────────────────────────────────┐
│ PRESENTATION  (UI Flutter, Widgets, Pages, Riverpod)       │ ← dépend de Application
├────────────────────────────────────────────────────────────┤
│ APPLICATION   (Use Cases, State Management / Notifiers)    │ ← dépend de Domain
├────────────────────────────────────────────────────────────┤
│ DOMAIN        (Entités, Value Objects, Interfaces, règles) │ ← ne dépend de RIEN
├────────────────────────────────────────────────────────────┤
│ INFRASTRUCTURE (BDD drift, YAML, API Open-Meteo, sync WiFi)│ → implémente les interfaces du Domain
└────────────────────────────────────────────────────────────┘
```

### Règle fondamentale des dépendances

```
Presentation → Application → Domain ← Infrastructure
```

- Les couches du haut **dépendent** des couches du bas.
- Le **Domain ne dépend de rien** — c'est le cœur pur.
- L'**Infrastructure implémente** les interfaces définies par le Domain
  (inversion de dépendance, SOLID).
- **Jamais de dépendance inverse.**

## 2. Rôle de chaque couche

### 2.1 Domain (`lib/domain/`) — le cœur métier

Règles métier pures du potager. **Aucune dépendance externe** (ni Flutter, ni
drift, ni http).

| Élément                 | Exemples                                                                        |
|-------------------------|---------------------------------------------------------------------------------|
| Entités                 | `Potager`, `Parcelle`, `Plantation`, `Recolte`, `Tache`, `Rappel`, `Equipement` |
| Value Objects           | `Surface`, `Periode`, `Quantite`, `Localisation`, `ZoneClimatique`              |
| Interfaces (abstraites) | `AbstractPotagerRepository`, `AbstractMeteoService`…                            |
| Règles métier           | « la tomate ne s'associe pas au fenouil »                                       |
| Exceptions métier       | `AssociationIncompatibleException`, `SurfaceInsuffisanteException`…             |

> **Ne contient pas** : widgets, SQL, appels réseau, dépendances à des packages
> d'infrastructure. Détail : [05-modele-de-domaine.md](05-modele-de-domaine.md).

### 2.2 Application (`lib/application/`) — orchestration

Coordonne les use cases et le state. Dépend **uniquement** du Domain (via ses
interfaces).

- **Use Cases** : une action métier = une classe (ex. `CreerPlantation`,
  `RecommanderPlantes`, `CalculerBesoinArrosage`).
- **State Management** : Notifiers Riverpod qui exposent l'état à la Presentation.

### 2.3 Infrastructure (`lib/infrastructure/`) — techniques externes

Implémente les interfaces du Domain avec les technologies concrètes.

| Sous-dossier    | Rôle                                                      |
|-----------------|-----------------------------------------------------------|
| `database/`     | drift : tables, DAOs, migrations                          |
| `repositories/` | implémentations concrètes des `Abstract*Repository`       |
| `mappers/`      | conversion lignes SQL ↔ entités / Value Objects du Domain |
| `catalogue/`    | chargement + validation + cache des fiches YAML           |
| `api/`          | client Open-Meteo                                         |
| `services/`     | notifications, géolocalisation, sync WiFi, backup         |

### 2.4 Presentation (`lib/presentation/`) — UI Flutter

Widgets, écrans, et providers Riverpod. Consomme les Notifiers de la couche
Application. **Aucune logique métier ici.**

| Sous-dossier  | Rôle                                                              |
|---------------|-------------------------------------------------------------------|
| `screens/`    | pages (par panel : accueil, potager, catalogue, calendrier, plus) |
| `widgets/`    | composants réutilisables (cf. design system)                      |
| `providers/`  | providers Riverpod (injection)                                    |

## 3. Arborescence cible

```
lib/
├── main.dart
├── app/                       # router (go_router), theme, bootstrap
├── domain/
│   ├── entities/
│   ├── value_objects/
│   ├── enums/
│   ├── repositories/          # interfaces abstraites
│   └── exceptions/
├── application/
│   ├── use_cases/
│   └── state/                 # Notifiers Riverpod
├── infrastructure/
│   ├── database/              # drift (tables, DAOs, migrations)
│   ├── repositories/          # implémentations concrètes
│   ├── mappers/
│   ├── catalogue/             # parsing + cache YAML
│   ├── api/                   # Open-Meteo
│   └── services/              # notifications, geoloc, sync, backup
├── presentation/
│   ├── screens/
│   ├── widgets/
│   └── providers/             # Riverpod
├── core/
│   ├── constants/
│   ├── extensions/
│   └── utils/
└── l10n/                      # ARB i18n
assets/
└── fiches_plantes/            # YAML (par catégorie) + _schema/
test/
├── unit/  ├── widget/  └── integration/
```

## 4. Principes architecturaux

| Principe                        | Application                                                           |
|---------------------------------|-----------------------------------------------------------------------|
| Inversion de dépendance (SOLID) | Interfaces dans le Domain, implémentations dans Infrastructure        |
| POO stricte                     | Encapsulation, héritage, abstraction, polymorphisme — non négociable  |
| Null safety                     | Activé partout                                                        |
| Immutabilité                    | Value Objects immuables ; listes via `List.unmodifiable()`            |
| IDs en `String`                 | UUID v4 généré côté app, pour la sync multi-appareils                 |
| Exceptions métier typées        | Pas de `throw Exception('...')` générique                             |

## 5. Flux complet d'une action utilisateur

Exemple : *l'utilisateur ajoute une plantation*.

```
[Presentation]  Tap "[Planter]" → appelle le Notifier (Application)
      │
      ▼
[Application]   Use Case CreerPlantation :
                 1. valide les règles métier (via le Domain : pasDeConflit, surfaceLibre…)
                 2. appelle AbstractPlantationRepository.sauvegarder(plantation)
      │
      ▼
[Domain]        L'entité Plantation porte la logique ; le repository est une interface
      │
      ▼
[Infrastructure] PlantationRepositoryImpl mappe l'entité → ligne drift → INSERT SQLite
      │
      ▼
[Application]   Le Notifier met à jour son état (stream drift réactif)
      │
      ▼
[Presentation]  L'UI se reconstruit (snackbar succès + plantation visible)
```

## 6. Injection de dépendances (Riverpod)

- Les **interfaces** du Domain sont fournies via des `Provider` Riverpod, dont
  l'implémentation pointe vers l'Infrastructure.
- En **test**, on **override** ces providers avec des mocks (`mocktail`), sans
  toucher au reste du code → testabilité maximale.
- Exemple de chaîne : `potagerRepositoryProvider` (Provider d'interface) →
  retourne `PotagerRepositoryImpl(database)` en prod, ou un mock en test.

## 7. Avantages concrets

- **Testabilité** : le Domain se teste sans Flutter ni BDD (objectif 80% sur `domain/`).
- **Remplaçabilité** : changer drift, l'API météo ou le mécanisme de sync n'impacte
  que l'Infrastructure.
- **Lisibilité** : chaque responsabilité a un emplacement unique et évident.
