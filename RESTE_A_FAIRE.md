# Reste à faire — Pot'à Gérer

Source unique du reste à faire. Remplace `docs/13-roadmap-et-versioning.md` et
`docs/15-elements-differes.md` (historique : `git log -- docs/13* docs/15*`).
Une entrée résolue est retirée dans le commit qui la résout.

Ordre d'exécution : §1 (lots numérotés, une branche par lot), puis §2 et §3.
§4 avance en parallèle. §5 juste avant la sortie.

## 1. Corrections issues de l'audit

Détail, fichiers et gravité : [docs/audit-2026-10.md](docs/audit-2026-10.md) (`#n`).

| Lot | Branche | Contenu |
|---|---|---|
| 5 | `fix/navigation-i18n` | Pile de navigation après reset/suppression (#40, #44), onboarding ignorant les retours arrière (#42), opt-out météo strict sur l'écran détail (#11, arbitré), texte FR en dur : titres de tâches persistés et notifications (#24), `generateur_resume_meteo.dart`, `_moisFr` ×4 → `DateFormat`, `'Mon carnet'`, `'$cle : '` (#26), `nomLocalise('fr')` ×32 (#41), clés de famille non normalisées (#15). |
| 6 | `refactor/composition-root` | Branchement des implémentations déplacé dans `lib/app/` via `ProviderScope(overrides:)` (schéma de `database_providers.dart` généralisé, arbitré) ; test garde-fou « `application/` n'importe pas `infrastructure/` ». |
| 7 | `chore/qualite` | Lints de fond (`strict-casts`, `strict-raw-types`, `avoid_dynamic_calls`, `discarded_futures`, `only_throw_errors`, `avoid_catching_errors`, `unawaited_futures`) ; listes des repositories via `List.unmodifiable` (#29) ; `Quantite` égalité à tolérance (#30) ; chemins Windows (#34) ; duplications (#35) ; code mort (#27) ; tap raté du test (#28). |
| 8 | `chore/purge-commentaires` | Retrait des références ADR/docs/lot/§ (701 lignes), commentaires du domaine en anglais, paraphrases supprimées. |

## 2. Dette technique hors audit

- **Phosphor Icons** : `phosphor_flutter` 2.1.0 ne compile pas (étend `IconData`, devenu `final`). Material en substitut. Options : wrapper local (`.ttf` MIT + `IconData` const) ou version amont compatible. Points de remplacement : `lib/app/router.dart` (`_destinations`), `libelles_enums.dart` (`iconeTypeTache`), icône par catégorie du catalogue.
- **Dark mode** : valeurs de `CouleursApp.*Sombre` non revalidées (maquettes light uniquement) ; maquetter puis revoir docs/08 §3.
- **Surface libre non contrôlée à la création** : `CreerPlantation` n'applique pas `Parcelle.ajouterPlantation` → une zone peut être sur-plantée.
- **Lignes en base invalides** : les invariants du domaine s'appliquent désormais en release ; une ligne invalide héritée d'une ancienne version fait échouer toute la liste à sa lecture. Tolérance ligne par ligne (ignorer + journaliser) à décider.
- **Échecs d'enregistrement des préférences non signalés** : les bascules des panneaux Paramètres appellent `PreferencesNotifier` sans gestion d'erreur (seul le changement de niveau est couvert).
- **`ResolveurFamille`** non transmis à `afficherVueAssociations` (`ecran_catalogue.dart`) → suggestions répulsion/piège inactives.

## 3. Finitions V1

| Élément | Manque | Où |
|---|---|---|
| Sections « Bons compagnons / À éviter » dans la fiche | Sections listées avec raison (la vue Associations les affiche déjà) | `fiche_plante_detail.dart` |
| Difficulté de culture | Champ présent sur `FichePlante`, non affiché au catalogue | `fiche_plante_detail.dart`, cartes catalogue |
| Gabarit / hauteur de plante | Champ absent | YAML + `FichePlante` |
| Favoris | Notion absente | Préférences + persistance |
| Métadonnées de zone | Dimensions L×l, besoin en eau de zone | `Parcelle` (actuellement `surface` seule) |
| Couleur de zone stable | Couleur dérivée de l'index, non persistée | `Parcelle` + drift |
| Swipe sur les listes | Préférence `SensSwipe` présente, geste non généralisé | listes tâches/cultures |
| Visibilité du bloc par potager (Confidentialité) | Surface contrastée ou tranche repliable | `panneau_confidentialite.dart` |
| Menu « Plus » | Racine Paramètres directe ; menu à ajouter si Post-récolte/Communauté arrivent | `ecran_plus.dart` |
| Dérivation climat/rusticité fine | Altitude via Open-Meteo | `DerivateurLocalisation` |
| Vue Réseau | Rendu canvas des nœuds (performance) | `vue_reseau_catalogue.dart` |
| Liens « documentation » et « signaler un bug » | Lignes absentes de l'UI | `panneau_a_propos.dart` |
| Appairage d'appareils | Fonction réseau local à concevoir | — |
| Export CSV | Optionnel (JSON ré-importable déjà livré) | — |
| Journal d'accès aux données | Différé (valeur faible pour une app 100 % locale) | — |

## 4. Contenu (parallèle au code)

- **Catalogue** : 445 fiches sur ~1 288 visées ([FICHES A CREER.md](FICHES%20A%20CREER.md)). Priorité : mères fruitières manquantes (~21), puis petits fruits. Arbitrages ouverts : vigne 'Isabelle' (mère distincte), potiron/potimarron, cornichon, pop-corn, fraisier des bois.
- **Associations** : typer et renseigner le contenu des paires (`type` + `raison_i18n`).
- **Référentiels** : `code_eppo` et descriptions des bioagresseurs restants ; prose des familles non utilisées ; traductions `en`. Contrôle : `dart run tool/verifier_referentiels.dart --strict`.
- **Arrosage détaillé** : chiffres de fréquence/volume des 6 espèces seedées, à sourcer.
- **Glossaire** : illustrations au fil de l'eau ([docs/17](docs/17-illustrations-glossaire.md)), DP/CC0 uniquement tant que l'attribution n'est pas câblée.
- **Politique de confidentialité** : finaliser [docs/politique-confidentialite.md](docs/politique-confidentialite.md).

## 5. Pré-release

- Keystore release réel (`signingConfigs.release`, `key.properties` hors VCS) ; actuellement clé debug.
- Job CI de build et signature d'APK.
- Icône et splash (dépendances à valider ou ressources manuelles).
- Packaging iOS / Linux / Windows / macOS.
- Relecture éditoriale de tout le glossaire, puis sa traduction `en`.
- **Vérification développeur Android** (Google) : en vigueur depuis le 30/09/2026 dans quatre pays, globale en 2027. Décision à prendre : vérification complète, distribution restreinte (≤ 20 appareils) ou hors Play Protect. [Source](https://developer.android.com/developer-verification).
- README à jour.

## 6. V1.1

| Fonctionnalité | Note |
|---|---|
| Post-récolte (conservation, recettes) | ADR-0019 ; ADR de cadrage avant implémentation. Clés ARB `plusPostRecolte(Sub)` réservées. |
| Entité `Traitement` | Interventions naturelles, YAML dédié. |
| Photos (observations, récoltes) | — |
| Réconciliation `TypeEquipement` | — |
| Seuils météo configurables | Gel/canicule figés en V1. |
| Déduction du type de sol | API géologique ou heuristique (API à valider). |
| Arrosage : phase sensible → urgence | ADR-0018 (Proposé). Prérequis : corpus renseigné. |
| Sensibilité météo par plante | Voir §6.1. |
| Conformité réglementaire par territoire | Voir §6.2. Bloqué par l'absence de source officielle intégrable hors ligne. |

### 6.1 Alertes météo ciblées par plante

Aujourd'hui l'alerte vise toutes les plantations en place.

- Champs YAML sous `besoins:` : `temperature_min_tolerance`, `temperature_max_tolerance` (°C), `tolerance_secheresse`, `sensibilite_exces_eau` (`faible|moyenne|forte`). Variante qualitative : `sensibilite_gel`, `sensibilite_chaleur`.
- Gain rapide : `temperature_min_germination` et `temperature_optimale`, déjà au schéma, non mappés.
- Raffinements : sensibilité selon le stade ; protection par équipement (voile, tunnel).
- Chaîne touchée : schéma, parser, validateur, mapper, `BesoinsCulture`, `tomate.yaml`, docs/07, évaluateur d'alertes.

### 6.2 Plantes invasives ou interdites par territoire

- Filtrer `RecommanderPlantes` ; alerte éducative unique, non bloquante, à la saisie.
- Sources candidates : Règlement (UE) n°1143/2014, listes nationales et régionales. Critères : officielle, versionnée, citable, embarquable.
- À créer : notion de territoire dérivée de la position, dataset embarqué par `nom_scientifique` avec statut et message i18n, suivi « alerte vue », mention de la source et de sa date.

## 7. V2 (opt-in, désactivé par défaut)

- Communauté P2P locale.
- Calendrier lunaire.
- Vue graphique des relations (type Obsidian).
- Plan spatial du potager (layout x/y des zones ; sélection de cible de tâche sur le plan, multi-cible).
- Sync bidirectionnelle avec une base communautaire.

## 8. Hors périmètre

- Détection automatique de maladies ou ravageurs (IA, photo).
