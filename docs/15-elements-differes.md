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
| **Navigation inter-écrans** | ⚪ | Les écrans existent mais ne se naviguent pas encore entre eux (pas de routes de détail). | Ajouter les sous-routes go_router (détail zone, détail tâche, fiche plante…) dans `lib/app/router.dart` au fil des écrans. |

---

## 2. Écran Accueil (`lib/presentation/screens/ecran_accueil.dart`)

Données réelles déjà branchées : nom du potager actif, zones, **tâches du jour**,
**niveau d'expérience** (→ divulgation progressive). Le reste :

| Élément | État | Ce qui manque | Où revenir |
|---|---|---|---|
| **Carte météo + verdict d'arrosage** | 🔵 placeholder `_CarteMeteo` | Un *verdict* (« bon pour arroser », pluie à venir) calculé à partir de `AbstractMeteoService` + `calculer_besoin_arrosage`. Le service météo existe mais aucune logique de verdict UI. | Créer un petit calculateur de verdict (application) consommant `meteoServiceProvider` (localisation du potager actif) ; brancher dans `_CarteMeteo`. |
| **Tuile « Alerte »** | 🔵 placeholder `_TuileStat` | Agrégat du nombre d'alertes météo actives. `detecter_alertes_meteo` / `evaluateur_alertes_meteo` existent mais pas exposés en provider d'état pour l'accueil. | Exposer un provider « alertes actives » et compter dans `_GrilleStats`. |
| **Tuile « Récoltes de la saison »** | 🔵 placeholder (visible niveau Expert) | Un agrégat « nb de récoltes cette saison ». Pas de requête agrégée sur `AbstractRecolteRepository`. | Ajouter une lecture agrégée (récoltes de la saison en cours) et la brancher dans `AccueilNotifier` + `_GrilleStats`. |
| **Niveaux d'expérience 4 → 3** | ✅ (décision) | La maquette a 4 paliers (Découverte/Apprenti/Jardinier/Expert), le domaine `NiveauExperience` en a 3 (debutant/intermediaire/expert). | Décision actée : domaine fait foi, stats au niveau **Expert**. À rouvrir seulement si on enrichit l'enum. |
| **Actions d'en-tête** (cloche notifs, menu ⋮) | ⚪ | Écran notifications + menu contextuel. | À l'implémentation de ces écrans. |
| **Navigation depuis les sections** (« voir les tâches », tuile zone…) | ⚪ | Routes de détail (cf. §1). | Brancher les `onTap` vers Calendrier / détail zone quand les routes existent. |

---

## 3. Écran Potager (`lib/presentation/screens/ecran_potager.dart`)

Réalisé : **variante C** de la maquette (liste des zones), données réelles
(potager actif, zones, cultures via catalogue, drapeau « tâche du jour »).

