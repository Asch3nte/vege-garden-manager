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
| **Navigation inter-écrans** | 🔵 avancée | Sous-routes go_router en place : `/potager/zone/:id` → `EcranZoneDetail` (atteint depuis le plan **et** les tuiles de l'accueil) et `/plus/{general,confidentialite,notifications,apropos}` (re-tap de l'onglet Plus → retour racine). Restent détail tâche, fiche plante en route dédiée. | Ajouter les sous-routes go_router restantes dans `lib/app/router.dart` au fil des écrans. |

---

## 2. Écran Accueil (`lib/presentation/screens/ecran_accueil.dart`)

Données réelles déjà branchées : nom du potager actif, zones, **tâches du jour**,
**niveau d'expérience** (→ divulgation progressive). Le reste :

| Élément | État | Ce qui manque | Où revenir |
|---|---|---|---|
| **Carte météo + verdict d'arrosage** | ✅ | — | `MeteoAccueilNotifier` (`meteoAccueilProvider`) : températures du jour + **verdict d'arrosage** niveau jardin (pluie à venir / sol humide / arroser / clément, seuils de `BilanArrosage`) depuis `meteoServiceProvider` + la **position du potager actif**. `_CarteMeteo` branché ; invite à renseigner la position si aucune (cf. onboarding §7). **Position connue → la carte ouvre le détail horaire** (`EcranMeteoDetail` : sélecteur de jour + prévisions par heure ; `obtenirPrevisionsHoraires` Open-Meteo + `PrevisionHoraire`). |
| **Tuile « Alerte »** | ✅ | — | `AccueilNotifier` compte les alertes via `detecterAlertesMeteo` (localisation du potager + plantations actives ; 0 sans position / météo indispo) → `AccueilVue.nombreAlertes` → `_GrilleStats`. |
| **Tuile « Récoltes de la saison »** | ✅ | — | `AccueilNotifier` agrège les récoltes de l'année courante (itère les plantations × `obtenirParPlantation`) → `AccueilVue.nombreRecoltesSaison` → tuile niveau Expert. |
| **Niveaux d'expérience 4 → 3** | ✅ (décision) | La maquette a 4 paliers (Découverte/Apprenti/Jardinier/Expert), le domaine `NiveauExperience` en a 3 (debutant/intermediaire/expert). | Décision actée : domaine fait foi, stats au niveau **Expert**. À rouvrir seulement si on enrichit l'enum. |
| **Actions d'en-tête** (cloche notifs, menu ⋮) | ⚪ | Écran notifications + menu contextuel. | À l'implémentation de ces écrans. |
| **Navigation depuis les sections** (« voir les tâches », tuile zone…) | 🔵 zone faite | **Tuile zone → détail** branché (`push('/accueil/zone/:id')` — le détail est aussi une sous-route de la branche Accueil, pour que le retour système revienne à l'accueil et non au plan Potager). Reste « voir les tâches » → Calendrier. | Brancher le `onTap` des tâches vers le Calendrier. |

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
| **Détail d'une zone** | 🔵 fonctionnel, stades à venir | `EcranZoneDetail` complet : nom, type, surface, expo, cultures + **« Ajouter une plante »** (§4) + par culture **Arracher** (statut `arrachee`, garde l'historique) / **Supprimer** (soft delete, confirmation) + **Modifier** / **Supprimer** la zone (soft delete en cascade logique → historique conservé ; confirmation). `ZonePotager.cultures` porte désormais l'id de plantation (`CulturePotager`). Restent les cultures **détaillées** (stade de croissance, prochaine tâche). | Stade = calculateur application (`Plantation.dateMiseEnPlace` + durées `FichePlante`) ; tâche par culture = lien tâche↔plantation. |
| **Stade de croissance par culture** (Semis→Récolte) | ⚪ | Un **modèle de croissance** : aucune notion de stade dérivable aujourd'hui (il faudrait `dateMiseEnPlace` + durées de la fiche + courbe de stades). | Concevoir un calculateur de stade (application) à partir de `Plantation.dateMiseEnPlace` et des durées `FichePlante`. |
| **Tâche « prochaine » par culture** | ⚪ | Les tâches sont liées à une **parcelle** (`CibleTache.parcelle`), pas à une plantation/culture. Pas de lien tâche↔culture. | Décider du rattachement (cible `plantation` ?) puis requête par culture. |
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
| **Liste des variétés** | 🔵 clé i18n prête (`catalogueNbVarietes`) | Aucun champ « variétés » sur `FichePlante`. | Ajouter au modèle (YAML + entité) puis l'afficher dans la fiche. |
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
| **Zone / culture / variété sur la carte** | 🔵 type + titre réels | La maquette affiche la zone (pastille colorée) + culture + variété ; ici on montre `titre` (réel) + type. La tâche porte `cible`/`cibleId` mais pas la culture/variété. | Résoudre la zone via le parcelle repo (`cible == parcelle`) ; culture/variété = nécessite un lien tâche↔plantation (cf. §3). |
| **Filtre / Ajout de tâche** (en-tête) | ✅ | — | Bouton **+** → `FormulaireTache` (intitulé, type, date, cible = potager ou zone, via `CreerTache`) ; bouton **filtre** → menu par type de geste (`CalendrierNotifier.definirFiltreType`, applique sur Agenda + Mois). |
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
| **Catégorie « Synchronisation & sauvegarde »** | ⚪ | Appairage d'appareils + **export JSON/CSV** + import. `sauvegardeServiceProvider` existe (infra) mais n'est pas branché à une UI. | Brancher `AbstractSauvegardeService` à un panneau Sync ; appairage = fonctionnalité réseau locale à concevoir. |
| **Réinitialiser toutes les données** | ⚪ | Action destructive (double confirmation + wipe réel). | Brancher sur un service de purge + dialogue à double confirmation. |
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
| **Onboarding localisation** | 🔵 capture faite | Position définissable à 3 endroits, via une feuille/actions partagées (`capture_localisation.dart`) : **création du potager** (« Détecter ma position » GPS + sélecteur de région, dérivation `DerivateurLocalisation` qui pré-remplit climat/rusticité) ; **carte météo de l'accueil** (uniquement si aucune position) ; **paramètres › Confidentialité** (ligne « Position » pilotée par le mode : GPS → détection, Manuelle → région ; **changer le mode réinitialise la position à null**). Mutations centralisées dans `position_potager_actions.dart` (`enregistrer`/`reinitialiser` + invalidations). → hémisphère réel (Saison/fiche) + météo. Reste : **prochaine itération du choix manuel → une carte monde cliquable** (tap → lat/long, plus précis que le sélecteur de régions actuel) ; écran d'onboarding dédié au 1er lancement ; dérivation climat/rusticité plus fine (Open-Meteo). | Carte monde interactive (package à valider ou image équirectangulaire + mapping tap→coords) ; flux d'onboarding ; affiner la dérivation. |
| **Signing release réel** | L'APK alpha est signé avec la clé **debug** (suffisant pour sideload, **pas** pour le Play Store ni des mises à jour propres). | Générer un keystore, configurer `signingConfigs.release` dans `android/app/build.gradle.kts` (+ `key.properties` hors VCS). |
| **Icône & splash de l'app** | Icône Flutter par défaut. | `flutter_launcher_icons` / `flutter_native_splash` (deps à valider) ou ressources manuelles. |
| **Édition / suppression** (~~potager~~, ~~zone~~, ~~plantation~~, tâche) | **Potager** (menu en-tête de l'onglet Potager → édition `FormulairePotager` en place / suppression en cascade soft via `AbstractPotagerRepository.supprimer`), **zone** et **plantation** câblés. Reste **tâche** (édition) et le **swipe** (cf. §6 `sens_swipe`). | Édition de tâche = formulaire en mode édition ; swipe à généraliser. |
| **Récolte** depuis l'UI | ✅ | `FormulaireRecolte` (date, quantité + unité, destination) via `CreerRecolte`, action **« Récolter »** du menu de culture (détail de zone) ; rafraîchit le compteur de récoltes de l'accueil. |
| **Observation** depuis l'UI | ✅ | `FormulaireObservation` (type, titre, date, description) via `CreerObservation`, action **« Observer »** du menu de culture (détail de zone, cible = plantation). |
| **Météo / alertes réelles** | cf. §2 (Accueil) — placeholders. | Brancher `meteoServiceProvider` une fois la localisation disponible. |
| **iOS / desktop packaging** | Alpha = Android d'abord. | `flutter build ipa` / Linux/Windows/macOS plus tard. |
| **CI/CD (build APK auto)** | Pas de pipeline. | GitHub Actions (cf. CLAUDE.md « à venir »). |

---

## 8. Comment utiliser ce registre

- En reprenant un sujet, **chercher son entrée ici** : la colonne « Où revenir »
  pointe le fichier/fonction exact à modifier.
- Quand une entrée passe 🔵/⚪ → ✅, **mettre à jour la ligne** (ou la retirer si
  totalement résolue) dans le même commit.
- Les nouveaux placeholders introduits par les prochains écrans (Catalogue,
  Calendrier, Plus) **s'ajoutent ici** au fur et à mesure.
