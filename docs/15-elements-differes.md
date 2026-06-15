# 15 — Éléments différés (registre)

> **But.** Recenser tout ce qui, pendant le développement de la couche
> Presentation, **n'a pas pu être branché à de vraies données / fonctions** et a
> été rendu comme placeholder explicite ou volontairement laissé de côté. Chaque
> entrée indique **ce qui manque** pour le réaliser et **où** revenir le brancher.
>
> Règle suivie : on n'affiche jamais de fausses valeurs. Tant qu'une donnée n'a
> pas sa source/son calcul, l'UI montre un placeholder « à venir » (ou un état
> verrouillé), jamais un chiffre inventé.
>
> Convention : ✅ fait · 🔵 placeholder en place (à brancher) · ⚪ non commencé.
> Mettre à jour ce fichier **en même temps** que le code qui résout une entrée.

---

## 1. Fondations (thème, icônes, navigation)

| Élément | État | Ce qui manque pour le faire | Où revenir |
|---|---|---|---|
| **Phosphor Icons** | 🔵 Material en substitut | `phosphor_flutter` 2.1.0 ne compile pas sur Flutter 3.44.1 (étend `IconData`, devenu `final`). Pas de correctif amont. | Wrapper local (`.ttf` Phosphor MIT + `IconData const` maison) **ou** version compatible publiée. Voir [08 §7](08-design-system.md). Icônes à remplacer dans `lib/app/router.dart` (`_destinations`) et tous les écrans. |
| **Dark mode** | 🔵 valeurs CAHIER, non revalidées | Les maquettes Claude Design ne couvrent que le light. | Maquetter le dark, puis revoir [08 §3](08-design-system.md) et `CouleursApp.*Sombre` dans `lib/app/theme/couleurs_app.dart`. |
| **Polices embarquées** | ✅ | — | Manrope/Inter variables embarquées (`assets/fonts/`). |
| **Navigation inter-écrans** | 🔵 avancée | Sous-routes go_router en place : `/potager/zone/:id` → `EcranZoneDetail` (atteint depuis le plan **et** les tuiles de l'accueil, qui basculent alors sur l'onglet Potager — §8 D #5), `/accueil/meteo` et `/plus/{general,confidentialite,notifications,apropos}`. **Retour arrière = historique global partagé** traversant les onglets, tap d'onglet → racine (§8 D #6, `historique_navigation.dart`). Restent détail tâche, fiche plante en route dédiée. | Ajouter les sous-routes go_router restantes dans `lib/app/router.dart` au fil des écrans. |

---

## 2. Écran Accueil (`lib/presentation/screens/ecran_accueil.dart`)

Données réelles déjà branchées : nom du potager actif, zones, **tâches du jour**,
**niveau d'expérience** (→ divulgation progressive). Le reste :

| Élément | État | Ce qui manque | Où revenir |
|---|---|---|---|
| **Carte météo + verdict d'arrosage** | ✅ | — | `MeteoAccueilNotifier` (`meteoAccueilProvider`) : températures du jour + **verdict d'arrosage** niveau jardin (pluie à venir / sol humide / arroser / clément, seuils de `BilanArrosage`) depuis `meteoServiceProvider` + la **position du potager actif**. `_CarteMeteo` branché ; invite à renseigner la position si aucune (cf. onboarding §7). **Position connue → la carte ouvre le détail horaire** (`EcranMeteoDetail` : sélecteur de jour + prévisions par heure ; `obtenirPrevisionsHoraires` Open-Meteo + `PrevisionHoraire`). |
| **Tuile « Alerte »** | ✅ | — | `AccueilNotifier` compte les alertes via `detecterAlertesMeteo` (localisation du potager + plantations actives ; 0 sans position / météo indispo) → `AccueilVue.nombreAlertes` → `_GrilleStats`. |
| **Tuile « Récoltes de la saison »** | ✅ | — | `AccueilNotifier` agrège les récoltes de l'année courante (itère les plantations × `obtenirParPlantation`) → `AccueilVue.nombreRecoltesSaison` → tuile niveau Expert. |
| **Niveaux d'expérience 4 → 3** | ✅ (décision) · **divulgation progressive : [ADR-0009](decisions/0009-paliers-experience-divulgation-progressive.md)** | La maquette a 4 paliers (Découverte/Apprenti/Jardinier/Expert), le domaine `NiveauExperience` en a 3 (debutant/intermediaire/expert). | Décision actée : domaine fait foi. **ADR-0009** formalise la **divulgation progressive** : matrice features→palier, garde-fous (réversible/non destructif), politique `AccesNiveau` (✅ socle), **gating** par palier (Lot 2/3), **mini-tuto par palier** (features débloquées : pourquoi/comment, présenté à l'atteinte + re-consultable) + **teaser** de montée de palier (Lot 4, modèle commun avec Aide & lexique §8 C4). |
| **Actions d'en-tête** (cloche notifs, menu ⋮) | ⚪ | Écran notifications + menu contextuel. | À l'implémentation de ces écrans. |
| **Navigation depuis les sections** (« voir les tâches », tuile zone…) | 🔵 zone faite | **Tuile zone → détail** branché : `go('/potager/zone/:id')` → bascule sur l'onglet **Potager** affichant la zone ; le retour système revient à l'accueil via l'historique global partagé (§8 D #5/#6). Reste « voir les tâches » → Calendrier. | Brancher le `onTap` des tâches vers le Calendrier. |

---

## 3. Écran Potager (`lib/presentation/screens/ecran_potager.dart`)

Réalisé : **variante A** de la maquette (plan en grille de planches — serre en
pleine largeur, 2 colonnes, puces de cultures, pastille « goutte » si tâche du
jour, légende), données réelles (potager actif, zones, cultures via catalogue,
type de zone, drapeau « tâche du jour »). Décision produit : variante A par
défaut, « afficher l'existant / dériver » (pas d'extension de modèle). Le tap sur
une planche ouvre le **détail de zone** (`EcranZoneDetail`, sous-route go_router
`/potager/zone/:id`).

