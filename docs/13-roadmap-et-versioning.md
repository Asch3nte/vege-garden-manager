# 13 — Roadmap & versioning

> Source : CAHIER §7 + annotations « V1.1 / V2 » disséminées dans le document.
> Les arbitrages de périmètre sont consignés dans
> [decisions/0001-arbitrages-de-coherence.md](decisions/0001-arbitrages-de-coherence.md).

## 1. V1 — scope validé

Toutes les fonctionnalités décrites dans [01](01-vision-et-perimetre.md) et
[02](02-fonctionnalites-v1.md) :

- Gestion multi-potagers (zones, plantations, équipements).
- Recommandations intelligentes, associations & compagnonnage, rotation.
- Météo Open-Meteo + arrosage intelligent + alertes.
- Calendrier personnalisé, rappels, tâches.
- Catalogue de fiches YAML + **éditeur de fiches perso** (création locale +
  export YAML + soumission GitHub via URL).
- Post-récolte (conservation, recettes).
- Export/import des données, **mode sombre**, architecture multilingue.
- Aide contextuelle in-app.

## 2. V1.1 — incréments rapprochés

| Fonctionnalité                      | Note                                                                                                                      |
|-------------------------------------|---------------------------------------------------------------------------------------------------------------------------|
| Entité `Traitement`                 | Interventions naturelles (purins, paillage) chargées depuis YAML dédié ; en V1, consignées via `NoteObservation`/`Tache`  |
| `NoteObservation` enrichie / photos | Photos d'observations et de récoltes (reportées de V1 pour ne pas alourdir sync & stockage)                               |
| Seuils météo configurables          | `risque_gel`/`risque_canicule` paramétrables (figés en V1)                                                                |
| Déduction du type de sol            | Depuis API géologique / heuristique climat                                                                                |

## 3. V2 — évolutions prévues (opt-in, désactivées par défaut)

| Fonctionnalité                            | Note                                                                                          |
|-------------------------------------------|-----------------------------------------------------------------------------------------------|
| **Communauté P2P locale**                 | Échanges de semis, conseils, entraide ; aucune identité réelle ; opt-in strict                |
| **Calendrier lunaire**                    | Désactivé par défaut                                                                          |
| **Vue graphique des relations**           | Graph view interactif (type Obsidian), critère d'arête sélectionnable ; UX complexe, reportée |
| Vue « plan du potager »                   | Exploite `position_x/y` des parcelles (déjà préparées en BDD)                                 |
| Sync bidirectionnelle base communautaire  | Après acceptation d'une PR GitHub                                                             |

## 4. Hors scope total

- **Détection automatique de maladies / ravageurs** (IA/photo) : la philosophie
  reste **manuelle et low-tech** — l'utilisateur identifie lui-même, l'app aide
  via le catalogue (solutions par problème).

## 5. Versioning & GitHub

- Repository public, licence **MIT**.
- Branches : `main` (stable) + `develop` + feature branches.
- **Conventional Commits** (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`,
  `chore:`…).
- README maintenu à jour.
- Fiches YAML contributives : format diffable, soumission via PR (cf.
  [CONTRIBUTING.md](../CONTRIBUTING.md)).
- Décisions structurantes consignées en **ADR** dans [decisions/](decisions/).

## 6. Ordre de développement suggéré

1. `flutter create` + `pubspec.yaml` (dépendances validées).
2. **Domain** : Value Objects (`Surface`, `Localisation`, `Periode`…) puis
   entités, **avec tests unitaires en parallèle** (cible 80%).
3. **Infrastructure** : schéma drift + mappers + chargeur YAML + client Open-Meteo.
4. **Application** : use cases + Notifiers Riverpod.
5. **Presentation** : design system → écrans par panel (Accueil → Potager →
   Catalogue → Calendrier → Plus).
6. CI/CD GitHub Actions, puis packaging multiplateforme.
