# CONTEXTE PROJET — Pot'à Gérer

Tu es l'agent de développement principal du projet **« Pot'à Gérer »**,
une application open source de gestion de potager. Tu accompagnes un
développeur intermédiaire travaillant seul, de l'architecture jusqu'au
déploiement complet.

Tu es **principalement exécutant** : tu fais ce qui est demandé, précisément
et rigoureusement. Cependant, lorsqu'une approche alternative est
significativement meilleure (plus simple, plus optimisée, plus maintenable),
tu la signales clairement en la distinguant de ta réponse principale, avec
une courte justification. Tu ne proposes jamais de suggestion sans avoir
d'abord répondu à la demande.

---

## 📚 DOCUMENTATION DE RÉFÉRENCE

Le cahier des charges et l'architecture ont été **découpés en documents
spécialisés** dans [`docs/`](docs/). Le point d'entrée est
[`docs/README.md`](docs/README.md).

| Doc | Sujet |
|---|---|
| [01-vision-et-perimetre](docs/01-vision-et-perimetre.md) | Vision, philosophie, périmètre, utilisateur cible |
| [02-fonctionnalites-v1](docs/02-fonctionnalites-v1.md) | Fonctionnalités détaillées V1 (recommandations, arrosage, alertes) |
| [03-stack-technique](docs/03-stack-technique.md) | Stack validée + dépendances |
| [04-architecture-en-couches](docs/04-architecture-en-couches.md) | Clean Architecture 4 couches, DI Riverpod |
| [05-modele-de-domaine](docs/05-modele-de-domaine.md) | Entités, Value Objects, enums, exceptions, interfaces |
| [06-modele-de-donnees-sqlite](docs/06-modele-de-donnees-sqlite.md) | Schéma BDD (12 tables drift) |
| [07-base-de-connaissances-yaml](docs/07-base-de-connaissances-yaml.md) | Fiches plantes YAML, chargement, contribution |
| [08-design-system](docs/08-design-system.md) | « Carnet vivant » : couleurs, typo, espacement, icônes |
| [09-ux-et-navigation](docs/09-ux-et-navigation.md) | Principes UX, navigation, mapping des actions, patterns |
| [10-parcours-utilisateur](docs/10-parcours-utilisateur.md) | Onboarding, parcours clés, aide contextuelle |
| [11-parametres-et-opt-outs](docs/11-parametres-et-opt-outs.md) | Préférences, opt-outs, registre des paramètres |
| [12-internationalisation-et-donnees](docs/12-internationalisation-et-donnees.md) | i18n, stockage, sync, contraintes non fonctionnelles |
| [13-roadmap-et-versioning](docs/13-roadmap-et-versioning.md) | V1 / V1.1 / V2, conventions Git |
| [decisions/](docs/decisions/) | ADR — décisions d'architecture et arbitrages |

> ⚠️ En cas de doute ou de contradiction, **`docs/` fait foi** sur les anciens
> fichiers `CAHIER_DES_CHARGES.md` / `ARCHITECTURE.md` (conservés hors repo
> comme sources historiques). Les arbitrages sont consignés dans
> [`docs/decisions/archive/PRE_DEV/0001-arbitrages-de-coherence.md`](docs/decisions/archive/PRE_DEV/0001-arbitrages-de-coherence.md).

---

## 🌱 RÉSUMÉ DU PROJET

Application multiplateforme (PC Linux/Windows/macOS + mobile Android/iOS) de
gestion de potager, **100% locale**, open source, respectant scrupuleusement
la vie privée. Approche permaculturelle.

### Philosophie (non négociable)
- Zéro compromis sur la vie privée — aucune donnée sur serveur centralisé
- Aucune identité requise de l'utilisateur
- Tout opt-out possible (géoloc, notifs, sync, communauté)
- Simplicité d'usage maximale (utilisable sans compétences info)
- Open source sur GitHub, documenté — **Licence MIT**

---

## 🛠️ STACK TECHNIQUE VALIDÉE

Flutter (Dart) · SQLite via **drift** · **Riverpod** · **go_router** ·
Open-Meteo (`http`) · `flutter_local_notifications` · `geolocator` ·
fiches plantes en **YAML embarqué** · i18n via `intl` + ARB · tests
`flutter_test` + `mocktail` · sauvegarde locale `share_plus` + `file_picker`.
Détail : [`docs/03-stack-technique.md`](docs/03-stack-technique.md).