| Élément | État | Ce qui manque | Où revenir |
|---|---|---|---|
| **Plan en grille** (variante A) | ⚪ | Vue « planches » carrées + légende. Purement présentationnel, faisable, mais choix produit (quelle variante par défaut ?) à trancher. | Nouvelle vue à partir des mêmes données `PotagerVue`. |
| **Plan spatial** (variante B) | ⚪ | Positions/dimensions spatiales des zones. **Aucun champ de layout** (x/y/largeur/hauteur) sur `Parcelle`. | Étendre le modèle (domaine + drift) avec un layout de zone, puis la vue. Lourd — à cadrer. |
| **Détail d'une zone** | ⚪ | Écran détail (dimensions, eau, expo, cultures détaillées). Données présentes sur `Parcelle`, mais pas de route ni d'écran. | Créer `EcranZoneDetail` + route ; brancher le `onTap` de `_LigneZone`. |
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
| **Vue « Réseau »** (constellation d'associations) | ⚪ | Un graphe interactif (nœuds = plantes, arêtes = associations). Les données existent (associations), mais la vue (layout, sélection, surbrillance) est lourde. | Nouvelle vue à partir du même `catalogueProvider` + un calcul de layout (cf. maquette `ReseauView`). |
| **Calendrier semis/récolte de la fiche** | ⚪ | Les périodes (`FichePlante.periodes`) sont indexées par **hémisphère × climat** ; une consultation du catalogue n'a pas ce contexte. | Soit dériver de la localisation du potager actif, soit laisser choisir hémisphère/climat ; brancher dans `fiche_plante_detail.dart` (`_Faits` / nouvelle section). |
| **Difficulté de culture** | ⚪ | Aucun champ « difficulté » sur `FichePlante` (la maquette a 1–3 points). | Ajouter le champ (YAML + entité) si on garde cette info, ou la dériver. |
| **Liste des variétés** | 🔵 clé i18n prête (`catalogueNbVarietes`) | Aucun champ « variétés » sur `FichePlante`. | Ajouter au modèle (YAML + entité) puis l'afficher dans la fiche. |
| **Description textuelle** | ⚪ | Pas de champ description sur `FichePlante`. | Ajouter au YAML/entité si souhaité. |
| **Gabarit / hauteur** | ⚪ | Pas de champ hauteur. | Idem (modèle). |
| **Favoris** (cœur en en-tête) | ⚪ | Pas de notion de favori. | Préférences/persistance à concevoir. |
| **« Ajouter au potager »** (CTA fiche) | ⚪ | Création de plantation depuis une fiche. | Brancher quand le form de création de plantation existe. |
| **Icône / couleur par catégorie** | 🔵 icône générique + couleur thème | La maquette a une icône + couleur par catégorie. | Mapper catégorie → icône Phosphor (cf. §1) + couleur déco. |

---

## 5. Écran Calendrier (`lib/presentation/screens/ecran_calendrier.dart`)

Réalisé : **vue Agenda** (résumé + sélecteur semaine/mois + groupes par jour de
tâches **cochables**). Données réelles : tâches sur fenêtre
(`obtenirEntreDates`), cocher = `Tache.marquerFaite` persisté.

| Élément | État | Ce qui manque | Où revenir |
|---|---|---|---|
| **Décocher une tâche** (réouvrir) | ⚪ | Le domaine n'a **pas** de transition « rouvrir » : `Tache` n'expose que `marquerFaite`, `reporter` (qui replanifie) et `annuler`. Pas de retour propre `terminee → aFaire`. | Ajouter une méthode domaine `rouvrir()` (+ test), puis activer le toggle inverse dans `_CarteTache`. |
| **Vue « Mois »** (grille mensuelle) | ⚪ | Grille calendaire + sélection de jour + pastilles de tâches. Faisable sur les mêmes données, mais c'est une autre vue. | Nouvelle vue à partir du `calendrierProvider` (élargir la fenêtre au mois et grouper par jour — déjà disponible). |
| **Vue « Saison »** (semis→récolte) | ⚪ | Bandes annuelles semis/plantation/récolte par culture : dépend des **périodes** des fiches (indexées hémisphère×climat, cf. §4) **et** des plantations en cours. | À concevoir avec le contexte localisation + les périodes du catalogue. |
| **Zone / culture / variété sur la carte** | 🔵 type + titre réels | La maquette affiche la zone (pastille colorée) + culture + variété ; ici on montre `titre` (réel) + type. La tâche porte `cible`/`cibleId` mais pas la culture/variété. | Résoudre la zone via le parcelle repo (`cible == parcelle`) ; culture/variété = nécessite un lien tâche↔plantation (cf. §3). |
| **Filtre / Ajout de tâche** (en-tête) | ⚪ | Bouton filtre + création de tâche. | Brancher quand le form de création de tâche existe ; filtre = état local de l'écran. |
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

## 7. Comment utiliser ce registre

- En reprenant un sujet, **chercher son entrée ici** : la colonne « Où revenir »
  pointe le fichier/fonction exact à modifier.
- Quand une entrée passe 🔵/⚪ → ✅, **mettre à jour la ligne** (ou la retirer si
  totalement résolue) dans le même commit.
- Les nouveaux placeholders introduits par les prochains écrans (Catalogue,
  Calendrier, Plus) **s'ajoutent ici** au fur et à mesure.
