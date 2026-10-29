# Reste à faire — Pot'à Gérer

Source unique du reste à faire. Remplace `docs/13-roadmap-et-versioning.md` et
`docs/15-elements-differes.md` (historique : `git log -- docs/13* docs/15*`).
Une entrée résolue est retirée dans le commit qui la résout.

Ordre d'exécution : thème (§2), puis lots de l'audit (§1), puis §3.
§4 avance en parallèle. §5 juste avant la sortie.

## 1. Corrections issues de l'audit

Audit pré-V1 (2026-11) : phases 1–3 et rapport livrés ; lots ci-dessous à faire après le thème (§2). Rapport : [docs/audit-2026-11.md](docs/audit-2026-11.md). Les lots touchant l'UI se font sur le nouveau thème.

- **L1 Fusion de sauvegarde** (D1–D3, P7, P8, S7; 3 `skip`) : [§5](docs/audit-2026-11.md#5-lots-proposés).
- **L2 Import et export robustes** (S4–S6, S10, S19, S20, S22, S23) : [§5](docs/audit-2026-11.md#5-lots-proposés).
- **L3 Échecs d'enregistrement et restauration** (D4, D5, P9, P10, Q4; 4 `skip`) : [§5](docs/audit-2026-11.md#5-lots-proposés).
- **L4 Vie privée et opt-outs (Auto Backup, notifications, météo, aide)** (S1, S13, S14, P11, P12, P24, P25, E10; 2 `skip`) : [§5](docs/audit-2026-11.md#5-lots-proposés).
- **L5 Notifications annoncées** (S2, S3, P3, P4, E15, Q7) : [§5](docs/audit-2026-11.md#5-lots-proposés).
- **L6 Recommandations visibles** (P2, E5, E6) : [§5](docs/audit-2026-11.md#5-lots-proposés).
- **L7 Frise du cycle et arrosage** (P5, P13, P23) : [§5](docs/audit-2026-11.md#5-lots-proposés).
- **L8 Sécurité plateformes et CI** (S8, S9, S11, S12, S15, S16, S21, S24) : [§5](docs/audit-2026-11.md#5-lots-proposés).
- **L9 Fiche : contenus non lus** (E1, E4, E7, E21, E24) : [§5](docs/audit-2026-11.md#5-lots-proposés).
- **L10 Niveaux d'expérience** (E2, E3, E9, E11, P14; 1 `skip`) : [§5](docs/audit-2026-11.md#5-lots-proposés).
- **L11 Conseils et alertes** (E14, E16–E19, E22; 1 `skip`) : [§5](docs/audit-2026-11.md#5-lots-proposés).
- **L12 Astuces permaculture** (E20) : [§5](docs/audit-2026-11.md#5-lots-proposés).
- **L13 Météo hors ligne** (Q1–Q3, S17, S18) : [§5](docs/audit-2026-11.md#5-lots-proposés).
- **L14 Cohérence et finitions** (Q5, Q6, P15–P20, P22) : [§5](docs/audit-2026-11.md#5-lots-proposés).

## 2. Dette technique hors audit

- **Thème** : prochain chantier, avant les lots de l'audit (§1). Le thème actuel est un placeholder ; thème général à refaire entièrement, clair et sombre (valeurs `CouleursApp.*Sombre` jamais validées). Maquetter dans Artifact puis revoir docs/08.

## 3. Finitions V1

| Élément | Manque | Où |
|---|---|---|
| Menu « Plus » | Racine Paramètres directe ; menu à ajouter si Post-récolte/Communauté arrivent | `ecran_plus.dart` |
| Swipe : action par sens au choix | En attente : choix dans Paramètres de l'action de chaque sens, quand une liste en offre plus de deux | `ElementBalayable`, `panneau_general.dart` |
| Appairage d'appareils | Fonction réseau local à concevoir | — |
| Export CSV | Optionnel (JSON ré-importable déjà livré) | — |
| Journal d'accès aux données | Différé (valeur faible pour une app 100 % locale) | — |

## 4. Contenu (parallèle au code)

- **Catalogue** : 445 fiches sur ~1 288 visées ([FICHES A CREER.md](FICHES%20A%20CREER.md)). Priorité : mères fruitières manquantes (~21), puis petits fruits. Arbitrages ouverts : vigne 'Isabelle' (mère distincte), potiron/potimarron, cornichon, pop-corn, fraisier des bois.
- **Gabarit** : renseigner `cycle.etalement_adulte_cm` (largeur adulte, sourcée) dans les fiches.
- **Associations** : typer et renseigner le contenu des paires (`type` + `raison_i18n`).
- **Référentiels** : `code_eppo` et descriptions des bioagresseurs restants ; prose des familles non utilisées ; traductions `en`. Contrôle : `dart run tool/verifier_referentiels.dart --strict`.
- **Arrosage détaillé** : chiffres de fréquence/volume des 6 espèces seedées, à sourcer.
- **Constats de l'audit** (C1–C5, F1–F3, E8, E12, E13, E23 : [docs/audit-2026-11.md](docs/audit-2026-11.md) §3) : arrosage détaillé (9 fiches sur 495, sans fréquence ni volume) ; étalement adulte sur 0 fiche ; données de graines absentes du schéma ; raisons d'association pauvres ; 58 bioagresseurs sur 105 sans description, ravageurs rattachés à la famille et non à l'espèce ; sources des fiches (URL de pages d'accueil) ; erreurs F1 (souci et nématodes), F2 (framboisier), F3 (zone_min).
- **Glossaire** : illustrations au fil de l'eau ([docs/17](docs/17-illustrations-glossaire.md)), DP/CC0 uniquement tant que l'attribution n'est pas câblée.

## 5. Pré-release

- Générer la clé de release et renseigner les secrets du dépôt ([docs/18](docs/18-publication-android.md)).
- Icône et splash (dépendances à valider ou ressources manuelles).
- Packaging iOS / macOS (compte Apple requis) ; Linux et Windows livrés en archives, sans signature Windows.
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