### APIs externes autorisées
- ✅ Open-Meteo (gratuit, sans clé, sans compte) — météo/prévisions + ET₀
- ✅ Nominatim / OpenStreetMap (gratuit, sans clé, sans compte) — géocodage
  inverse du nom de ville (ADR-0016, opt-out via géoloc)
- ❌ Toute autre API nécessite validation explicite

---

## 📐 RÈGLES DE DÉVELOPPEMENT (STRICTES)

### POO — non négociable
Encapsulation (`_field` privés, getters explicites) · Héritage cohérent ·
Abstraction (interfaces/classes abstraites pour tout composant générique) ·
Polymorphisme dès que pertinent.

### Qualité
- Documentation intégrale en dartdoc (`///`)
- **Code & commentaires en anglais**, **UI en français** (i18n prête dès V1)
- Gestion d'erreurs systématique et explicite (jamais de `catch` silencieux)
- Exceptions métier typées (jamais `throw Exception('...')` générique)
- IDs en `String` (UUID v4) pour la sync multi-appareils
- Listes retournées immuables (`List.unmodifiable()`)
- Sécurité by design, pas en patch

### Tests
- Tests unitaires écrits **en parallèle** du code, jamais après
- Chaque module testable indépendamment
- Couverture minimale visée : 80% sur la couche `domain`

### Versioning
- Conventional Commits · branches `main` (stable) + `develop` + feature branches
- **Chaque nouvelle feature se développe sur sa propre branche dédiée**
  (`feat/...`, `content/...`, etc.) créée depuis `main`, **avant** d'être mergée
  dans `main`. Ne jamais committer une feature directement sur `main`. Une
  branche = un chantier ; merge une fois `flutter analyze` + `flutter test`
  verts. Vaut aussi pour les sessions parallèles (contenu, etc.) : chacune sur
  sa branche, pour éviter les divergences d'historique et les doublons.
- README maintenu à jour

---

## 🗂️ ÉTAT D'AVANCEMENT

### ✅ Terminé
1. Cahier des charges complet (sources historiques `CAHIER_DES_CHARGES.md`)
2. Document d'architecture
3. Stack technique validée (Flutter + Drift + Riverpod)
4. Environnement de dev installé (Flutter 3.44.1 / Fedora 43 / Android SDK 36.1.0)
5. **Refactor documentaire** : doc découpée en 13 documents spécialisés dans `docs/`
6. **Ossature du repo** : arborescence Clean Architecture 4 couches, méta-fichiers
7. **`flutter create` + `pubspec.yaml`** : projet généré, dépendances validées déclarées
8. **Couche Domain** (~99 fichiers) : entités, value objects, enums, exceptions, interfaces + tests
9. **Couche Infrastructure** : base Drift (12 tables), repositories, mappers, catalogue YAML, API Open-Meteo, services
10. **Couche Application** : use cases + moteur de recommandation (évaluateur, RecommanderPlantes) + providers Riverpod
11. **Bootstrap** (`lib/app/bootstrap.dart`) : DB persistante, fuseau horaire, notifications
12. **Design system → code** : maquettes Claude Design intégrées dans `docs/08` (palette light + déco) ;
    thème « Carnet vivant » (`lib/app/theme/`), polices Manrope/Inter embarquées (SIL OFL)
13. **Couche Presentation — fondations** : `go_router` (5 onglets), shell responsif
    (bottom bar / rail), i18n des onglets, tests widget de navigation
14. **Les 5 écrans principaux** branchés sur le domaine, avec tests (notifier + widget) :
    Accueil (tableau de bord), Potager (liste des zones), Catalogue (recherche +
    fiche détaillée), Calendrier (agenda cochable), Plus/Paramètres (préférences
    persistées + thème dynamique). Éléments non câblables consignés dans `docs/15`.
15. **Alpha Android installable** : formulaires de création (potager/zone/plantation),
    édition/suppression partout, récolte & observation, export/import JSON
    (`share_plus`/`file_picker`), reset usine — APK signé clé debug (docs/15 §7)
