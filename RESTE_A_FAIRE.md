# Reste à faire — Pot'à Gérer

> Résumé étendu de ce qu'il reste à faire, **hors design** (dark mode, Phosphor
> Icons) et **hors revue de contenu** (relecture éditoriale du glossaire,
> éditorial des familles/bioagresseurs). Généré le 2026-07-07 à partir de
> [`docs/15-elements-differes.md`](docs/15-elements-differes.md) et
> [`docs/13-roadmap-et-versioning.md`](docs/13-roadmap-et-versioning.md).
> Mis à jour le 2026-07-08 après livraison des **fiches plantes perso** et de la
> **CI analyze+test** (le multi-potager, les équipements, la version dynamique,
> les liens externes et l'i18n `en` UI étant déjà livrés).

## 1. Fonctionnalités « build-then-gate » (ADR-0009 §9)

Réservées par palier mais sans UI ni donnée :

- ~~**Multi-potager** (inter+)~~ ✅ **fait** : sélecteur de potager actif
  (menu ⋮ Potager) + action « Ajouter un potager » + réglages (F2)
- ~~**Équipements/outils** (inter+) : toute l'UI manque~~ ✅ **Livré**
  (liste + formulaire + section détail de zone, gaté `acces.equipements`,
  entrée menu ⋮ Potager) — voir docs/15 §9
- ~~**Fiches plantes perso** (expert) : toute l'UI de création/édition~~
  ✅ **Livré** : couche complète (domain→infra→UI), YAML = source de vérité,
  fusion au catalogue (surcharge sur collision d'id, ADR-0002 A6), **tag `Perso`**
  sur les cartes + fiche, dupliquer/éditer depuis le catalogue, gaté
  `acces.fichesPerso` — voir docs/15 §9
- ~~**Rotation avancée** (expert) : UI de rotation~~ ✅ **Livré** (Lots 1–4) :
  **domain** — enum `GroupeCultural`, VO `PrecedentCultural` + normaliseur,
  `precedentsFavorables/Defavorables` sur `FichePlante` ; **infra** — mapper +
  intégrité référentielle des précédents-familles ; **moteur** —
  `EvaluationRotation` (verdict favorable/défavorable/neutre + raisons
  explicites) ; **UI** — section « Rotation » gatée `acces.rotationAvancee`
  dans le détail de zone (`syntheseRotationZoneProvider` : historique récent,
  familles bloquées par délai de retour, opportunités azote), tests en //.
  - **⚠️ i18n restant (suivi)** : les **noms de famille** s'affichent en FR via
    `FamilleBotanique.nomsLocalises` (résolu dans le provider), mais c'est figé
    en `'fr'` → le rendre **locale-aware**. Les **libellés de groupe**
    (« Légumineuses », « Engrais verts ») + descriptions existent désormais en
    ARB (`glossaireValGroupeCultural*`, affichés sur la page glossaire
    `rotation-cultures`) ; reste à exposer les précédents groupes/slugs sur une
    surface UI (ex. fiche plante) le jour venu, en réutilisant ces libellés.
  - **Entrée glossaire `rotation-cultures`** enrichie (définition détaillée
    pourquoi + implémentation, 7 conseils, valeurs `GroupeCultural`, « Voir
    aussi »). Traduction `en` du glossaire : différée (cf. §7).
- **Besoins en eau détaillés** (expert) : il faut d'abord enrichir
  `BesoinsCulture` (fréquence/quantité, pas juste le terme grossier) →
  **chantier à venir**
- **Lot 4 ADR-0009** : mini-tutos par palier + teaser de montée (modèle de
  contenu partagé avec le glossaire — mais l'implémentation du mécanisme, pas
  le texte, reste du dev)

## 2. Éléments différés docs/15 — non-design

- **Navigation** : sous-routes go_router restantes (détail tâche, fiche
  plante en route dédiée)
- **Accueil** : écran notifications + menu ⋮ (actions d'en-tête), lien « voir
  les tâches » → Calendrier
- **Potager** : FAB de création (potager/zone/plantation), métadonnées de
  zone (besoin eau/dimensions littérales) si on veut les champs réels
- **Catalogue** : favoris (notion inexistante), gabarit/hauteur de plante
  (champ manquant), vue Réseau — rendu canvas (perf, différé)
- **Calendrier** : rien de fonctionnel majeur restant (tout ✅)
- **Paramètres** :
  - Catégorie « Transparence des données » (stats tailles DB + journal
    d'accès — n'existe pas)
  - Toggle « récupération météo auto » (champ manquant)
  - Toggle « Ne pas déranger » (champs domaine présents, UI absente)
  - ~~**Version dynamique** (`package_info_plus`), **liens externes**
    (`url_launcher`), **i18n `en`**~~ ✅ **livrés** : version lue au runtime,
    liens externes fonctionnels, ARB `en` + pilotage `locale` (glossaire non
    traduit, cf. §7 relecture éditoriale différée)
  - Appairage d'appareils (réseau local, à concevoir)

## 3. Distribution / packaging (docs/15 §7) — groupé « juste avant release »

- ~~CI/CD GitHub Actions (aucun pipeline)~~ ✅ **partiel** : pipeline
  `.github/workflows/ci.yml` sur push/PR `main` (pub get → gen-l10n → codegen →
  `flutter analyze` + `flutter test`). **Reste le job de build/signature d'APK
  release** — couplé au keystore ci-dessous, donc reporté juste avant release
  (le commit CI le note : « signing release reste un chantier séparé »)
- Signing release réel (keystore + `signingConfigs.release` + `key.properties`
  hors VCS, actuellement clé **debug**) — pré-release
- Icône & splash screen — pré-release
- iOS / desktop packaging (Linux AppImage/Flatpak, .exe, .dmg, .ipa) — alpha =
  Android seul pour l'instant
- ⚠️ **Vérification développeur Android** (Google, rollout global 2027) —
  démarche d'identité du **dev**, non-code, à décider avant la sortie grand
  public (docs/15 §7)

## 4. Backlog UX (docs/15 §8) — restes non-design

- ~~**F2** (multi-potager dans réglages)~~ ✅ **fait**
- **§11** : (a) typer/renseigner le contenu éditorial des paires
  d'associations (mi-contenu, mi-dev) ; (c) brancher un `ResolveurFamille`
  complet pour activer les suggestions répulsion/piège (aujourd'hui `null`)

## 5. V1.1 (docs/13 §2)

- Entité `Traitement` (interventions naturelles, YAML dédié)
- Photos (observations, récoltes) — reporté pour ne pas alourdir sync/stockage
- Réconciliation de l'enum `TypeEquipement`
- Seuils météo configurables (gel/canicule, figés en V1)
- Déduction du type de sol (API géologique/heuristique)
- **Sensibilité météo par plante** : nouveaux champs YAML (tolérance
  gel/chaleur/sécheresse/excès d'eau) + parser/validator/mapper + évaluateur
  d'alertes plante-par-plante (actuellement générique)
- **Conformité réglementaire par territoire** (espèces invasives/interdites) :
  bloquée tant qu'une **source officielle fiable par territoire** n'est pas
  identifiée (UE/national/régional) ; implique modèle « territoire », dataset
  embarqué, filtre dans `RecommanderPlantes`, alerte éducative unique

## 6. V2 (docs/13 §3) — hors scope proche

- Communauté P2P locale
- Calendrier lunaire (déjà un placeholder « désactivé »)
- Vue graphique des relations façon Obsidian (au-delà de la vue Réseau
  actuelle)
- Vue « plan du potager » spatial (x/y des parcelles, préparé en BDD mais pas
  exploité)
- Sync bidirectionnelle avec une base communautaire GitHub

## En résumé — le plus proche/actionnable

Livré depuis la dernière révision : ~~Multi-potager + F2~~ ✅ · ~~Équipements~~ ✅ ·
~~Version dynamique + liens externes + i18n `en` UI~~ ✅ · ~~CI analyze+test~~ ✅ ·
~~**Fiches plantes perso**~~ ✅ (2026-07-08).

Côté **features V1**, il ne reste vraiment que deux chantiers de code
substantiels — à traiter chacun dans sa propre conversation :

1. **Rotation avancée** (expert) : donnée présente sur la fiche, aucun écran.
2. **Besoins en eau détaillés** (expert) : enrichir d'abord `BesoinsCulture`
   (fréquence/quantité), puis l'UI.
   (+ Lot 4 ADR-0009 : mécanisme mini-tutos/teaser.)

Tout le reste se range en :

- **Pré-release / distribution** (groupé avant la sortie) : keystore release +
  job CI de build/signature, icône & splash, packaging desktop/iOS, relecture
  éditoriale du glossaire puis sa traduction `en`, vérification dev Android.
- **Finitions légères** (docs/15 §2) : toggles paramètres (transparence des
  données, météo auto, « Ne pas déranger »), sous-routes go_router restantes,
  écran notifications d'accueil, `ResolveurFamille` complet (§11).
- **V1.1 / V2** : `Traitement`, photos, sensibilité météo par plante,
  conformité territoriale, communauté P2P, plan spatial, calendrier lunaire.
