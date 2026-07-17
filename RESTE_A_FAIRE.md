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
  plante en route dédiée)~~ ✅ **arbitré** (2026-07-17) : **fiche plante gardée
  en modale** (`showModalBottomSheet`, bien intégrée + meilleure UX — décision
  dev) ; **détail tâche jugé redondant** (une tâche est déjà cochable + éditable
  via `ouvrirFormulaireTache` + supprimable → pas de route dédiée). Seule
  sous-route ajoutée : `/accueil/notifications` (voir Accueil ci-dessous).
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
- **Calendrier** : rien de fonctionnel majeur restant (tout ✅)
- **Paramètres** :
  - Catégorie « Transparence des données » (stats tailles DB + journal
    d'accès — n'existe pas)
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
   Reste, plus léger : finitions §2 (transparence des données ; ~~sous-routes
   go_router~~ ✅ arbitré, ~~écran notifications d'accueil~~ ✅ livré).

Tout le reste se range en :

- **Pré-release / distribution** (groupé avant la sortie) : keystore release +
  job CI de build/signature, icône & splash, packaging desktop/iOS, relecture
  éditoriale du glossaire puis sa traduction `en`, vérification dev Android.
- **Finitions légères** (docs/15 §2) : toggles paramètres restants (transparence
  des données — les **« Ne pas déranger »** et **« météo auto » sont ✅ livrés**,
  cf. § Paramètres) ; ~~sous-routes go_router restantes~~ ✅ **arbitré** (fiche =
  modale, détail tâche redondant, `/accueil/notifications` ajoutée) ; ~~écran
  notifications d'accueil~~ ✅ **livré** ; `ResolveurFamille` complet (§11).
  **Reste vraiment : la « transparence des données ».**
- **V1.1 / V2** : `Traitement`, photos, sensibilité météo par plante,
  **post-récolte (conservation, recettes — reporté, ADR-0019)**, conformité
  territoriale, communauté P2P, plan spatial, calendrier lunaire.
