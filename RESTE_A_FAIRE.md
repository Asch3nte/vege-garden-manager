# Reste à faire — Pot'à Gérer

Source unique du reste à faire. Remplace `docs/13-roadmap-et-versioning.md` et
`docs/15-elements-differes.md` (historique : `git log -- docs/13* docs/15*`).
Une entrée résolue est retirée dans le commit qui la résout.

Ordre d'exécution : §2 et §3 (§1, l'audit, est soldé).
§4 avance en parallèle. §5 juste avant la sortie.

## 1. Corrections issues de l'audit

Tous les lots sont livrés. Détail : [docs/audit-2026-10.md](docs/audit-2026-10.md).

## 2. Dette technique hors audit

- **Thème** : le thème actuel est un placeholder ; thème général à refaire entièrement, clair et sombre (valeurs `CouleursApp.*Sombre` jamais validées). Maquetter puis revoir docs/08.

## 3. Finitions V1

| Élément | Manque | Où |
|---|---|---|
| Menu « Plus » | Racine Paramètres directe ; menu à ajouter si Post-récolte/Communauté arrivent | `ecran_plus.dart` |
| Swipe : action par sens au choix | Choix dans Paramètres de l'action de chaque sens, quand une liste en offre plus de deux | `ElementBalayable`, `panneau_general.dart` |
| Swipe : suppression / arrachage sans confirmation | Option « Ne plus afficher » la confirmation, livrée avec un snackbar « Annuler » (5 s) et la restauration par type | `ElementBalayable`, notifiers |
| Appairage d'appareils | Fonction réseau local à concevoir | — |
| Export CSV | Optionnel (JSON ré-importable déjà livré) | — |
| Journal d'accès aux données | Différé (valeur faible pour une app 100 % locale) | — |

## 4. Contenu (parallèle au code)

- **Catalogue** : 445 fiches sur ~1 288 visées ([FICHES A CREER.md](FICHES%20A%20CREER.md)). Priorité : mères fruitières manquantes (~21), puis petits fruits. Arbitrages ouverts : vigne 'Isabelle' (mère distincte), potiron/potimarron, cornichon, pop-corn, fraisier des bois.
- **Gabarit** : renseigner `cycle.etalement_adulte_cm` (largeur adulte, sourcée) dans les fiches.
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