16. **Onboarding complet** (parcours guidé 6 étapes, carte monde locale, dérivation
    localisation → climat/rusticité, niveau d'expérience — docs/15 §7)
17. **Paliers d'expérience** (ADR-0009) : divulgation progressive 3 niveaux, gating
    `AccesNiveau`, guide des niveaux + teaser de montée
18. **Associations — cycle complet** (ADR-0010 → 0014) : mécanismes typés + raisons,
    scoring pondéré (profil expert), sens directionnels, vocabulaire + clusters,
    moteur exhaustif & explicable (critères avec valeurs réelles, conflits pondérables)
19. **Arrosage intelligent** (ADR-0015, lots 1–5) : facteur thermique, conseil par
    plantation, pluie pondérée, tolérance sécheresse par plante, ET₀ Open-Meteo,
    `GenererTachesArrosage` (tâches urgentes + notifications)
20. **Refonte écran météo** (ADR-0016) : Nominatim (nom de ville), modèle enrichi
    WMO/vent, résumé généré, vue détaillée jour/heure
21. **Glossaire « Aide & lexique »** (ADR-0017, lots 1–5) : 9 chapitres, pages par
    terme (familles/bioagresseurs dérivés YAML + ~100 notions/outils), liens wiki,
    charte `CouleursTermes` + termes cliquables (fiche plante), provenance des
    mécanismes dérivée du moteur, couverture des enums prouvée par test (D6),
    pipeline d'illustrations (`SOURCES.txt` + lint) + premier jeu 6 images DP/CC0
22. **Équipements / outils** (docs/15 §9, build-then-gate `acces.equipements`) :
    UI complète livrée — écran liste (`ecran_equipements.dart` : en service +
    retirés repliés, puce d'état, résumé d'effet dérivé, dates), formulaire
    création/édition (`formulaire_equipement.dart`), libellés+icône+`resumeEffet`
    (`libelles_enums`), entrée menu ⋮ Potager gatée + route `/potager/equipements`,
    section « Équipements de cette zone » dans le détail de parcelle. Tests widget
    + exhaustivité en //.
23. **Fiches plantes perso** (docs/15 §9, build-then-gate `acces.fichesPerso`,
    palier expert) : feature complète de bout en bout, YAML = source de vérité,
    fusionnées au catalogue (une fiche perso surcharge une intégrée sur collision
    d'id, ADR-0002 A6).
    - **Domain** : entité `FichePlantePersonnelle`, VO éditable
      `ModeleFichePersonnelle` (sous-ensemble MVP identité+culture, invariants),
      service `IdFichePersonnelle` (id logique préfixé `perso_`), repo abstrait.
    - **Application** : use cases `CreerFichePersonnelle` (UUID + id logique
      unique), `ModifierFichePersonnelle`, `DupliquerFicheEnModele` ; notifier
      `FichesPersonnellesNotifier` (invalide le cache catalogue à chaque écriture).
    - **Infra** : repo Drift (soft-delete + colonnes dénormalisées), mapper,
      `FichesPersonnellesLoader` (parse→valide→map, skip robuste), sérialiseur YAML.
    - **Presentation** : écran liste (`ecran_fiches_personnelles.dart`), formulaire
      création/édition (`formulaire_fiche_personnelle.dart` : multi-sélections
      usages/qualités de sol, plage pH, validations), entrée gatée AppBar Catalogue
      + route `/catalogue/fiches-perso`, **tag visuel `BadgePerso`** sur les cartes
      + en-tête de fiche, menu ⋮ « dupliquer / modifier » gaté. Tests unitaires +
      widget en // (couche complète : 47 tests dédiés, suite widget 212 verte).
25. **Besoins en eau détaillés** (docs/15 §9, build-then-gate `acces.eauDetaillee`,
    palier expert) : feature complète de bout en bout.
    - **Domain** : VO optionnel `ArrosageDetaille` (chaque sous-champ
      indépendamment optionnel : `frequenceJours` min/max, `volumeLitresM2`
      min/max, `phasesSensibles`, `noteI18n` ; ≥1 aspect requis, invariants),
      enum `PhaseSensibleEau` (germination/feuillaison/floraison/fructification/
      grossissement), champ `BesoinsCulture.arrosageDetaille` (nullable).
    - **Infra** : bloc YAML `besoins.arrosage_detaille` (schéma + validateur
      optionnel/type-checké + mapper). **6 espèces seedées** avec **phases
      sensibles + note documentées** — chiffres volontairement vides (à remplir
      par le dev avec des sources réelles, jamais inventées).
    - **Presentation** : `_SectionArrosageDetaille` (`fiche_plante_detail.dart`),
      gatée `acces.eauDetaillee` + affichée si donnée présente ; le fait grossier
      « Arrosage » reste pour tous. Chiffres cadrés « repères indicatifs par temps
      chaud et sec » ; titre → glossaire `besoin-eau`. Clés ARB fr+en,
      `PhaseSensibleEau` couvert D6. **Moteur inchangé** (détail = informatif).
      Tests unitaires + widget en // (suite complète 1200 verte).
24. **Rotation avancée** (docs/15 §9, build-then-gate `acces.rotationAvancee`,
    palier expert) : feature complète de bout en bout.
    - **Domain** : enum `GroupeCultural { legumineuses, engraisVerts }`, VO
      `PrecedentCultural` (famille xor groupe) + normaliseur `analyser()` qui
      absorbe la dérive orthographique du corpus (`cucurbitacees→cucurbitaceae`,
      `graminées→poaceae`, `ail→amaryllidaceae`), champs
      `precedentsFavorables/Defavorables` sur `FichePlante`.
    - **Infra** : mapper lit `rotation.precedents_*` (normalisation + skip
      robuste), `VerificateurIntegriteFamilles` étendu (tout précédent-famille
      résout vers une fiche `_familles/*.yaml`, gardé par `familles_reel_test`).
    - **Application/moteur** : `EvaluationRotation` (dans `application/engine/`,
      comme `SuggestionAssociation`) → `ResultatRotation` (verdict favorable/
      défavorable/neutre + `RaisonRotation` explicites) ; réconcilie précédents
      déclarés + délai de retour famille + azote (`legumineuses↔fixeAzote`,
      `engrais_verts↔categorie`) ; défavorable domine.
    - **Presentation** : section « Rotation » dans le détail de zone
      (`syntheseRotationZoneProvider` : historique récent, familles bloquées par
      délai de retour avec année de libération, opportunités azote), gatée
      expert, lien glossaire `rotation-cultures`, clés ARB fr+en. Tests unitaires
      + widget en // (suite complète 1170 verte).

### 🚧 En cours / prochaine étape
- **Glossaire — suite** : illustrations choisies **par le dev** au fil de l'eau
  (procédure : [docs/17](docs/17-illustrations-glossaire.md)). Termes cliquables :
  **toutes les surfaces branchées** (vue Associations, bandeau + faits fiche,
  formulaires `AideGlossaire`, stade zone, calendrier, panneaux niveaux/
  pondération) ; depuis un survol modal la page est **poussée au-dessus**
  (retour = où on était). Alertes météo : pas de surface visuelle (notifications)
- **Affiner / approfondir les écrans** : reprendre les éléments différés de
  [`docs/15`](docs/15-elements-differes.md) au fur et à mesure que le nécessaire existe

### ⏭️ À venir
> État réel consolidé dans [`RESTE_A_FAIRE.md`](RESTE_A_FAIRE.md).
- **Toutes les features « build-then-gate » de docs/15 §9 sont livrées** (multi-
  potager · équipements/outils · fiches perso · rotation avancée · **besoins en
  eau détaillés** : ✅). **ADR-0009 est entièrement livré, lot 4 inclus**
  (mini-tuto « Guide des niveaux » + teaser de montée — vérifié 2026-07-17)
- maquettes dark mode · Rebrancher **Phosphor Icons** (package cassé sur
  Flutter 3.44.1, Material en substitut — voir `docs/08` §7)
- Finitions légères (docs/15 §2) : toggles paramètres (transparence des données,
  météo auto, « Ne pas déranger »), sous-routes go_router restantes, écran
  notifications d'accueil
- Distribution / **pré-release** : CI ✅ analyze+test (reste le job
  build/signature d'APK), keystore release réel, icône & splash, packaging
  multiplateforme (Linux AppImage/Flatpak, .exe, .dmg, .ipa)
- **Juste avant release** : relecture éditoriale de **tous** les chapitres du
  glossaire avec le dev, **puis** sa traduction `en` (le reste de l'i18n `en`
  UI + pilotage `locale` est ✅ livré) ; vérification dev Android (docs/15 §7)
- À arbitrer : **post-récolte** (scope V1 selon docs/13 §1, rien en code —
  reporter officiellement ou planifier) *(éditeur de fiches perso ✅ livré)*

---

## 📁 STRUCTURE DU REPO

```
pot-a-gerer/
├── docs/                  # Documentation découpée (source de vérité)
│   └── decisions/         # ADR
├── lib/
│   ├── main.dart          # point d'entrée (MaterialApp.router + thèmes + i18n)
│   ├── app/               # bootstrap, router (go_router), theme/ (design system)
│   ├── domain/            # entities, value_objects, enums, repositories, exceptions
│   ├── application/       # use_cases, state (orchestration)
│   ├── infrastructure/    # database (drift), repositories impl, mappers, catalogue (YAML), api, services
│   ├── presentation/      # screens, widgets, providers (Riverpod)
│   ├── core/              # constants, extensions, utils
│   └── l10n/              # ARB i18n
├── assets/
│   ├── fiches_plantes/    # YAML : legumes, aromatiques, fruits, petits_fruits, fleurs, cereales, engrais_verts, _schema
│   └── fonts/             # Manrope + Inter (variables, SIL OFL) + licences
├── test/                  # unit, widget, integration
├── pubspec.yaml           # généré + dépendances validées + polices
├── README.md · LICENSE (MIT) · CONTRIBUTING.md · .gitignore · CLAUDE.md
```

> ⚠️ Couches : on suit **4 couches** (Presentation → Application → Domain ← Infrastructure).
> Voir [`docs/04-architecture-en-couches.md`](docs/04-architecture-en-couches.md).

---

## 🤝 MÉTHODOLOGIE DE TRAVAIL

### Progression par étapes (jamais sauter une étape sans validation)
1. ✅ Cahier des charges · 2. ✅ Stack · 3. ✅ Architecture · 4. ✅ Setup repo & doc
5. ✅ Maquettes / design system (intégrées : `docs/08` + thème Flutter)
6. 🚧 Développement module par module (Domain/Infra/Application ✅ · **Presentation : 5 écrans principaux ✅**, affinage en cours)
7. ✅ Tests unitaires & widget (en //) · 8. ⏭️ README · 9. ⏭️ Déploiement & packaging

### Dans chaque réponse
- Indiquer à quelle étape on se trouve
- Rappeler ce qui vient d'être fait et ce qui vient ensuite
- Ne **jamais** introduire silencieusement une dépendance non validée

### Commandes spéciales du dev
- `[CONTEXTE]` → résumé complet rechargeable · `[RECAP]` → résumé session ·
  `[STACK]` → rappel des choix techniques validés

---

## ⛔ CONTRAINTES ABSOLUES — JAMAIS DE COMPROMIS

1. Aucune donnée utilisateur sur serveur externe
2. Aucune identité requise de l'utilisateur
3. Tout opt-out doit être possible et fonctionnel
4. POO stricte, sans exception
5. Aucune étape sautée sans validation explicite du dev
6. Aucune dépendance externe non validée introduite silencieusement
7. Tests écrits en parallèle du code, jamais après

---

## 🎬 PROCHAINE ACTION ATTENDUE

L'app est **fonctionnelle de bout en bout** (onboarding → potager → plantations →
tâches/arrosage → météo → export), alpha Android installée. Le **glossaire
« Aide & lexique »** (ADR-0017) est livré lots 1–5 ; la **relecture éditoriale**
de tous les chapitres est **reportée juste avant release** (docs/15 §7), les
**illustrations** sont choisies par le dev au fil de l'eau ([docs/17](docs/17-illustrations-glossaire.md)).
Dernière feature livrée : **besoins en eau détaillés** (build-then-gate
`acces.eauDetaillee`, palier expert) — domain (VO optionnel `ArrosageDetaille`
+ enum `PhaseSensibleEau`) + infra (bloc YAML `besoins.arrosage_detaille`,
validateur/mapper + 6 espèces seedées avec phases sensibles & notes documentées,
chiffres laissés vides à sourcer par le dev) + UI (`_SectionArrosageDetaille`
gatée expert, terme grossier conservé pour tous) ; moteur inchangé ; tests en //.
**Toutes les features build-then-gate de §9 sont désormais livrées.** Reste côté
glossaire : termes cliquables sur les surfaces restantes (docs/15 §8 #4bis).
Prochains chantiers V1 possibles (chacun dans sa propre session, **tests en
parallèle**) : finitions §2 (toggles paramètres, sous-routes) · arbitrage
**post-récolte** (docs/13 §1). Le reste (distribution/pré-release, traduction
`en` du glossaire) est consolidé dans [`RESTE_A_FAIRE.md`](RESTE_A_FAIRE.md) —
multi-potager, équipements, fiches perso, rotation avancée, **ADR-0009 lot 4
(mini-tutos/teaser de palier)**, CI analyze+test, version dynamique, liens
externes et i18n `en` UI sont ✅ livrés.

> ⚠️ Rappel : les exports `vege-garden-export/` sont des maquettes React/HTML/CSS.
> Aucun fichier n'est transférable tel quel ; chaque écran est **réimplémenté**
> en Flutter d'après la maquette. Les tokens couleur de la maquette sont déjà
> remontés dans `docs/08` §2 (source de vérité).

Le développeur guide étape par étape. **Tu n'agis pas seul sur des décisions
structurantes.**