| Élément | État | Ce qui manque | Où revenir |
|---|---|---|---|
| **Plan en grille** (variante A) | ✅ | — | `_Plan` dans `ecran_potager.dart`. |
| **Plan spatial** (variante B) | ⚪ (écarté) | Positions/dimensions spatiales des zones. **Aucun champ de layout** (x/y/largeur/hauteur) sur `Parcelle`. | Étendre le modèle (domaine + drift) avec un layout de zone, puis la vue. Lourd — à cadrer. Non retenu pour V1 (variante A par défaut). |
| **Détail d'une zone** | ✅ | — | `EcranZoneDetail` complet : nom, type, surface, expo, cultures + **« Ajouter une plante »** (§4) + par culture **Arracher** (statut `arrachee`, garde l'historique) / **Supprimer** (soft delete, confirmation) + **Modifier** / **Supprimer** la zone (soft delete en cascade logique → historique conservé ; confirmation). Chaque culture montre son **stade de croissance** (`CulturePotager.etat`) **et sa prochaine tâche** (`prochainesTachesZoneProvider`). |
| **Stade de croissance par culture** (Semis→Récolte) | ✅ V1 (proportionnel) | — | `CalculateurDatesCulture.etatCroissance` (engine pur) : courbe **proportionnelle** plante-agnostique dérivée de `Plantation.dateMiseEnPlace` + `dureeAvantRecolteJoursMin` (seuils 12 %/66 %/100 %), consciente de la méthode (semis → phase **Levée** ; plant établi → démarre à **Croissance**). 4 stades `StadeCroissance` (Levée/Croissance/Maturation/Récolte) + VO résultat `EtatCroissance` (stade + progression). Surfacé dans `_LigneCulture` (libellé + barre de progression). **V2** : modèle fidèle par espèce/variété quand les fiches porteront des durées de stade (option : parser `duree_germination_jours`, déjà présent dans des fiches mères). |
| **Tâche « prochaine » par culture** | ✅ | — | Lien **tâche↔plantation** câblé : `CibleTache.plantation` (déjà au modèle) exposé à la **création** (cibles « culture » dans `FormulaireTache`) et à la **consommation** (`prochainesTachesZoneProvider` → prochaine tâche non faite par culture, dans le détail de zone). |
| **Métadonnées de zone** (eau « 1×/jour », dimensions « 1,2 × 1,2 m ») | ⚪ | « Besoin en eau » et « dimensions » littérales de la maquette n'existent pas comme champs (`Parcelle` a une `surface` en m², pas L×l ; pas de fréquence d'arrosage de zone). | Soit dériver (arrosage via moteur), soit étendre le modèle si on veut les dimensions littérales. |
| **Couleur de zone** | 🔵 dérivée par index | La maquette assigne une couleur par zone ; ici on l'attribue par position (`_couleursZones`), non persistée. | Si on veut une couleur choisie/stable par zone : champ sur `Parcelle` (domaine + drift). |
| **FAB de création** (docs/09 §4) | ⚪ | Actions de création (potager/zone/plantation). | Brancher quand les écrans/forms de création existent. |

---

## 4. Écran Catalogue (`lib/presentation/screens/ecran_catalogue.dart`)

Réalisé : **vue Fiches** (recherche + filtre catégorie + cartes + fiche détaillée
en bottom sheet). Données réelles : nom, catégorie, exposition, eau, espacement,
délai de récolte, **associations** (bons/mauvais compagnons, dérivées via les
prédicats `sAssocieBienAvec` / `entreEnConflitAvec` sur tout le catalogue).

