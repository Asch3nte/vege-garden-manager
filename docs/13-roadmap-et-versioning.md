# 13 — Roadmap & versioning

> Source : CAHIER §7 + annotations « V1.1 / V2 » disséminées dans le document.

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

| Fonctionnalité | Note |
|-------------------------------------|---------------------------------------------------------------------------------------------------------------------------|
| Entité `Traitement` | Interventions naturelles ponctuelles (purins/extraits, `thePurin`) chargées depuis YAML dédié ; en V1, consignées via `Observation`/`Tache` |
| Photos (`Observation`, récoltes) | Photos d'observations et de récoltes (reportées de V1 pour ne pas alourdir sync & stockage) |
| Réconciliation `TypeEquipement` | Revue fonctionnelle fine de l'enum équipements |
| Seuils météo configurables | `risque_gel`/`risque_canicule` paramétrables (figés en V1) |
| Déduction du type de sol | Depuis API géologique / heuristique climat |
| **Sensibilité météo par plante** (fiche) | Alertes gel/canicule/forte-pluie ciblées par plante — voir §2.1 ci-dessous |
| **Arrosage : phase sensible → urgence** | Coupler `phasesSensibles` (livré, affichage seul) × stade de croissance pour moduler l'urgence d'arrosage — [ADR-0018](decisions/0018-stade-sensible-urgence-arrosage.md) (**Proposé**, cadrage figé). Prérequis : corpus renseigné + recalibration moteur |

### 2.1 Extension des fiches pour des alertes météo ciblées (reporté de V1)

En V1, l'alerte météo (gel / canicule / forte pluie) est **générique** : elle vise
**toutes les plantations en place** du potager concerné, sans distinguer les plantes,
car **aucune donnée structurée de sensibilité** n'existe encore dans les fiches (seule
la prose `erreurs_frequentes` la mentionne). Pour un calcul **plante par plante**, il
faudra enrichir le modèle. Recommandations détaillées (à débattre avant implémentation) :

**Champs YAML à ajouter sous `besoins:`** (puis mapper → `BesoinsCulture`) :
- `temperature_min_tolerance` (°C) — seuil de **dégât par le froid** (distinct de
  `temperature_min_germination`). Une plantation est « concernée par le gel » si
  `prevision.tempMin <= temperature_min_tolerance`. (Ex. tomate ~ 0–2 °C, salade ~ −5 °C.)
- `temperature_max_tolerance` (°C) — seuil de **stress thermique** → filtre canicule
  (`prevision.tempMax >= temperature_max_tolerance`).
- `tolerance_secheresse` (enum `faible|moyenne|forte`) — affine l'**arrosage** (lot 4),
  pas seulement les alertes.
- `sensibilite_exces_eau` (enum `faible|moyenne|forte`) — filtre l'alerte **forte pluie**
  (asphyxie racinaire, éclatement des fruits).
- Alternative plus simple si on ne veut pas de °C : `sensibilite_gel`
  (`aucune|legere|forte`) + `sensibilite_chaleur` (idem), tables qualitatives.

**Champs déjà présents au schéma mais NON mappés** (gain rapide, fidèle au schéma) :
- `besoins.temperature_min_germination` et `besoins.temperature_optimale` : à lire dans
  le parser/validator/mapper et exposer sur `BesoinsCulture`. Utilisables comme **proxy
  faible** en attendant les seuils de tolérance dédiés.

**Raffinements possibles (plus lourds) :**
- **Sensibilité dépendante du stade** : un semis/jeune plant est plus gélif qu'un pied
  établi → nécessiterait un modèle de stade (date plantation + cycle) croisé avec la
  tolérance. À évaluer.
- **Prise en compte des équipements de protection** : un `voileHivernage`/`tunnel` en
  place sur la parcelle relève le seuil effectif de gel (lié au calibrage `EffetEquipement`).

**Travaux d'implémentation impliqués :** schéma `_schema/fiche_plante_schema.yaml`,
`CatalogueYamlParser` + `FichePlanteValidator` + `FichePlanteMapper`, VO `BesoinsCulture`,
valeurs de la fiche golden `tomate.yaml`, doc `07-base-de-connaissances-yaml.md`, puis
l'évaluateur d'alertes (filtrage par plante au lieu de générique).

