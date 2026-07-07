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
- Features « build-then-gate » (docs/15 §9) : multi-potager,
  fiches perso (scope V1), rotation avancée *(équipements/outils ✅ livré)*
- i18n effective (ARB `en` + pilotage `locale`) · maquettes dark mode
- Rebrancher **Phosphor Icons** (package cassé sur Flutter 3.44.1, Material en substitut — voir `docs/08` §7)
- Distribution : keystore release réel, icône & splash, CI/CD GitHub Actions
- **Juste avant release** : relecture éditoriale de **tous** les chapitres du
  glossaire avec le dev (quand tous les termes/features/design seront figés —
  docs/15 §7)
- Packaging multiplateforme (Linux AppImage/Flatpak, APK, .exe, .dmg)
- À arbitrer : **post-récolte** et **éditeur de fiches perso** (scope V1 selon
  docs/13 §1, rien en code — reporter officiellement ou planifier)

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
Reste côté glossaire : termes cliquables sur les surfaces restantes (docs/15 §8
#4bis). Ensuite (à arbitrer) : multi-potager (§9), distribution
(CI/CD, signing), i18n `en` — toujours **avec leurs tests en parallèle**.

> ⚠️ Rappel : les exports `vege-garden-export/` sont des maquettes React/HTML/CSS.
> Aucun fichier n'est transférable tel quel ; chaque écran est **réimplémenté**
> en Flutter d'après la maquette. Les tokens couleur de la maquette sont déjà
> remontés dans `docs/08` §2 (source de vérité).

Le développeur guide étape par étape. **Tu n'agis pas seul sur des décisions
structurantes.**