| Élément | État | Ce qui manque | Où revenir |
|---|---|---|---|
| **Vue « Réseau »** (constellation d'associations) | ✅ | — | `VueReseauCatalogue` (`vue_reseau_catalogue.dart`) : spirale de Fermat, arêtes `CustomPaint` (bons / à éviter, bascule), sélection → voisins surlignés + panneau (compagnons, « Voir la fiche »), re-tap → fiche. Bascule **Fiches / Réseau** dans `ecran_catalogue.dart` ; `CatalogueVue.toutes` expose le catalogue complet. |
| **Calendrier semis/récolte de la fiche** | ✅ | — | Section « Semis & récolte » (`fiche_plante_detail.dart` → `CalendrierSemisRecolte`) dérivée de `periodesPour(hémisphère, climat)` via le **contexte du potager actif** (`contexteClimatProvider`, brique partagée avec la vue Saison). Hémisphère nord supposé+signalé sans position ; note « crée un potager » si aucun potager actif. |
| **Difficulté de culture** | ⚪ | Aucun champ « difficulté » sur `FichePlante` (la maquette a 1–3 points). | Ajouter le champ (YAML + entité) si on garde cette info, ou la dériver. |
| **Liste des variétés** | ✅ | — | Hiérarchie mère/variété (ADR-0005) : variétés dépliables sous l'espèce dans la liste (`_CarteGroupe`) **et** sélecteur de variété dans la fiche (`_SelecteurVariete` → `_ListeVarietes`, `CatalogueVue.varietesDe`/`mereDe`) ; choisir une variété re-rend la fiche, bouton retour + retour OS reviennent à l'espèce. |
| **Filtre par famille botanique** (ADR-0006, Lots 1–3) | ✅ | — | 2ᵉ ligne de chips sous la catégorie : familles **présentes** parmi les espèces de la catégorie (dérivé). Pipeline familles complet (`_familles/*.yaml`, `FamilleBotanique`, loader/validator/mapper/cache, repo + providers, intégrité référentielle). `CatalogueNotifier.definirFamille` + `_ChipsFamilles` dans `ecran_catalogue.dart`. |
| **Bulles éducatives par famille** (ADR-0006, **Lot 4**) | ⚪ | Le contenu éditorial au niveau famille existe en **structure** (`famille_schema.yaml` : `pourquoi_rotation`, `ennemis_communs_note`, `associations_note`) mais les **champs sont vides** dans les 44 fiches `_familles/`. Manquent aussi : exposition UI (bulles/info), et idéalement un **référentiel maladies/ravageurs** (les slugs `maladies_communes`/`ravageurs_communs` sont aujourd'hui indicatifs, non normalisés). À lancer quand on aura un maximum d'éléments pour démarrer le contenu éditorial. | Remplir le contenu éditorial des fiches `_familles/`, l'exposer dans la fiche plante (au niveau de sa famille) et/ou le filtre famille ; normaliser un référentiel maladies/ravageurs. Entité `FamilleBotanique` à étendre (champs notes localisées). |
| **Description textuelle** | ✅ | — | Champ `descriptionsLocalisees` sur `FichePlante` (parsé depuis `i18n.<locale>.description`, déjà présent dans les YAML) ; affichée en tête de fiche. |
| **Gabarit / hauteur** | ⚪ | Pas de champ hauteur. | Idem (modèle). |
| **Favoris** (cœur en en-tête) | ⚪ | Pas de notion de favori. | Préférences/persistance à concevoir. |
| **« Ajouter au potager »** (CTA fiche) | ✅ | — | CTA dans `fiche_plante_detail.dart` ; flux d'ajout (`_ajouterPlante` dans `ecran_catalogue.dart`) avec **2 chemins** : zone pré-ciblée (depuis le détail de zone, bannière d'ajout) ou **sélection sur le plan** (`EcranSelectionZone`) en navigation libre. Le `FormulairePlantation` s'ouvre pré-rempli (plante verrouillée). État de ciblage : `ajoutPlanteProvider`. |
| **Icône / couleur par catégorie** | 🔵 icône générique + couleur thème | La maquette a une icône + couleur par catégorie. | Mapper catégorie → icône Phosphor (cf. §1) + couleur déco. |

---

## 5. Écran Calendrier (`lib/presentation/screens/ecran_calendrier.dart`)

Réalisé : **vue Agenda** (résumé + sélecteur semaine/mois + groupes par jour de
tâches **cochables**). Données réelles : tâches sur fenêtre
(`obtenirEntreDates`), cocher = `Tache.marquerFaite` persisté.

| Élément | État | Ce qui manque | Où revenir |
|---|---|---|---|
| **Décocher une tâche** (réouvrir) | ✅ | — | Méthode domaine `Tache.rouvrir()` (terminee → aFaire, même date, efface la réalisation) ; `CalendrierNotifier.cocher` devient une **bascule** ; `_CarteTache` cliquable dans les deux sens (Agenda + Mois). |
| **Vue « Mois »** (grille mensuelle) | ✅ | — | Sélecteur **Agenda / Mois** dans `ecran_calendrier.dart` ; `_VueMois` : grille mensuelle navigable (‹ mois › + « Aujourd'hui »), pastilles colorées par type de tâche (`couleurTypeTache`), états aujourd'hui/sélectionné/tout-fait, liste cochable du jour sélectionné. `CalendrierVue` expose `moisAffiche` + `groupesMois` ; notifier `moisPrecedent`/`moisSuivant`/`revenirMoisActuel`. |
| **Vue « Saison »** (semis→récolte) | ✅ | — | `saison_notifier.dart` + `_VueSaison` : par culture en place, bandes **Semis / Plantation / Récolte** sur 12 mois, dérivées de `FichePlante.periodesPour(hemisphere, climat)`. Hémisphère = latitude du potager actif (**nord supposé + signalé** si pas de position, jamais en silence) ; climat = `zoneClimatique.type`. Colonne du mois courant surlignée, légende, état « non renseigné » si la fiche n'a pas le couple. |
| **Zone / culture / variété sur la carte** | ✅ | — | `CalendrierVue.cibleNom(tache)` résout `cibleId` → nom (map `'<cible>:<cibleId>'`, peuplée par `CalendrierNotifier._resoudreCibles`) : `parcelle` → nom de zone, `plantation` → culture/variété (via `obtenirParId` + fiche), `potager` → nom du jardin, `equipement` → null (pas d'écran). Affiché sur `_CarteTache` (icône lieu + nom). Cible introuvable/supprimée → aucun nom (jamais inventé). |
| **Filtre / Ajout de tâche** (en-tête) | ✅ (sélection de cible : évolution prévue) | Le menu déroulant de cible est provisoire. | Bouton **+** → `FormulaireTache` (intitulé, type, date, cible = potager / zone / **culture**, via `CreerTache`) ; bouton **filtre** → menu par type de geste (`CalendrierNotifier.definirFiltreType`, applique sur Agenda + Mois). **Évolution prévue** : une fois le Potager refondu en **vue plan du jardin** (cf. §3 variante B), remplacer le menu déroulant par une **sélection directe sur le plan** — cliquer le bouton de cible ouvre la vue plan, l'utilisateur tape l'élément voulu : le **potager entier**, une **parcelle**, ou **une/plusieurs plantations**. ⚠️ Le multi-cible (« plusieurs plantations ») dépasse le modèle actuel (`Tache` = exactement une cible) → impliquerait soit N tâches créées en lot, soit un modèle multi-cible. |
| **Icône Phosphor par geste** | 🔵 Material en substitut | cf. §1 (Phosphor en attente). `iconeTypeTache` mappe déjà chaque type → une icône Material. | Remplacer par les icônes Phosphor quand dispo (`libelles_enums.dart`). |

---

## 6. Écran Plus / Paramètres (`lib/presentation/screens/ecran_plus.dart` + `parametres/`)

Réalisé : racine Paramètres + 4 sous-panneaux **réels et persistés** (auto-save
via `PreferencesNotifier`) : **Général** (langue, thème, unités, gestes, niveau),
**Confidentialité** (géoloc, sync, lunaire, communauté V2), **Notifications**
(maître + 6 catégories), **À propos** (version, licence MIT, licences tierces,
crédits). Le **thème de l'app suit la préférence** (`main.dart` → `ThemeMode`).

| Élément | État | Ce qui manque | Où revenir |
|---|---|---|---|
| **Menu « Plus » (popover/sheet)** | 🔵 racine directe | La maquette ouvre un menu (Paramètres / Post-récolte / Communauté / À propos) ; ici l'onglet affiche directement la racine Paramètres. | Ajouter un menu si Post-récolte/Communauté arrivent ; sinon garder la racine directe. |
| **Post-récolte** | ⚪ | Écran de conservation/transformation. | Concevoir la fonctionnalité (hors V1 ?). |
| **Communauté (P2P)** | ⚪ V2 | Marquée V2, désactivée. | V2. |
| **Catégorie « Sauvegarde & données »** | ✅ (export/import) · ⚪ appairage | Nouveau panneau `PanneauDonnees` (catégorie du Plus, route `/plus/donnees`). **Export** : `AbstractSauvegardeService.exporterJson` → fichier partagé via la **feuille native** (`gestionnaire_sauvegarde_fichier.dart`, **share_plus**, écrit dans le dossier temp + `Share.shareXFiles`). **Import** : **file_picker** (`choisirEtLire`) → choix du **mode** (remplacer / fusionner, `SimpleDialog`) → `importerJson` ; erreurs typées (`SauvegardeInvalideException`) → snackbar ; succès → invalidation `preferences`/`potagers`. I/O fichier isolé derrière `AbstractGestionnaireSauvegardeFichier` (testable). Deps **share_plus + file_picker** validées (dev 2026-06-13), 100 % local. Tests : service de sauvegarde (déjà) + `panneau_donnees_test.dart` (export, import remplacer/annulé/invalide). **CSV** : non retenu (JSON structuré et ré-importable ; CSV lecture-seule à ajouter plus tard si besoin). Reste : **appairage d'appareils** = fonctionnalité réseau locale à concevoir (séparé). | Appairage (réseau local) à concevoir ; CSV optionnel. |
| **Réinitialiser toutes les données** | ✅ | `AbstractReinitialisationService` (`ReinitialisationServiceImpl` : wipe générique de toutes les tables dans une transaction + reseed du singleton préférences aux défauts → `onboardingTermine=false`). Branché dans `PanneauDonnees` avec **double confirmation** (`confirmerAction` ×2, destructif) ; après wipe, invalidation `preferences`/`potagers` → la garde router **relance l'onboarding** (reset usine). Tests : `reinitialisation_service_test.dart` (wipe + reseed) + `panneau_donnees_test.dart` (double confirmation / annulation). | — |
| **Catégorie « Transparence des données »** | ⚪ | Tableau des tailles par table + journal d'accès. Nécessite des stats de taille de la base (drift) + un journal d'accès (inexistant). | Ajouter une lecture de stats DB + (éventuel) journal d'accès. |
| **Récupération météo auto** (toggle) | ⚪ | La maquette a ce switch, mais **aucun champ** correspondant sur `PreferencesUtilisateur`. | Ajouter le champ (entité + drift) si on garde l'option, ou la dériver du mode géoloc. |
| **Ne pas déranger (créneau horaire)** | 🔵 champs présents, non exposés | `PreferencesUtilisateur` a `nePasDerangerDebut/Fin` mais pas de `copierAvec` pour eux (méthodes `avecNePasDeranger`/`sansNePasDeranger`) ; pas de sélecteur d'heure dans l'UI. | Ajouter le toggle + time-pickers, brancher sur `avecNePasDeranger`. |
| **Version dynamique** | 🔵 constante en dur | Lire la version au runtime = `package_info_plus` (hors stack validée). | Ajouter la dépendance (à valider) ou générer la version au build. |
| **Liens externes** (code source, doc, bug) | 🔵 lignes présentes, inertes | Ouvrir une URL = `url_launcher` (hors stack validée). | Ajouter la dépendance (à valider) puis brancher les `onTap`. |
| **Langue effective** | 🔵 préférence persistée | Le choix de langue est **stocké** mais l'app ne réagit pas encore (un seul ARB `fr` ; `MaterialApp.locale` pas piloté). | Ajouter l'ARB `en` + piloter `locale`/`localeResolutionCallback` depuis la préférence. |

---

## 7. Milestone « Alpha installable » (Android) — état & reste à faire

> Objectif du jalon : un APK installable sur téléphone Android, **utilisable**
> (création de potager / zone / plantation), pour un premier retour terrain.

### Fait pour l'alpha
- **Config Android** : permissions `INTERNET` (Open-Meteo), `POST_NOTIFICATIONS`,
  localisation (opt-in) ; label « Pot'à Gérer » ; desugaring activé
  (`flutter_local_notifications`) ; release signé avec la clé **debug**.
- **Formulaires de création** (`lib/presentation/forms/`) : potager, zone,
  plantation — branchés sur les use cases existants, persistés, testés.
- **Points d'entrée** : écran Potager → bouton « Créer un potager » (état vide),
  FAB « Ajouter une zone », tap sur une zone → « Ajouter une plantation ».

### À faire après l'alpha (priorité descendante)
| Élément | Pourquoi différé | Où / comment |
|---|---|---|
| **Onboarding localisation** | ✅ **Lots 1–3** (Lot 4 différé) | Position définissable à 3 endroits, via une feuille/actions partagées (`capture_localisation.dart`) : **création du potager** (« Détecter ma position » GPS + **carte monde**, dérivation `DerivateurLocalisation` qui pré-remplit climat/rusticité) ; **carte météo de l'accueil** (uniquement si aucune position) ; **paramètres › Confidentialité** (ligne « Position » pilotée par le mode : GPS → détection, Manuelle → **carte monde** ; **changer le mode réinitialise la position à null**). Mutations centralisées dans `position_potager_actions.dart` (`enregistrer`/`reinitialiser` + invalidations). → hémisphère réel (Saison/fiche) + météo. **Plan lotté (validé dev 2026-06-13)** — **Lot 1 ✅** : drapeau `PreferencesUtilisateur.onboardingTermine` (+ colonne drift `onboarding_termine`, **migration schéma v1→v2** `addColumn`) ; `GoRouter.redirect` gardant l'app sur `/onboarding` (route hors shell, `EcranOnboarding`) tant que faux, refermé une fois terminé (`refreshListenable` sur les préférences ; route exclue de la pile de navigation) ; `PreferencesNotifier.terminerOnboarding`. **Lot 2 ✅** : **carte monde cliquable** (`selecteur_carte_monde.dart`, `choisirSurCarteMonde`) — **image équirectangulaire embarquée** (`assets/images/carte_monde.jpg`, NASA Blue Marble, domaine public, plate carrée plein globe ; provenance dans `carte_monde.SOURCE.txt`) + **projection linéaire** pure/testable `ProjectionEquirectangulaire` (tap→(lat,lon)), **zoomable** (`InteractiveViewer` pinch/pan, l'utilisateur choisit sa précision ; **la zone interactive remplit toute la hauteur dispo**, image contenue proportionnelle), **pin** à taille écran constante (re-projeté via la transform), **presets de régions** (puces qui recentrent + posent le pin). Remplace `choisirRegion` (supprimé) **partout** (feuille de capture, `FormulairePotager`, Confidentialité). **Pas de package carto** (100 % local, conforme stack). **Lot 3 ✅** : **parcours guidé complet** (`EcranOnboarding`, `PageView` 6 étapes : bienvenue → vie privée/opt-out → position **requise** → confirmation climat/rusticité dérivés (éditables via `ChampDeroulantDecrit`) → **1er potager** (nom) → opt-in notifs ; indicateur à puces, Précédent/Suivant/Terminer). La finalisation **crée le 1er potager** (position + climat), fixe le **mode géoloc** (GPS/manuel selon la source) + le choix notifs, puis lève la garde. **Décision appliquée : position OBLIGATOIRE à la création d'un potager** — `FormulairePotager` refuse `Localisation.nonDefinie` (message inline `formPotagerPositionRequise`). Tests : `onboarding_test.dart` (parcours complet → création + bascule Potager), formulaire (garde-fou). **Affinements (retour de test 2026-06-15, ADR-0009 Lot 1)** : la **position auto-avance** une fois choisie (#1) ; nouvelle **étape « niveau d'expérience »** (cartes sélectionnables + descriptions `niveauDescription`, finalisation `definirNiveau` — socle d'[ADR-0009](decisions/0009-paliers-experience-divulgation-progressive.md)) (#2) ; l'**étape potager** porte une section **« Zones de culture »** réutilisant `ouvrirFormulaireZone` via **création paresseuse** du potager (nom verrouillé une fois créé) (#3) ; fin d'onboarding → **panneau Potager** + **bulle d'astuce** « touchez une zone » (`astuce_post_onboarding.dart`, éphémère) (#4) ; **invalidation large** des vues après reset **et** onboarding (`invalidation_vues.dart::invaliderVuesDonnees`) → fini l'accueil périmé (#5). **2ᵉ retour** : les zones ajoutées s'affichent en **cartes** (grille 2 colonnes, bordure colorée + nom, façon plan Potager mais widget séparé `_CarteZone`) au-dessus du bouton ; **garde élargie** — l'onboarding n'apparaît que si **aucune donnée** au lancement (`!onboardingTermine && potagers.isEmpty`, le router écoute `potagersProvider`) → une base pré-existante (flag faux par migration) **n'écrase plus** les données réelles. **Fix (régression)** : la création **paresseuse** du potager pendant l'onboarding faisait croire à des « données » → le redirect **éjectait vers Potager au milieu du flux**. Corrigé : **une fois sur `/onboarding`, seul `onboardingTermine` lève la garde** (la garde « aucune donnée » ne s'applique qu'à l'entrée). Test stateful dédié. **3ᵉ retour** : sélecteur de carte — bande de régions **en haut**, bouton **« Valider »** en **bas à droite** (FilledButton, même style que « Suivant ») ; étape **notifications** de l'onboarding montre le **détail par catégorie** (maître + 6 catégories, comme le panneau Réglages) **dès intermédiaire** (débutant = maître seul) — catégories partagées via `categoriesNotifications`. Reste — **Lot 4 (différé)** : dérivation climat/rusticité fine via Open-Meteo (altitude). | Affiner la dérivation (Lot 4, différé). |
| **Signing release réel** | L'APK alpha est signé avec la clé **debug** (suffisant pour sideload, **pas** pour le Play Store ni des mises à jour propres). | Générer un keystore, configurer `signingConfigs.release` dans `android/app/build.gradle.kts` (+ `key.properties` hors VCS). |
| **Icône & splash de l'app** | Icône Flutter par défaut. | `flutter_launcher_icons` / `flutter_native_splash` (deps à valider) ou ressources manuelles. |
| **Édition / suppression** (~~potager~~, ~~zone~~, ~~plantation~~, ~~tâche~~) | **Potager** (menu en-tête de l'onglet Potager → édition `FormulairePotager` en place / suppression en cascade soft via `AbstractPotagerRepository.supprimer`), **zone**, **plantation** et **tâche** câblés. La **tâche** : menu ⋮ par carte (Agenda + Mois) → édition (`FormulaireTache` en mode édition, reconstruit avec le même id) / suppression (`AbstractTacheRepository.supprimer`, confirmation). Reste le **swipe** (cf. §6 `sens_swipe`). | Swipe à généraliser. |
| **Récolte** depuis l'UI | ✅ | `FormulaireRecolte` (date, quantité + unité, destination) via `CreerRecolte`, action **« Récolter »** du menu de culture (détail de zone) ; rafraîchit le compteur de récoltes de l'accueil. |
| **Observation** depuis l'UI | ✅ | `FormulaireObservation` (type, titre, date, description) via `CreerObservation`, action **« Observer »** du menu de culture (détail de zone, cible = plantation). |
| **Météo / alertes réelles** | cf. §2 (Accueil) — placeholders. | Brancher `meteoServiceProvider` une fois la localisation disponible. |
| **iOS / desktop packaging** | Alpha = Android d'abord. | `flutter build ipa` / Linux/Windows/macOS plus tard. |
| **CI/CD (build APK auto)** | Pas de pipeline. | GitHub Actions (cf. CLAUDE.md « à venir »). |

---

## 8. Lot d'améliorations UX (revue dev — 2026-06-11)

> Backlog issu d'une revue du dev. Ordre de départ proposé : **A** (bug
> d'intégrité, contenu), puis **B**, **C/D**, enfin **E** (gros chantier).
> État : ⚪ non commencé sauf mention.

### A. Correction — intégrité des données
| # | Élément | État | Ce qui manque / où | 
|---|---|---|---|
| 1 | **Suppression → lignes de planification orphelines** | ✅ | Les 3 repos (`potager`/`parcelle`/`plantation`) cascade désormais les **`taches`, `rappels` et `observations`** ciblant l'élément supprimé **ou n'importe quel descendant** de sa hiérarchie, via le helper partagé `suppression_cascade.dart::soustraireLignesDePlanification`. La suppression potager scope aussi les **équipements par `potagerId`** (corrige la fuite des équipements de niveau potager, `parcelleId` null) ; la suppression parcelle inclut les équipements de la parcelle. Tests : `supprimer cascades to the whole hierarchy and its planning rows` (potager), `…to planning rows of the parcelle and its children` (parcelle), `…to its planning rows, sparing other plantations` (plantation). |

### B. Pédagogie inline (descriptifs à côté des choix)
| # | Élément | État | Ce qui manque / où |
|---|---|---|---|
| 2 | **Descriptifs climat & rusticité** | ✅ | Widget réutilisable `champ_deroulant_decrit.dart::ChampDeroulantDecrit<T>` : menu affichant un court descriptif sous chaque option (champ fermé = libellé seul via `selectedItemBuilder`). Branché sur **climat** et **rusticité** dans `FormulairePotager` (création **et** édition — seul endroit où ces champs vivent). Descriptions dans `LibellesEnums.climatDescription` / `rusticiteDescription` (rusticité = plage de température minimale USDA par zone) + clés ARB `climat*Desc` / `rusticiteZoneDesc`. |
| 3 | **Renommer « Méthode » → « Type » + aide** | ✅ | Champ `methode` du `FormulairePlantation` renommé **« Type de mise en place »** (clé `formPlantationMethode`, valeur FR mise à jour) — lève la confusion avec les méthodes de culture. Mêmes options décrites via `ChampDeroulantDecrit` + `LibellesEnums.methodeDescription` (clés ARB `methode*Desc`). |

### C. Aide & lexique
| # | Élément | État | Ce qui manque / où |
|---|---|---|---|
| 4 | **Panneau « Aide & lexique »** | ⚪ | Nouveau panneau accessible depuis l'onglet **Plus** : définitions détaillées de chaque terme propre au potager + tips. Les mêmes tips s'afficheront **en bulles contextuelles au bon moment**, l'utilisateur pouvant toujours revenir ici. Prévoir un modèle de contenu (terme → définition → tip) réutilisé par les bulles. **Modèle partagé avec les mini-tutos par palier d'[ADR-0009](decisions/0009-paliers-experience-divulgation-progressive.md) §4a** (feature → pourquoi → comment) et le teaser de montée de palier. Lien avec §6 (menu Plus). |

### D. Navigation
| # | Élément | État | Ce qui manque / où |
|---|---|---|---|
| 5 | **Tuile zone (Accueil) → vue zone du panneau Potager** | ✅ | La tuile zone de l'accueil fait `go('/potager/zone/:id')` (`ecran_accueil.dart`) : **bascule sur l'onglet Potager** affichant la zone. Le détail de zone n'est plus enregistré sous la branche Accueil (route retirée du router) ; le **retour ramène directement à l'accueil** via la pile transverse (#6). |
| 6 | **Re-tap onglet = racine ; retour = écran précédent (même inter-panneau)** | ✅ | **Historique global partagé** (façon navigateur) : `PileNavigation` (`lib/app/historique_navigation.dart`, `pileNavigationProvider`) tient la liste ordonnée des locations, alimentée par un listener unique sur le `routerDelegate` (`routeurProvider`). Le shell enveloppe l'`EchafaudageNavigation` dans un **`PopScope`** : `canPop` faux tant qu'il reste un précédent, le retour fait `go(precedent)` (le listener reconnaît un retour et dépile) ; à la racine, l'OS quitte. **Tout tap d'onglet** (re-tap *ou* inactif) fait `goBranch(initialLocation: true)` → racine garantie ; un parcours profond se rejoue via le **bouton retour**, jamais en re-sélectionnant l'onglet. L'`indexedStack` reste (préservation de l'état des 5 **racines**). Tests : `historique_navigation_test.dart` (logique de pile) + `navigation_test.dart` (reset onglet, retrace sous-route + onglets). |

### E. Refonte de la vue Réseau (Catalogue) — gros chantier
> `VueReseauCatalogue` (`vue_reseau_catalogue.dart`) est aujourd'hui ✅ (spirale de
> Fermat, arêtes CustomPaint, sélection → voisins + panneau). Ce lot la fait évoluer
> en vue exploratoire scalable. **Cadrage acté : [ADR-0007](decisions/0007-vue-reseau-exploratoire.md)**
> (modèle de transformation explicite + découpage en lots). **Phase 1 (#7 + #8a) livrée.**

| # | Élément | État | Ce qui manque / où |
|---|---|---|---|
| 7 | **Zoom / déplacement** | ✅ | Modèle de transformation explicite `_TransformReseau` (échelle + offset, ADR-0007) : **pinch + pan x/y** (un `GestureDetector(onScaleUpdate)` enveloppant) + **boutons +/−/recentrer** (`_ControlesZoom`). Baseline = fit-to-width centré (= cible « recentrer »). Tests dans `vue_reseau_catalogue_test.dart`. |
| 8 | **Sélection → noms complets + recadrage intelligent** | ✅ | **#8a** : sélection → **noms complets** (`_EtiquetteNoeud`) sur le node sélectionné **et ses liés**, à **taille écran constante** (libellés hors transform, centrés par décalage −50 % de largeur) + **recadrage animé** zoom-to-fit (`_ajusterSur` + `AnimationController`, `_TransformReseau.lerp`). **#8b** : **anti-chevauchement actif** — décalage par node en unités virtuelles (`_decalages`, jamais appliqué aux positions canoniques), calculé par séparation AABB itérative des empreintes disque+libellé (`_resoudreChevauchement`, tailles mesurées au `TextPainter`, marge `_ecartLabel` pour un écart visible entre voisins), animé avec le recadrage ; arêtes attachées aux positions déplacées. Recalcul à la sélection / au toggle / au recentrage **et** une fois ~1 s après la fin d'un pan/zoom manuel (timer débouncé `_planifierReajustement`, `_delaiReajustement`) → corrige le re-chevauchement après dézoom sans recalcul continu. Tests dans `vue_reseau_catalogue_test.dart`. |
| 9 | **Node espèce → liste des variétés** | ✅ | Vue Réseau en **deux zones indépendantes** (`Stack`) : **BOX 1** = réseau interactif (pan/zoom/clic), dimensionné à l'espace au-dessus de la feuille ; **BOX 2** = `DraggableScrollableSheet` (toggle + panneau + **variétés** de l'espèce, `_LigneVarieteReseau` dérivé de `varietesDe`). Drag BOX 1 = pan/zoom ; drag BOX 2 = la feuille grandit et BOX 1 rétrécit (sans recouvrement). |
| 10 | **Scroll bas → réduire la tuile réseau, place aux fiches** | ✅ | BOX 2 **plafonnée à la moitié de l'écran** (`_feuilleMax = 0.5`) → BOX 1 ne descend jamais sous 50 % ; au-delà, la feuille scrolle en interne. **Comportement uniforme** (décision dev, revoyure) : la vue réseau est **identique que BOX 1 soit réduite ou pas** — bulles + noms complets + anti-chevauchement, **toujours** (pas de mode « compact/initiale »). Re-cadrage débouncé quand BOX 1 change de taille (`_planifierRecadrageTaille`). ⚠️ Avec beaucoup de compagnons (ex. Laitue, 17), les libellés peuvent **sortir de l'écran** (accepté). **Suite cadrée par [ADR-0008](decisions/0008-vue-reseau-familles-et-focus.md)** : layout par **bulles de famille**, **mode focus** (ego-réseau bon/à-éviter), recherche par nom. **Lot 1 ✅** : **compteurs alignés** — résolveur unifié (`domain/services/resolveur_compagnonnage.dart`, bidir + toutes espèces) consommé par la vue Réseau **et** la fiche → mêmes compteurs/listes (fini l'écart 17 / 2 / 0 ; la fiche liste tous les compagnons, hors filtre). **Lot 2 ✅** : `LayoutReseauFamilles` (packing de cercles déterministe + spirale phyllotaxique interne) **remplace la spirale de Fermat** — familles **jamais chevauchantes**, **halos blobby** lissés (`reseau/halo_famille.dart`, `_PeintreFoyers`) sous les nœuds, baseline recadrée sur l'union des bulles. **Lot 5 ✅** : **recherche par nom** dans la vue Réseau (`_BarreRecherche` : champ overlay, normalisation casse/accents, sélectionne + recadre le nœud trouvé, message « aucun résultat »). **Lot 4 ✅** : **mode Focus additif** — bouton « Focus » du panneau ouvrant un **ego-réseau dédié** (`_VueFocus` : espèce au centre, **bons à gauche / à-éviter à droite**, légendes, emplacement raison réservé, état vide) ; le clic conserve le recadrage + anti-chevauchement (rien jeté). **Deux vues distinctes (revue dev)** : **« Réseau »** (constellation) — cliquer une plante regroupe ses **liens par famille** en un nœud unique (`_GroupeFocusReseau` : famille au‑dessus, espèces listées dessous, **cliquables → re‑focus** ; supersède l'anti‑chevauchement #8b en focus) ; **« Associations »** (`vue_associations.dart`, `afficherVueAssociations`) — vue **détail dégroupée** d'une espèce (une espèce = un nœud, bons/à‑éviter séparés, emplacement raison réservé pour ADR‑0006 Lot 4), **ouverte depuis la vue Fiches** (bouton ⬡ par carte d'espèce). **Affinements UX (revue dev)** : bulles **scalées au zoom** (petites au dézoom → pleines au zoom, plafonnées ; déroge à la taille constante d'ADR-0007), **noms affichés en vue globale dès qu'ils tiennent sans chevauchement** (`_labelsQuiTiennent`), focus plus lisible (nœuds non liés atténués + réduits de moitié, halos inchangés, seuls les labels des familles du focus restent), labels de famille en **pastille au-dessus du halo**, recherche **repliée en bouton loupe** (effacer = retour vue globale, tap‑dehors si vide = repli). **Labels de relation** vert/rouge en focus, **menu de contrôles replié** (zoom + bascules **liens** / **noms de famille**, tap‑dehors referme), **Focus regroupé par famille** (`_GroupeFocus` : famille au‑dessus, espèces listées en dessous). **Tweaks post‑lots (revue dev)** : **#1** compteur de variétés retiré de la vue Fiches (flèche seule, `_CarteFiche`) ; **#2** la **plante sélectionnée fusionne dans le nœud de sa propre famille** en focus (groupe `{sel, …voisins}`, sélection listée en premier/neutre, liens vert/rouge, plus de disque « sélectionné » distinct → on rouvre sa fiche via son **nom**) ; **#3** **hitbox agrandie « au plus proche »** (`onTapUp` canvas → nœud le plus proche à ≤ 28 px, cellules Voronoï non chevauchantes/déformables ; taps précis sur disque/label/contrôle captés par l'arène ; tap+scale → 1er segment de pan absorbé par le slop, accepté). Reste : rendu **canvas** des nœuds (perf, différé) + lot bloqué « raisons » (ADR-0006 Lot 4). |
| 11 | **Scroll bas → sections « Bon(s) compagnon(s) » / « À éviter » avec raisons** | ⚪ (dépend ADR-0006 Lot 4) | Plus bas, 2 sections listant compagnons / à éviter, chacune indiquant **en petit la raison** (ex : « maladie commune : mildiou », « compétition pour la lumière », « complémentarité lumière »). ⚠️ Les *raisons* ne sont **pas en données** : le contenu éditorial famille (`_familles/*.yaml` : `ennemis_communs_note`, `associations_note`) est **vide** et le référentiel maladies/ravageurs n'est pas normalisé (cf. §4 Lot 4). Pré-requis data avant l'UI. |

### F. Réglages localisation — climat/rusticité éditables (suivi lot B)
> Issu d'une revue dev pendant le lot B : le climat/rusticité n'étaient éditables
> que via le formulaire de potager. Décision : **rester par-potager** (pas de
> préférence globale), mais le **répercuter dans les réglages**.

| # | Élément | État | Détail |
|---|---|---|---|
| F1 | **Climat/Rusticité dans Confidentialité (potager actif)** | ✅ | Sous « Géolocalisation », sous-bloc tabulé au nom du **potager actif** : **Position + Climat + Rusticité**, toujours visibles (même géoloc désactivée), valeur affichée, éditables. Climat/Rusticité via `selecteur_decrit.dart::choisirOptionDecrite` (feuille modale réutilisant les descriptifs du lot B) → `enregistrerZoneClimatiquePotager` (mute la `ZoneClimatique` du potager actif). Sans potager actif → ligne d'invite. Libellés des 3 modes géoloc clarifiés (Aucune / Région / GPS + sous-textes impact météo). `panneau_confidentialite.dart`, helper `_LigneReglage`. Accueil inchangé (capture position **uniquement** si aucune position). |
| F2 | **Multi-potager (autres potagers grisés/dépliables)** | ⚪ | Phase 2 : lister les **autres** potagers (nom + chevron dépliable), valeurs **grisées non modifiables** (seul l'actif est éditable). Surtout de l'UI ; aucun changement de modèle. Lire `potagersProvider` (liste) en plus de `potagerActifProvider`. **Déclencheur** : à faire quand on ajoutera l'action **« Ajouter un potager »** au panneau Potager (à côté de modifier/supprimer déjà présents). |
| F3 | **Visibilité du sous-bloc tabulé** | ⚪ | Améliorer la lisibilité du regroupement par-potager (la tabulation actuelle est discrète) : ex. **fond de texte / surface légèrement contrastée** sur le bloc, et/ou une **tranche cliquable à gauche** (sur la tabulation elle-même) pour **dérouler/replier** les infos du potager. Basse priorité, à cadrer visuellement. `panneau_confidentialite.dart` (`_LigneReglage` + en-tête nom). |

---

## 9. Paliers d'expérience — features réservées (« build-then-gate », ADR-0009)

> Issues du **recadrage du Lot 3** d'[ADR-0009](decisions/0009-paliers-experience-divulgation-progressive.md).
> Ces features sont **réservées par la politique `AccesNiveau`** (prédicat déjà
> prêt) mais n'ont **pas encore d'UI ni la donnée** : elles relèvent de
> « **construire la feature, puis la gater** », pas d'un simple masquage. À leur
> construction : **gater via `AccesNiveau`** et respecter les garde-fous (cœur
> jamais bloqué ; réversible/non destructif — données conservées, contrôles
> masqués). Le gating « features déjà câblées » (Vue Réseau, Vue Saison,
> Observations, lunaire, granularité notifs, stats, **sol texture/pH/techniques**)
> est, lui, **fait** (Lots 2–3).

| Feature | Palier | Manque (à construire) | Où / prédicat |
|---|---|---|---|
| **Multi-potager** | inter+ | un **sélecteur de potager actif** (aucun `setActif`/`definirActif` sur `AbstractPotagerRepository` — un seul actif aujourd'hui) **+** une action **« Ajouter un potager »** (créer un 2ᵉ jardin). Voir aussi §8 **F2** (UI réglages multi-potager grisés). | `acces.multiPotager` ; `ecran_potager.dart` (menu en-tête) + repo (notion d'actif) |
| **Équipements / outils** | inter+ | **toute l'UI** (liste + formulaire d'`Equipement`) — seuls existent l'entité, la table et les libellés. | `acces.equipements` |
| **Fiches plantes perso** (contribution) | expert | **toute l'UI** (créer/éditer une fiche perso) — seule existe la table `fiches_plantes_personnelles`. | `acces.fichesPerso` |
| **Rotation avancée** | expert | **UI de rotation** (précédents culturaux, délai de retour famille) — la donnée `rotation` existe sur la fiche, mais **aucun écran**. | `acces.rotationAvancee` |
| **Besoins en eau détaillés** | expert | **donnée fiche manquante** : `BesoinsCulture` ne porte que le terme grossier (`BesoinEau` : beaucoup/moyen/peu), **pas** de fréquence/quantité. Enrichir les fiches d'abord, puis afficher le détail en **expert** (le terme grossier reste pour déb./inter.). | `acces.eauDetaillee` ; `fiche_plante_detail.dart` |

> **Lot 4 d'ADR-0009 (à venir)** : **mini-tutos par palier** (features débloquées :
> pourquoi/comment, présentés à l'atteinte du palier + re-consultables) **+
> teaser** de montée de palier — modèle de contenu commun avec « Aide & lexique »
> (§8 C4).

---

## 10. Comment utiliser ce registre

- En reprenant un sujet, **chercher son entrée ici** : la colonne « Où revenir »
  pointe le fichier/fonction exact à modifier.
- Quand une entrée passe 🔵/⚪ → ✅, **mettre à jour la ligne** (ou la retirer si
  totalement résolue) dans le même commit.
- Les nouveaux placeholders introduits par les prochains écrans (Catalogue,
  Calendrier, Plus) **s'ajoutent ici** au fur et à mesure.
