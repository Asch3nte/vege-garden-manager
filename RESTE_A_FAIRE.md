# Reste à faire — Pot'à Gérer

> Résumé étendu de ce qu'il reste à faire, **hors design** (dark mode, Phosphor
> Icons) et **hors revue de contenu** (relecture éditoriale du glossaire,
> éditorial des familles/bioagresseurs). Généré le 2026-07-07 à partir de
> [`docs/15-elements-differes.md`](docs/15-elements-differes.md) et
> [`docs/13-roadmap-et-versioning.md`](docs/13-roadmap-et-versioning.md).
> Mis à jour le 2026-07-08 après livraison des **fiches plantes perso** et de la
> **CI analyze+test** (le multi-potager, les équipements, la version dynamique,
> les liens externes et l'i18n `en` UI étant déjà livrés).
> Mis à jour le 2026-07-17 : **correction de suivi** — **ADR-0009 lot 4**
> (mini-tutos/teaser de palier) était listé « à faire » alors qu'il était déjà
> livré et mergé ; entrées rayées.
> Mis à jour le 2026-07-17 (soir) : livraison du **toggle « Ne pas déranger »**
> (opt-out #3 rendu effectif dans `GenererTachesArrosage` — branche
> `feat/notifs-opt-outs-fonctionnels`) ; entrées rayées.
> Mis à jour le 2026-07-17 (soir, suite) : livraison du **toggle « Météo
> automatique »** (opt-out docs/11 rendu effectif — aucun appel Open-Meteo
> automatique quand off ; branche `feat/toggle-meteo-auto`) ; entrées rayées.
> Mis à jour le 2026-07-17 (soir, suite 2) : livraison de l'**écran
> notifications d'accueil** (`/accueil/notifications` : alertes météo + cloche +
> lien « Voir toutes les tâches » ; branche `feat/accueil-notifications`) et
> **arbitrage des sous-routes go_router** (fiche = modale, détail tâche
> redondant) ; entrées rayées.
> Mis à jour le 2026-07-17 (soir, suite 3) : livraison de la **transparence des
> données** (section « Données stockées » : taille de la base + nb
> d'enregistrements par table ; branche `feat/transparence-donnees`). **Les 3
> finitions §2 sont désormais traitées** ; journal d'accès différé, politique de
> confidentialité (texte) laissée à la rédaction du dev.
> Mis à jour le 2026-07-18 : **révision de l'arbitrage « détail tâche »** (retour
> dev) — finalement **livré** (route `/calendrier/tache/:id`, édition
> notes/priorité + cycle de vie + navigation vers la cible). En parallèle,
> **précision des tâches & notifications d'arrosage** : les tâches nomment leur
> culture (« Arroser : Tomate ») et **une seule** notification récap regroupe
> tout (noms dans le titre + « +N », liste complète dans le corps) — anti-spam,
> détail maximal. Brouillon **politique de confidentialité**
> (`docs/politique-confidentialite.md`) livré. Branche `feat/detail-tache`.
> Mis à jour le 2026-07-18 (suite) : **audit i18n** — nouveau **§4bis** listant
> le texte UI encore codé en français en dur (résumé météo, tâches/notifs
> d'arrosage, `_moisFr` ×4, 1 placeholder). **Borné** (pas un chantier
> global) ; à corriger avec/avant la traduction `en`.
> Mis à jour le 2026-08-16 : **correction de suivi** — le fichier de route du
> contenu (`FICHES A CREER.md`) avait été **perdu lors de la fusion des fiches**
> du 2026-07-18 et n'existait plus sur `main`. Restauré, réconcilié contre
> `_schema/id_registry.yaml` (312 fiches réelles) et **étoffé** à la cible
> « maximum de fiches, mères ET filles ». Nouvelle entrée « Contenu du
> catalogue » en fin de document.
> Mis à jour le 2026-08-16 (fin de session) : **lots de contenu 12 (aromatiques,
> 38 fiches) et 13 (piments, 25 fiches)** livrés → **375 fiches**. Merge de
> `fix/dates-et-regroupement-taches` (correctif dates UTC↔local + regroupement
> des tâches par geste, **ADR-0020** après renumérotation). **Nettoyage des
> branches** : toutes les branches mergées supprimées (locales + distantes) ;
> deux branches obsolètes supprimées après vérification qu'elles ne contenaient
> rien d'unique — `feat/fiches-plantes-courantes` (`c523120`, contenu déjà
> intégré par la fusion du 2026-07-18 : 0 fichier absent de `main`) et
> `feat/finitions-parametres-accueil` (`9d415f3`, refaite sur `main` sous
> d'autres noms : `ecran_notifications`, `statistiques_donnees_service_impl`,
> `ecran_tache_detail`, `fenetre_ne_pas_deranger`). Les SHA permettent de les
> restaurer si besoin (`git checkout -b <nom> <sha>`). **Conservées** : `main`,
> `develop` (convention du repo) et **`feat/catalogue-reseau`** — voir ci-dessous.
> **⚠️ `feat/catalogue-reseau` (`9c433e7`, wip du 2026-06-13) est la seule
> branche non mergée restante.** Elle porte 29 fichiers absents de `main`, dont
> tout le dossier `vege-garden-export/` (maquettes React/HTML/CSS de référence
> des 5 écrans + `spec/00-design-system.md` … `05-parametres.md`). Ces maquettes
> **n'existent nulle part ailleurs dans le repo**. Les tokens couleur en ont déjà
> été remontés dans `docs/08` (source de vérité), donc rien n'est bloquant — mais
> supprimer la branche ferait disparaître les maquettes d'origine. **Décision à
> prendre par le dev** : merger les maquettes dans `main` pour les archiver, ou
> supprimer la branche en connaissance de cause.
> **Audit intégral 2026-07-17** : chaque item encore listé « à faire » a été
> **revérifié contre le code**. Résultat — **base saine** : hormis le lot 4
> ci-dessus (corrigé), tout le reste est bien pendant. Vérifiés réellement
> absents : ~~DND (champs domaine présents, UI absente)~~ **livré depuis** (voir
> ci-dessous), toggle météo auto (aucun
> champ), « Transparence des données » (le panneau `donnees` = sauvegarde/reset,
> **pas** stats DB + journal), favoris catalogue, dimensions littérales de zone
> (`Parcelle` n'a que `surface`), `ResolveurFamille` non branché dans
> `RecommanderPlantes` (répulsion/piège left out, cf. `recommander_plantes.dart`),
> menu ⋮/notifications d'accueil + lien « voir les tâches », sous-routes dédiées
> détail-tâche/fiche-plante, job CI build/signature APK, icône/splash, packaging.

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
- ~~**Besoins en eau détaillés** (expert) : enrichir d'abord `BesoinsCulture`~~
  ✅ **Livré** : VO optionnel `ArrosageDetaille` (fréquence/volume/phases
  sensibles/note, chaque sous-champ optionnel) + enum `PhaseSensibleEau` ;
  bloc YAML `besoins.arrosage_detaille` (validateur/mapper) ; **6 espèces
  seedées** (phases sensibles + notes documentées ; **chiffres laissés vides à
  sourcer par le dev**, jamais inventés) ; section gatée `acces.eauDetaillee`
  dans le détail de fiche (terme grossier conservé pour tous), **moteur
  inchangé** — voir docs/15 §9
  - **Suite envisagée (post-V1)** : [ADR-0018](docs/decisions/0018-stade-sensible-urgence-arrosage.md)
    (statut **Proposé**) — coupler `phasesSensibles` × stade de croissance pour
    **moduler l'urgence d'arrosage** ; cadrage figé (mapping fin↔grossier,
    garde-fou ADR-0009, recalibration). Prérequis : corpus renseigné.
- ~~**Lot 4 ADR-0009** : mini-tutos par palier + teaser de montée~~ ✅ **Livré**
  (2026-07-17, vérifié) : **4a** panneau « Guide des niveaux »
  (`panneau_niveaux.dart`, route `/plus/niveaux`) re-consultable ; **4b** teaser
  contextuel `CarteTeaserPalier` (Catalogue/Calendrier) + nudge au changement de
  niveau — commits `59d32ed` / `80de958`. **L'ADR-0009 marquait déjà le lot ✅**
  (ligne 172) ; ce fichier était périmé.

## 2. Éléments différés docs/15 — non-design

- ~~**Navigation** : sous-routes go_router restantes (détail tâche, fiche
  plante en route dédiée)~~ ✅ **fait** (2026-07-18) : **fiche plante gardée
  en modale** (`showModalBottomSheet`, bien intégrée + meilleure UX — décision
  dev, inchangée). **Détail tâche : LIVRÉ** (révision de l'arbitrage du 2026-07-17
  après retour dev — l'ancien « redondant » était faux : le formulaire rapide ne
  couvre ni notes, ni priorité, ni le cycle de vie) : route `/calendrier/tache/:id`
  → `EcranTacheDetail` (VO+notifier `detailTacheProvider`) — vue complète (type,
  état, priorité, date, cible résolue **avec navigation** vers la zone/culture,
  description en lecture seule) + **édition des notes** (« ajouter des détails »),
  **choix de priorité**, **marquer fait/rouvrir**, **reporter**, **annuler**,
  modifier (formulaire) / supprimer. Ouverte depuis la carte du calendrier et les
  lignes d'accueil (le corps ouvre le détail, le bouton ☑ coche). Sous-routes
  ajoutées : `/accueil/notifications` + `/calendrier/tache/:id`. Tests notifier +
  widget + navigation en //.
- ~~**Accueil** : écran notifications + menu ⋮ (actions d'en-tête), lien « voir
  les tâches » → Calendrier~~ ✅ **fait** (2026-07-17) : écran
  `EcranNotifications` (route `/accueil/notifications`) surfaçant les **alertes
  météo** (gel/canicule/forte pluie de `DetecterAlertesMeteo`, jusqu'ici
  seulement comptées) via un provider partagé `alertesMeteoProvider` (**source
  unique** : le badge de la cloche == la liste) ; **cloche** dans l'AppBar
  d'accueil (badge = nombre d'alertes) ; **lien « Voir toutes les tâches »** →
  Calendrier en pied de section « Tâches du jour ». Le « menu ⋮ » est résolu par
  la cloche (le tableau de bord, read-only, n'a pas d'autre action d'en-tête).
  Provider + widget + navigation testés en //.
- **Potager** : la **création fonctionne déjà** partout (FAB « ajouter une zone »
  dans `ecran_potager.dart`, potager via menu ⋮, plantation via détail de zone) ;
  reste seulement, **optionnel**, les métadonnées de zone (besoin eau/dimensions
  littérales — `Parcelle` ne porte que `surface`) si on veut les champs réels
- **Catalogue** : favoris (notion inexistante), gabarit/hauteur de plante
  (champ manquant), vue Réseau — rendu canvas (perf, différé)
- **Calendrier** : rien de fonctionnel majeur restant (tout ✅). **Détail
  tâche livré** (2026-07-18) : `/calendrier/tache/:id`, cf. § Navigation.
- **Tâches & notifications d'arrosage** ✅ (2026-07-18) : `GenererTachesArrosage`
  nomme la culture dans le titre de la tâche (« Arroser : Tomate ») et n'émet
  qu'**une** notification récap par jour (anti-spam), noms dans le titre (avec
  « +N » si débordement) + liste complète dans le corps. **Dette connue** :
  ces libellés de notification/tâche générés hors UI restent **codés en dur en
  français** (i18n des notifications = chantier séparé, docs/15).
- **Paramètres** :
  - ~~Catégorie « Transparence des données » (stats tailles DB + journal
    d'accès — n'existe pas)~~ ✅ **fait** (2026-07-17) : section **« Données
    stockées »** dans le panneau Données (`_SectionStockage`) — **taille de la
    base sur l'appareil** (`PRAGMA page_count × page_size`, indépendant de la
    plateforme) + **nombre d'enregistrements par table** (lecture générique de
    `AppDatabase.allTables`, apparaît automatiquement pour toute nouvelle table).
    Couche propre : VO domain `StatistiquesStockage`/`StatistiqueTable`,
    interface `AbstractStatistiquesDonneesService`, impl infra Drift, provider +
    FutureProvider applicatif, i18n fr/en, tests (service en mémoire + VO +
    widget). **Journal d'accès aux données sensibles : volontairement différé**
    (docs/15 le marquait déjà « (éventuel) » ; nécessiterait un sous-système de
    journalisation à instrumenter partout, valeur discutable pour une app 100 %
    locale). **Politique de confidentialité (texte hors-ligne)** : à rédiger par
    le dev (éditorial) — cf. docs/11 §6.
  - ~~Toggle « récupération météo auto » (champ manquant)~~ ✅ **fait**
    (2026-07-17) : opt-out `meteoAutoActive` (défaut `true`, migration Drift
    v5→v6) — interrupteur panneau Confidentialité + **application effective**
    (aucun appel Open-Meteo automatique quand off : carte météo d'accueil
    masquée/muette, alertes = 0, conseil arrosage & `GenererTachesArrosage`
    dégradés en demande-seule ; l'écran détail météo reste rafraîchi à la main).
    Domain→infra→app→UI + i18n fr/en, tests par couche en //. Branche
    `feat/toggle-meteo-auto`.
  - ~~Toggle « Ne pas déranger »~~ ✅ **fait** (2026-07-17) : plage silencieuse
    fonctionnelle — VO `FenetreNePasDeranger` (fenêtre horaire semi-ouverte,
    chevauchement de minuit), UI panneau notifications (interrupteur +
    sélecteurs début/fin), et **application effective** de l'opt-out #3 dans
    `GenererTachesArrosage` (notification supprimée si master off, catégorie
    `arrosage` coupée, ou 08:00 dans la fenêtre — la **tâche est toujours
    créée**). Tests VO + notifier + use case en //.
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
- **Prérequis à la traduction `en`** : corriger d'abord la **dette i18n**
  (texte UI codé en FR en dur — voir **§4bis**), sinon ces chaînes resteront en
  français quelle que soit la langue choisie.

## 4. Backlog UX (docs/15 §8) — restes non-design

- ~~**F2** (multi-potager dans réglages)~~ ✅ **fait**
- **§11** : (a) typer/renseigner le contenu éditorial des paires
  d'associations (mi-contenu, mi-dev) ; (c) brancher un `ResolveurFamille`
  complet pour activer les suggestions répulsion/piège (aujourd'hui `null`)

## 4bis. Dette i18n — texte UI codé en français en dur (à corriger)

> ⚠️ **Règle projet** : tout texte visible par l'utilisateur doit passer par
> l'i18n (ARB `AppLocalizations`), **toujours**. Quelques endroits y ont
> échappé — à réparer avant la traduction `en` (§3). **Bonne nouvelle : c'est
> borné** (l'UI est déjà i18n à ~167 endroits `AppLocalizations.of(context)`).
> Audit du 2026-07-18 : sur 29 littéraux accentués, seuls ceux ci-dessous sont
> du vrai texte UI (le reste = tables de normalisation d'accents, clés de
> données, noms de mois — voir plus bas).

Vrai texte UI à faire passer en ARB :

- **`application/engine/generateur_resume_meteo.dart`** (~8 chaînes) — **le plus
  gros** : tout le résumé météo affiché (« Vent très fort », « Pluie prévue
  prochainement… », « Temps ensoleillé/Ensoleillé », les 4 verdicts d'arrosage).
  Générateur de la couche **application** → pas de `BuildContext`, d'où le
  contournement.
- **`application/use_cases/generer_taches_arrosage.dart`** — titres de tâches
  (« Arroser : X ») **persistés en base** + textes de notification. ⚠️ cas
  double : le titre stocké **fige la langue** → la vraie correction est de **ne
  pas persister de titre localisé** mais de le **dériver à l'affichage** depuis
  `type` + cible (déjà porté par `Tache`). Notifications = injecter un
  fournisseur de textes localisés (garde la couche Application sans Flutter).
- **`presentation/screens/ecran_en_construction.dart`** — « Écran à venir. »
  (placeholder, trivial).
- **Tableaux `_moisFr`** dupliqués dans **4** fichiers (`ecran_meteo_detail`,
  `ecran_notifications`, `ecran_calendrier`, `ecran_tache_detail`) — noms de mois
  FR en dur ; devraient venir de `intl`/`DateFormat` localisé. **Double dette** :
  i18n **et** duplication (à factoriser en un helper unique).

**Non concernés** (à laisser tels quels) : jeux de caractères `àâä…` =
normalisation d'accents pour la recherche (`bioagresseur`, `famille_botanique`,
`precedent_cultural`, `vue_reseau_catalogue`, `recherche_glossaire`) ; clé de
donnée `"défavorable"` (`verificateur_integrite_familles`).

> Racine commune : les **générateurs de la couche application** (résumé météo,
> tâches d'arrosage) produisent du texte utilisateur **sans `BuildContext`**,
> alors que la règle « pas de Flutter dans Application » interdit
> `AppLocalizations.of(context)`. Correctif propre : injecter une petite
> **interface de textes localisés** (implémentée côté présentation) dans ces
> use cases — ou, pour les titres de tâches, **dériver à l'affichage** au lieu
> de persister. À faire **avec/avant la traduction `en`** (§3), pas en urgence.

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
~~**Fiches plantes perso**~~ ✅ (2026-07-08) · ~~**Rotation avancée**~~ ✅ ·
~~**Besoins en eau détaillés**~~ ✅ (2026-07-08) · ~~**Lot 4 ADR-0009**
(mini-tutos/teaser de palier)~~ ✅ (livré antérieurement, suivi corrigé le
2026-07-17).

Côté **features V1 build-then-gate (§9) ET l'accompagnement des paliers
(ADR-0009), tout est livré.** Reste, plus léger :

1. ~~Arbitrage **post-récolte** (docs/13 §1) : reporter ou planifier.~~
   ✅ **tranché** (2026-07-17) : **reporté en V1.1** — [ADR-0019](docs/decisions/0019-report-post-recolte-v11.md)
   (Accepté). Périmètre V1 fermé ; docs/13 §1→§2 alignés, docstring
   `ecran_plus.dart` alignée, clés ARB `plusPostRecolte(Sub)` réservées V1.1.
   Finitions §2 : ~~transparence des données~~ ✅ livré ; ~~sous-routes
   go_router~~ ✅ arbitré ; ~~écran notifications d'accueil~~ ✅ livré.
   **Les trois finitions §2 sont désormais traitées.**

Tout le reste se range en :

- **Contenu du catalogue** (chantier long, parallèle au dev — feuille de route
  [`FICHES A CREER.md`](FICHES%20A%20CREER.md)) : **312 fiches livrées sur une
  cible décrite de ~1 259** (235 mères + 1 024 variétés), objectif « maximum de
  fiches, mères ET filles ». Dernier lot : **lot 11** (amaranthacées, 2026-07-15),
  suivi de la **fusion des deux efforts divergents** (2026-07-18). Priorité :
  **aromatiques** (7 mères, romarin/sauge/origan/mélisse/estragon/laurier
  absents), puis piment (arbitrage à trancher), fruits/petits fruits (1 variété
  par espèce aujourd'hui).
- **Pré-release / distribution** (groupé avant la sortie) : keystore release +
  job CI de build/signature, icône & splash, packaging desktop/iOS, relecture
  éditoriale du glossaire puis sa traduction `en`, vérification dev Android.
- **Finitions légères** (docs/15 §2) — **toutes traitées** : ~~toggles
  paramètres~~ ✅ (« Ne pas déranger », « météo auto ») ; ~~transparence des
  données~~ ✅ (section « Données stockées » ; journal d'accès différé, cf.
  § Paramètres) ; ~~sous-routes go_router~~ ✅ **arbitré** (fiche = modale,
  détail tâche redondant, `/accueil/notifications` ajoutée) ; ~~écran
  notifications d'accueil~~ ✅ **livré**. Reste hors §2 : `ResolveurFamille`
  complet (§11).
- **V1.1 / V2** : `Traitement`, photos, sensibilité météo par plante,
  **post-récolte (conservation, recettes — reporté, ADR-0019)**, conformité
  territoriale, communauté P2P, plan spatial, calendrier lunaire.
