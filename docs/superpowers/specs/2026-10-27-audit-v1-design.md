# Audit pré-V1 — design

Date : 2026-10-27. Statut : approuvé le 2026-10-28.

## 1. Intention

Avant de publier la V1, établir avec des preuves que l'app tient ses trois
engagements envers l'utilisateur, et laisser dans le dépôt les tests qui les
garantissent ensuite.

Trois craintes du dev, par ordre de priorité :

1. **Perte de données utilisateur** — inacceptable, quelle qu'en soit la cause.
2. **App pas assez éducative** — selon son niveau, l'utilisateur reçoit des
   tips pertinents, et toute question qui émerge en utilisant l'app ou en
   lisant une fiche trouve très facilement sa réponse.
3. **Promesses non tenues** — tout ce que l'app et sa doc affirment est vrai
   dans le code.

La sécurité classique compte dans la mesure où elle menace (1) ou (3).

## 2. Objectifs, non-objectifs, anti-objectifs

**Objectifs**
- Rapport `docs/audit-2026-11.md`, même format que `docs/audit-2026-10.md`
  (gravité C/H/M/B, effort S/M/L, couche, fichier, vérifié oui/non), plus trois
  sections dédiées aux trois craintes.
- Lots de correction ajoutés à `RESTE_A_FAIRE.md` §1.
- Tests E2E et de non-perte **versionnés et exécutés en CI**.
- Alignement doc ↔ code des écarts constatés (ex. `docs/02` §8 post-récolte et
  §9 CSV, repoussés mais encore listés V1).

**Non-objectifs**
- Corriger les constats pendant l'audit (hors tests ajoutés). Les corrections
  passent par les lots, une branche chacun.
- Le design / thème (chantier séparé, `RESTE_A_FAIRE.md` §2).
- Produire le contenu manquant du catalogue (§4) ; l'audit signale seulement
  les trous qui nuisent à l'éducatif.

**Anti-objectifs** (l'audit échoue même s'il « tourne ») :
- Un rapport sans preuve : chaque constat cite un fichier/ligne, un test qui
  échoue ou une reproduction.
- Des tests E2E fragiles qui rendent la CI rouge par intermittence.
- Des constats « éducatifs » relevant du goût, sans question utilisateur
  concrète restée sans réponse.

## 3. Contraintes

- Règles de `CLAUDE.md` du projet : branche courte par chantier, Conventional
  Commits, aucune dépendance sans validation, tests avec le code, commentaires
  en anglais sans référence externe.
- Flutter **3.47.7** (version CI). Le poste local est en 3.44.1 et
  `flutter pub get` échoue : mise à jour locale requise avant tout.
- CI actuelle : analyze + tests (`TZ=Europe/Brussels`), osv-scanner, gitleaks.

## 4. Le comment — décidé

### 4.1 Axe données (priorité 1)

Tests versionnés sous `integration_test/` (paquet SDK `integration_test`,
dépendance de dev à valider) et `test/` :

- **Aller-retour complet** : construire un potager riche (plusieurs potagers,
  zones, plantations à tous statuts, tâches, rappels récurrents, récoltes,
  observations, équipements, fiches personnelles, préférences), exporter,
  réinitialiser, réimporter en mode *remplacer*, comparer champ par champ
  (dont dates de création).
- **Fusion** : fusionner une sauvegarde dans sa base d'origine et dans une base
  divergente ; aucune perte, aucun doublon.
- **Imports hostiles** : fichier tronqué, non UTF-8, JSON invalide, version
  future, colonnes/tables inconnues, FK incohérentes → refus typé, message,
  base inchangée.
- **Migrations** : ouvrir une base peuplée à chaque `schemaVersion` passée
  (7 → 12 couverts unitairement ; compléter jusqu'à la v1 si possible) et
  vérifier les données après montée.
- **Écritures en échec** : erreur repository simulée sur chaque formulaire →
  message visible, UI fidèle à l'état persisté.
- **Dates** : génération de tâches/rappels autour des bascules d'heure
  (fuseaux avec DST, Nord et Sud).
- **Réinitialisation** : double confirmation, base vide ensuite, pile de
  navigation propre.

### 4.2 Axe éducatif (priorité 2)

- **Parcours par personnages** : trois agents (débutant, intermédiaire,
  expert) suivent les parcours de `docs/10` dans le code et l'UI (widgets +
  ARB + fiches YAML). Chacun note les questions qui lui viennent ; pour
  chacune : réponse trouvable ? en combien de gestes ? juste ? adaptée au
  niveau ? Sortie : liste de trous classés.
- **Contrôles automatiques versionnés** :
  - toute recommandation, alerte et conseil d'arrosage porte un « pourquoi »
    non vide (quoi / pourquoi / comment, `docs/02` §2) ;
  - tout terme du glossaire employé dans les textes UI et fiches est lié ;
  - les sections pédagogiques vides des fiches sont comptées.
