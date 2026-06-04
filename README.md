<div align="center">

# 🌱 Pot'à Gérer

**L'assistant de potager 100% local, open source et respectueux de la vie privée.**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
![Statut](https://img.shields.io/badge/statut-en%20développement-orange)
![Flutter](https://img.shields.io/badge/Flutter-Dart-02569B?logo=flutter)

</div>

---

## Qu'est-ce que c'est ?

**Pot'à Gérer** est une application multiplateforme (Linux · Windows · macOS ·
Android · iOS) qui aide à gérer un potager selon une approche permaculturelle —
**sans compte, sans cloud, sans télémétrie**. Toutes les données restent sur
l'appareil de l'utilisateur.

Elle est à la fois :

- 🧭 **un assistant pratique** — quoi planter, quand, où, comment ;
- 📚 **un outil éducatif** — le *pourquoi* derrière chaque recommandation ;
- 🔎 **une base de connaissances explorable** — ~200 fiches plantes, recherche, filtres, calendrier ;
- 🌿 **respectueux de la nature** — permaculture, zéro chimique ;
- 🔒 **respectueux de l'utilisateur** — 100% local, tout opt-out possible.

## Fonctionnalités clés (V1)

- Gestion multi-potagers : zones (pleine terre, bacs, balcon, serre…), plantations, équipements
- Recommandations intelligentes (climat, saison, associations, place disponible)
- Arrosage intelligent croisé avec la météo (Open-Meteo, sans clé API)
- Calendrier personnalisé, rappels et alertes (gel, canicule, semis, récolte)
- Rotation des cultures avec historique
- Suggestions post-récolte (conservation, recettes)
- Catalogue de fiches plantes contributif (format YAML diffable)
- Export des données (JSON/CSV), mode sombre, architecture multilingue

> Communauté P2P locale et calendrier lunaire : prévus en **V2** (opt-in, désactivés par défaut).

## Architecture & documentation

Le projet suit une **Clean Architecture à 4 couches** (Presentation → Application →
Domain ← Infrastructure). Toute la spécification est dans **[`docs/`](docs/)** :

- 🏛️ [Architecture en couches](docs/04-architecture-en-couches.md)
- 🧩 [Modèle de domaine](docs/05-modele-de-domaine.md) · 🗄️ [Schéma BDD SQLite](docs/06-modele-de-donnees-sqlite.md)
- 🌿 [Base de connaissances YAML](docs/07-base-de-connaissances-yaml.md)
- 🎨 [Design system](docs/08-design-system.md) · 🧭 [UX & navigation](docs/09-ux-et-navigation.md)

👉 Point d'entrée : **[docs/README.md](docs/README.md)**

## Stack technique

Flutter (Dart) · SQLite via **drift** · **Riverpod** · **go_router** ·
Open-Meteo · `flutter_local_notifications` · `geolocator` · fiches **YAML** ·
i18n (`intl`) · tests `flutter_test` + `mocktail`.
Détail : [docs/03-stack-technique.md](docs/03-stack-technique.md).

## Démarrage (développement)

> ⚠️ Le squelette Flutter (`pubspec.yaml`, dossiers de plateforme) n'est pas
> encore généré. L'ossature `lib/`, `assets/`, `test/` et la documentation sont
> en place.

```bash
# Générer les fichiers de plateforme sur l'ossature existante
flutter create --org com.potagerer --project-name pot_a_gerer .

# Récupérer les dépendances puis lancer
flutter pub get
flutter run
```

## Contribuer

Les contributions sont les bienvenues, en particulier les **fiches plantes** !
Voir [CONTRIBUTING.md](CONTRIBUTING.md).

## Licence

[MIT](LICENSE) © Pot'à Gérer contributors.