### 2.2 Conformité réglementaire des plantes par territoire (espèces invasives / interdites)

> **Prérequis bloquant** : disposer d'une **source officielle et fiable** par territoire.
> Tant que cette source n'est pas identifiée et intégrable hors-ligne, la fonctionnalité
> reste reportée. Cible V1.1, possiblement V2 selon la disponibilité des données.

**Objectif** : le moteur (recommandations + saisie de plantation) doit tenir compte des
**plantes interdites ou déconseillées sur le territoire de l'utilisateur** — espèces
**invasives** (ex. réglementées au niveau de l'UE ou national/régional) ou **non endémiques**.

**Deux comportements attendus :**
1. **Filtrer les recommandations** : `RecommanderPlantes` ne doit jamais proposer une plante
   interdite/invasive sur le territoire de l'utilisateur (exclusion stricte, ou rétrogradation
   avec avertissement selon le statut).
2. **Alerte éducative unique** : si l'utilisateur saisit lui-même une plante interdite/invasive
   sur son territoire, afficher **une notification/alerte pédagogique ponctuelle** (une seule
   fois par espèce) expliquant le statut, le risque écologique et la source officielle —
   sans bloquer (cohérent avec la philosophie : informer, pas contraindre).

**Sources de données (à valider, officielles et datées) :**
- **UE** : Règlement (UE) n°1143/2014 sur les espèces exotiques envahissantes (liste de
  l'Union, mise à jour périodiquement).
- **National / régional** (ex. Belgique : niveau fédéral + Régions wallonne / flamande /
  bruxelloise ; France : arrêtés ministériels ; etc.). La granularité régionale peut être
  nécessaire.
- Critère : source **officielle, versionnée, citable, intégrable hors-ligne** (comme le
  catalogue YAML — aucune API live, privacy by design). Le fichier `Sources_Referenciel_Botanique.odt`
  (hors repo) peut servir de point de départ à la recherche.

**Implications de modélisation (n'existent PAS aujourd'hui) :**
- **Notion de territoire** (pays + éventuellement région) à dériver de la position d'onboarding
  (lié à la dérivation position → défauts). Aucune donnée pays/région dans le modèle actuel
  (`Localisation` ne porte que lat/lng/ville).
- **Jeu de données embarqué** territoire → liste d'espèces (par **`nom_scientifique`**, déjà
  présent sur la fiche) avec un **statut** (`invasive_ue` | `invasive_nationale` |
  `interdite` | `non_endemique` | `deconseillee`), un **message éducatif i18n** et un **lien
  source + date**. Format diffable/contributif (comme les fiches), versionné.
- **Suivi de l'alerte « vue »** (une fois par espèce/territoire) — persistance d'un drapeau
  (préférences ou table dédiée), réinitialisable.
- **Avertissement légal / disclaimer** : afficher la source et sa date ; les listes évoluent ;
  l'app informe mais ne se substitue pas à la réglementation officielle.

**Travaux impliqués :** recherche & validation de source ; modèle territoire + dérivation
depuis la position ; nouveau dataset embarqué + parser/validator ; intégration dans
`RecommanderPlantes` (filtre) ; déclenchement de l'alerte éducative à la création de plantation
(use case `CreerPlantation` / `DetecterPlanteNonConforme`) ; i18n des messages.

## 3. V2 — évolutions prévues (opt-in, désactivées par défaut)

| Fonctionnalité | Note |
|-------------------------------------------|-----------------------------------------------------------------------------------------------|
| **Communauté P2P locale** | Échanges de semis, conseils, entraide ; aucune identité réelle ; opt-in strict |
| **Calendrier lunaire** | Désactivé par défaut |
| **Vue graphique des relations** | Graph view interactif (type Obsidian), critère d'arête sélectionnable ; UX complexe, reportée |
| Vue « plan du potager » | Exploite `position_x/y` des parcelles (déjà préparées en BDD) |
| Sync bidirectionnelle base communautaire | Après acceptation d'une PR GitHub |

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
