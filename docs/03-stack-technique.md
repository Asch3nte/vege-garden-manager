# 03 — Stack technique

> Source : CAHIER §2. Choix **validés**. Toute autre dépendance doit être
> validée explicitement avant introduction.

## 1. Décisions validées

| Composant | Choix | Justification |
|---------------------|-------------------------------------------|-------------------------------------------------------------------|
| Langage | **Dart** | POO native, null safety, compilation native |
| Framework | **Flutter** | Multiplateforme unifié (PC + mobile), un seul codebase |
| BDD locale | **SQLite via `drift`** | Requêtes typées, migrations, testable |
| Fiches plantes | **YAML embarqué** | Lisible, contributif, diffable sur Git |
| Météo | **Open-Meteo** via `http` | Gratuit, sans clé API, sans compte |
| Gestion d'état | **Riverpod** | Moderne, testable, bien documenté |
| Navigation | **`go_router`** | Déclaratif, deep linking |
| Notifications | **`flutter_local_notifications`** | 100% local |
| Géolocalisation | **`geolocator`** | Opt-out possible |
| i18n | **`intl`** + ARB (+ YAML pour les fiches) | Architecture multilingue |
| IDs | **`uuid`** (v4) | Compatibilité sync multi-appareils |
| Parsing YAML | **`yaml`** | Chargement des fiches plantes |
| Sync locale | Sockets / **mDNS** sur WiFi | Réseau local uniquement, aucun cloud (détail à l'implémentation) |
| Tests | **`flutter_test`** + **`mocktail`** | Unit + widget + integration |
| Scripts utilitaires | Dart | Validation YAML, génération de fiches |
| IDE | VS Code + extensions Dart/Flutter | Gratuit, léger, hot reload |

## 2. APIs externes autorisées

- ✅ **Open-Meteo** uniquement (gratuit, sans compte, sans clé API).
  - *Archive API* : données observées passées.
  - *Forecast API* : prévisions (jusqu'à 16 jours).
- ❌ Aucune autre API externe sans **validation explicite**.

## 3. Synchronisation inter-appareils

- Via **réseau local WiFi uniquement** — aucun cloud.
- Protocole : Sockets / mDNS (à détailler à l'implémentation).
- Transparent pour l'utilisateur, **opt-out disponible** (désactivé par défaut).

## 4. Packages — statut

> ⚠️ Cette liste reflète les choix de spec. Les versions seront figées dans
> `pubspec.yaml` lors de l'initialisation. Tout ajout hors de cette liste =
> validation requise (contrainte absolue n°6).

**Validés** : `drift`, `sqlite3_flutter_libs`, `riverpod` / `flutter_riverpod`,
`go_router`, `http`, `flutter_local_notifications`, `geolocator`, `intl`,
`uuid`, `yaml`, `path_provider`, `path`.

**Dev** : `flutter_test`, `mocktail`, `drift_dev`, `build_runner`,
`flutter_lints` (ou `very_good_analysis`).

**Validés** : `freezed` / `json_serializable` (immutabilité &
sérialisation), `phosphor_flutter` (iconographie — cf.
[08-design-system.md](08-design-system.md)), `flutter_markdown` (doc d'aide
in-app — cf. [10-parcours-utilisateur.md](10-parcours-utilisateur.md)).

## 5. Environnement de développement

- Flutter **3.44.1** sur **Fedora 43**.
- Android SDK **36.1.0**.
- VS Code + extensions Dart / Flutter / Error Lens / GitLens / YAML.
