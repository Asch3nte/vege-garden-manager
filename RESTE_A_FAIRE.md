# Reste à faire — Pot'à Gérer

> Résumé étendu de ce qu'il reste à faire, **hors design** (dark mode, Phosphor
> Icons) et **hors revue de contenu** (relecture éditoriale du glossaire,
> éditorial des familles/bioagresseurs). Généré le 2026-07-07 à partir de
> [`docs/15-elements-differes.md`](docs/15-elements-differes.md) et
> [`docs/13-roadmap-et-versioning.md`](docs/13-roadmap-et-versioning.md).
> Mis à jour le 2026-07-07 après livraison du multi-potager (sélecteur +
> création + F2 réglages).

## 1. Fonctionnalités « build-then-gate » (ADR-0009 §9)

Réservées par palier mais sans UI ni donnée :

- ~~**Multi-potager** (inter+)~~ ✅ **fait** : sélecteur de potager actif
  (menu ⋮ Potager) + action « Ajouter un potager » + réglages (F2)
- ~~**Équipements/outils** (inter+) : toute l'UI manque~~ ✅ **Livré**
  (liste + formulaire + section détail de zone, gaté `acces.equipements`,
  entrée menu ⋮ Potager) — voir docs/15 §9
- **Fiches plantes perso** (expert) : toute l'UI de création/édition (table
  existe)
- **Rotation avancée** (expert) : UI de rotation (précédents culturaux, délai
  retour famille) — donnée sur la fiche mais aucun écran
- **Besoins en eau détaillés** (expert) : il faut d'abord enrichir
  `BesoinsCulture` (fréquence/quantité, pas juste le terme grossier)
- **Lot 4 ADR-0009** : mini-tutos par palier + teaser de montée (modèle de
  contenu partagé avec le glossaire — mais l'implémentation du mécanisme, pas
  le texte, reste du dev)

## 2. Éléments différés docs/15 — non-design

- **Navigation** : sous-routes go_router restantes (détail tâche, fiche
  plante en route dédiée)
- **Accueil** : écran notifications + menu ⋮ (actions d'en-tête), lien « voir
  les tâches » → Calendrier
- **Potager** : FAB de création (potager/zone/plantation), métadonnées de
  zone (besoin eau/dimensions littérales) si on veut les champs réels
- **Catalogue** : favoris (notion inexistante), gabarit/hauteur de plante
  (champ manquant), vue Réseau — rendu canvas (perf, différé)
- **Calendrier** : rien de fonctionnel majeur restant (tout ✅)
- **Paramètres** :
  - Catégorie « Transparence des données » (stats tailles DB + journal
    d'accès — n'existe pas)
  - Toggle « récupération météo auto » (champ manquant)
  - Toggle « Ne pas déranger » (champs domaine présents, UI absente)
  - **Version dynamique** (`package_info_plus`), **liens externes**
    (`url_launcher`), **i18n `en`** — 🚧 **en cours ailleurs**, branche
    `feat/parametres-version-liens-i18n`
  - Appairage d'appareils (réseau local, à concevoir)

## 3. Distribution / packaging (docs/15 §7)

- Signing release réel (keystore + `key.properties`, actuellement clé debug)
- CI/CD GitHub Actions (aucun pipeline)
- iOS / desktop packaging (Linux AppImage/Flatpak, .exe, .dmg) — alpha =
  Android seul pour l'instant

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

- ~~Multi-potager (sélecteur actif + création) + F2~~ ✅ fait (2026-07-07)
- 🚧 Version dynamique + liens externes + i18n `en` — en cours ailleurs
  (`feat/parametres-version-liens-i18n`)

Prochains candidats, par ordre de terrain nouveau croissant :

1. **Distribution** : keystore release + CI/CD GitHub Actions
2. ~~**Équipements/outils** (inter+)~~ ✅ **livré** (liste + formulaire +
   section zone, gaté `acces.equipements`)
3. Le reste (fiches perso, rotation avancée, transparence des données,
   territoire/invasives, besoins en eau détaillés) sont des chantiers plus
   lourds nécessitant de nouvelles UI/modèles complets.