- **Paliers (ADR-0009)** : vérifier la matrice feature → palier et la
  verbosité des conseils par palier. Constat préliminaire à confirmer : la
  verbosité semble décidée mais non implémentée.
- **Tips permaculture contextuels** (`docs/02` §4) : constat préliminaire à
  confirmer — pas de mécanisme dédié, seulement des astuces ponctuelles.

### 4.3 Axe promesses (priorité 3)

- **Registre des promesses** : chaque affirmation de `docs/01`, `docs/02`,
  `docs/11`, `README.md`, des politiques de confidentialité (fr/en) et des
  textes UI (onboarding : « 100 % local, sans compte ») → tenue / partielle /
  non tenue, avec preuve.
- **Réseau** : test versionné qui intercepte tout client HTTP et vérifie
  qu'aucun hôte hors Open-Meteo et Nominatim n'est appelé, et qu'aucun appel
  ne part quand l'opt-out correspondant est actif (météo, géoloc).
- **Opt-outs** (`docs/11`) : chacun testé effectif.
- **Sécurité** : `/claude-security` sur tout le dépôt ; `atelier:relecteur-hostile`
  sur sauvegarde/import, clients HTTP, fichiers temporaires, notifications,
  permissions Android/iOS/desktop, release ; `/code-review` niveau `high` pour
  les bugs restants.

### 4.4 CI

- Nouveau job E2E sur Linux sans écran (`xvfb-run flutter test integration_test -d linux`).
- Les contrôles éducatifs et réseau tournent dans le job de tests existant.

### 4.5 Ordre

0. Flutter local 3.47.7, ligne de base (analyze, tests, couverture).
1. Axe données → 2. Axe promesses → 3. Axe éducatif → 4. Rapport + lots +
   alignement doc.

Une branche par livraison : `chore/flutter-3.47.7` (si besoin),
`chore/e2e-donnees`, `chore/tests-promesses-reseau`, `chore/controles-educatifs`,
`docs/audit-2026-11`.

### 4.6 Précisions (relecture builder)

- **Migrations** : v0.9.0 et v0.9.1, seules versions publiées, sont en
  `schemaVersion` 12. Aucune base < 12 n'existe chez un utilisateur : les
  tests partent de la v12 (fixture figée) ; les tests v7–v11 existants
  restent. *Choix de l'agent.*
- **Imports** : comportement actuel pris comme attendu — colonne inconnue →
  refus typé ; table inconnue → ignorée ; ligne malformée → refus ; la base
  reste inchangée (transaction). *Constaté dans le code.*
- **Opt-outs réseau** (`docs/11`) : un appel déclenché par l'utilisateur
  (ouverture de l'écran météo, actualisation manuelle, recherche de ville) est
  permis ; tout appel automatique est interdit quand l'opt-out est actif.
  Le constat n° 11 d'octobre est tranché dans ce sens. *Lecture de `docs/11`.*
- **Contrôles éducatifs** : seuil à cliquet — le test mesure, enregistre la
  valeur de référence et échoue seulement en cas de régression. « Terme » =
  entrée du registre du glossaire (forme et variantes déclarées) ; textes
  contrôlés : ARB et YAML des fiches. *Choix de l'agent.*
- **Promesse non tenue** : la doc n'est jamais revue à la baisse pendant
  l'audit ; un lot est ouvert, la décision reste au dev. Seuls les écarts déjà
  décidés (`docs/02` §8, §9) sont alignés. *Choix de l'agent.*

### 4.7 Décisions du dev (2026-10-27)

- **Test qui révèle un bug** : mergé avec `skip`, raison décrivant le défaut
  (sans référence externe) ; le lot de correction retire le `skip`. Le rapport
  cite le test comme preuve.
- **Fusion, même UUID modifié des deux côtés** : la version au `updatedAt`
  (`dateModification` pour `parametres`) le plus récent gagne. Le comportement
  actuel (la sauvegarde gagne toujours) est donc un constat H de l'axe
  données. Tables sans date (`preferences`, `meteo_cache`) : au builder.
- **Flutter 3.47.7 en local** : validé.

## 5. Laissé au builder

- Structure interne des tests, helpers, fixtures (bases par version).
- Mécanisme d'interception HTTP (le client `http` est déjà injectable).
- Découpage des agents et prompts des personnages.
- Format exact des listes de trous éducatifs, tant qu'elles se rangent dans le
  rapport.

## 6. Choix validés par le dev (2026-10-27)

- Pas de `/code-review ultra` (payant) ni de MobSF (outil externe).
- Android E2E sur émulateur : en local seulement, pas en CI (coût, fragilité).
- `integration_test` ajouté comme dépendance de dev ; job CI E2E Linux avec
  paquets apt GTK et `xvfb`.
