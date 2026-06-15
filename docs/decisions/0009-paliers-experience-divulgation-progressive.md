# ADR-0009 — Paliers d'expérience et divulgation progressive

- **Statut** : Accepté
- **Date** : 2026-06-15
- **Contexte** : l'enum `NiveauExperience` (`debutant` / `intermediaire` /
  `expert`) existe, est choisi dans les réglages, et **alimente déjà
  partiellement** deux mécanismes : la divulgation du tableau de bord
  (`accueil_notifier.dart`) et un filtre du moteur de recommandation
  (`evaluateur_recommandations.dart`). Mais il **n'existe aucun modèle formel**
  de ce que chaque palier débloque, ni de mécanisme pour aider l'utilisateur à
  progresser.

  Trois besoins, confirmés en revue dev (2026-06-15) après le retour de test de
  l'onboarding :

  1. **Critères de distinction clairs** entre les trois paliers.
  2. Leur **traduction concrète** : quelles features/contrôles/données sont
     affichés ou masqués à chaque palier, et comment varie la verbosité des
     conseils.
  3. Un mécanisme de **montée de palier** (l'app doit donner envie et les moyens
     de passer au niveau suivant), **réversible et non destructif**.

  Déclencheur : l'onboarding doit **demander explicitement** le niveau (pas de
  défaut silencieux), et adapter immédiatement les écrans suivants.

---

## Décision 1 — Trois paliers, profondeur croissante

Chaque palier est **une couche de profondeur agronomique + de densité d'UI**. La
**boucle de base** — potager → zone → plante → tâches, catalogue **Fiches**,
agenda — reste **toujours disponible à tous les paliers**. On ne masque que des
**contrôles/données avancés**, et on module la **verbosité des conseils**.

| Palier | Posture | Conseils |
|---|---|---|
| **Débutant** | stricte simplicité, on guide pas à pas | détaillés |
| **Intermédiaire** | plus de contrôle, l'utilisateur a déjà jardiné | utiles, moins verbeux |
| **Expert** | agronomie fine, rien de masqué | concis |

---

## Décision 2 — Matrice feature → palier

> ✅ disponible · — masqué (donnée conservée, cf. Décision 3).

| Élément | Débutant | Intermédiaire | Expert |
|---|:--:|:--:|:--:|
| **Cœur** (potager/zone/plante/tâches, Fiches, agenda) | ✅ | ✅ | ✅ |
| Verbosité des conseils | détaillés | utiles | concis |
| Équipements / outils (`Equipement`) | — | ✅ | ✅ |
| Techniques de sol (lasagne, butte, paillage, no-dig — `TechniqueSol`) | — | ✅ | ✅ |
| Vue **Réseau** du Catalogue (associations) | — | ✅ | ✅ |
| Observations (journal) | — | ✅ | ✅ |
| Vue **Saison** (calendrier semis→récolte) | — | ✅ | ✅ |
| **Multi-potager** (gérer plusieurs jardins) | — | ✅ | ✅ |
| Besoins en eau | grossier (**beaucoup / moyen / peu**) | grossier | **détaillé** (fréquence/quantités, `BesoinsCulture`) |
| Sol : **texture + pH** par zone (`TextureSol` / `PhSol`) | — | — | ✅ |
| **Stats** du tableau de bord (récoltes saison…) | — | — | ✅ |
| **Rotation avancée** (précédents culturaux, délai de retour) | — | — | ✅ |
| **Fiches plantes perso** (contribution — table `fiches_plantes_personnelles`) | — | — | ✅ |
| **Calendrier lunaire** (option) | — | option | option |
| **Notifications** (granularité du réglage — cf. Décision 5) | maître seul | + par catégorie | + par catégorie |

**Notes d'état du modèle** :
- `TextureSol` / `PhSol` sont **déjà des champs nullable de `Parcelle`**
  (à exposer au formulaire en Expert).
- `TechniqueSol` **existe comme enum** mais n'est **pas encore rattaché** à
  `Parcelle` → câblage à faire (champ + colonne drift + formulaire).
- Stats tableau de bord et filtre de reco par niveau **existent déjà**
  (à étendre).

---

## Décision 3 — Garde-fous (non négociables)

1. **Cœur jamais bloqué** — un débutant peut jardiner de bout en bout (créer
   jardin, zones, plantations, suivre ses tâches). On ne gate jamais l'essentiel
   ni la **sécurité** (alertes météo critiques restent actives, cf. Décision 5).
2. **Réversible et non destructif** — changer de palier **ne supprime jamais**
   de données. Une zone dont le pH a été saisi en Expert **conserve** son pH si
   l'utilisateur redescend en Débutant ; le contrôle est simplement masqué.
   Conséquence d'implémentation : le gating agit sur l'**affichage des
   contrôles/données**, pas sur le stockage.
3. **Ne pas sur-masquer** — risque « où est passé X ? ». Mitigé par le teaser
   (Décision 4) et par le fait que le palier est **à un tap** dans les réglages.

---

## Décision 4 — Accompagnement des paliers : **mini-tuto** (palier courant) + **teaser** (palier suivant)

Deux canaux **complémentaires**, partageant le même **modèle de contenu** que
l'« Aide & lexique » (docs/15 §8 C4) : **feature → pourquoi → comment**.

### 4a. Mini-tuto **par palier** (features du palier courant)
À chaque palier correspond un **mini-tuto** qui **répertorie les features que ce
palier débloque**, et pour chacune **pourquoi elle existe** et **comment
l'utiliser**. Il est :
- **présenté au moment où l'on atteint le palier** (choix à l'onboarding, ou
  changement de niveau dans les réglages) — non bloquant, passable ;
- **toujours re-consultable** ensuite (depuis l'« Aide & lexique » et/ou le
  réglage de niveau), pour ne rien perdre ;
- **cumulatif** : le tuto d'un palier suppose acquis ceux des paliers inférieurs
  (le cœur n'est pas re-expliqué à chaque fois).

Le contenu vit comme **données éditoriales** (une entrée par feature : palier,
titre, *pourquoi*, *comment*), réutilisées par l'Aide & lexique et le teaser.

### 4b. Teaser de **montée de palier** (perk du palier suivant)
Chaque palier **propose** une perk du **palier suivant**, **au bon moment et au
bon endroit**, via des **cartes “aperçu de palier”** : un court texte + un CTA
d'un tap vers le réglage de niveau. Exemple pour un débutant, en bas du
Catalogue : *« 💡 Organisez vos associations visuellement — la Vue Réseau s'ouvre
en niveau Intermédiaire »* + bouton « Passer en Intermédiaire ».
- **Dismissable** et non intrusif (jamais une modale bloquante).
- Le CTA peut **enchaîner sur le mini-tuto (4a)** du palier atteint.

Ensemble, 4a + 4b répondent au besoin #3 (« donner envie **et** les moyens » de
progresser) : le teaser donne *envie*, le mini-tuto donne les *moyens*.

---

## Décision 5 — Notifications : gating de la **granularité**, jamais de la sécurité

- **Débutant** : la page Notifications n'affiche **que l'interrupteur maître**
  (« Notifications : on/off »). Les bascules par catégorie sont masquées.
- **Intermédiaire / Expert** : maître **+ les bascules par catégorie** (Semis,
  Arrosage, Récolte, Météo critique, Entretien).
- **Une catégorie masquée garde son défaut (activé)** → un débutant **reçoit
  quand même** la Météo critique et les rappels essentiels. On masque la
  *granularité du réglage*, pas les notifications.

> **⚠️ Sweet-spot (revue dev 2026-06-15).** Au lot Notifications, **calibrer
> prudemment** la fréquence/le volume : trop de notifications (travers classique
> du mobile) pousse l'utilisateur à **tout couper** ; trop peu dégrade le suivi.
> Viser le minimum utile, regrouper quand c'est possible, respecter « Ne pas
> déranger ». À traiter comme une décision produit à part entière le moment venu.

---

## Décision 6 — Onboarding : choix **explicite** du niveau

L'onboarding ajoute une **étape dédiée** au choix du palier (après la
confirmation climat/rusticité, **avant** la création du 1er potager), avec une
**description par palier** dérivée de la matrice (Décision 2). Pas de défaut
silencieux. Comme l'étape précède la création du potager, **les formulaires
suivants de l'onboarding respectent déjà le palier choisi**.

---

## Décision 7 — Socle technique : une **politique d'accès centralisée**

Pour éviter des `if (niveau == ...)` éparpillés et incohérents, le mapping
feature → palier requis vit dans **un seul endroit** (p. ex.
`AccesNiveau` / une politique pure, couche `domain` ou `application`), exposant
des prédicats lisibles (`peutVoirVueReseau(niveau)`, `peutEditerSol(niveau)`…).
L'UI consomme ces prédicats. Avantages : un seul point de vérité, testable,
cohérent avec le garde-fou de réversibilité.

---

## Découpage en lots livrables

Comme les ADR précédents : **chaque lot laisse l'app verte** (`flutter analyze` +
suite). Tests écrits **en parallèle**.

| Lot | Périmètre | Dépendance |
|---|---|---|
| **1 — Onboarding** | Affinements de l'onboarding issus du retour de test : auto-avance après position (#1), **étape niveau d'expérience** + descriptions (#2), ajout de **zones** dans l'étape potager (#3), atterrissage sur le panneau **Potager** + bulle d'aide (#4), **invalidation** des vues après reset/onboarding (#5). | — |
| **2 — Socle + gating rapide** | Politique `AccesNiveau` (Décision 7) + gating des features **déjà câblées** : Vue Réseau, Vue Saison, Observations, stats tableau de bord, calendrier lunaire, granularité notifications. | Lot 1 |
| **3 — Gating à câblage modèle** ✅ (recadré) | **Réalité** : seuls les **champs sol existants** étaient gatables (le reste n'a **pas d'UI/donnée** → relève de « construire puis gater »). **Fait** : `FormulaireZone` expose **techniques de sol** (intermédiaire+, `Parcelle.techniquesSol` déjà câblé) et **texture + pH** (expert, champs `Parcelle` déjà présents), gatés via `AccesNiveau` ; valeurs masquées **préservées** (réversibilité). Libellés sol ajoutés. **Reclassé en « build-then-gate » (lots futurs dédiés)** : multi-potager (manque un sélecteur de potager actif), équipements, fiches perso, rotation avancée (aucune UI), besoins en eau détaillés (manque la donnée fiche). La politique `AccesNiveau` les **réserve déjà** → ils se gateront à leur construction. | Lot 2 |
| **4 — Mini-tutos par palier + teaser** ✅ | **4a ✅** Mini-tuto **re-consultable** : panneau « Guide des niveaux » (`panneau_niveaux.dart`, route `/plus/niveaux`) — catalogue des features **construites** par palier (titre → **pourquoi** → **comment**), badge « Débloqué » selon le niveau, paliers supérieurs = teaser statique. Contenu éditorial (`_features` + clés `tuto*`). **4b ✅** Teaser **contextuel** `CarteTeaserPalier` (dismissable, CTA « En savoir plus » → Guide) sur **Catalogue** (Vue Réseau) et **Calendrier** (Vue Saison) pour les paliers inférieurs ; **nudge auto** au changement de niveau (snackbar « Découvrir » → Guide, panneau Général). | Lot 2 (+ docs/15 §8 C4) |

---

## Conséquences

### Positives
- Un modèle **formel et unique** de la divulgation progressive (fin des
  décisions ad hoc), aligné sur la philosophie « simple pour les débutants,
  profond pour les experts ».
- Réutilise l'existant (stats, filtre de reco) au lieu de le refaire.
- La réversibilité non destructive protège les données et l'utilisateur.

### Négatives / risques
- Surface transverse importante : le gating touche beaucoup d'écrans → **rollout
  incrémental** indispensable (d'où le découpage en lots).
- Risque de **sur-masquage** / confusion → mitigé par le teaser et la
  réversibilité à un tap.
- Le lot **Notifications** porte un vrai risque produit (sweet-spot) à traiter
  avec soin.

---

## Liens
- Registre des éléments différés : [`docs/15`](../15-elements-differes.md) (§2 tableau de bord, §8 C4 Aide & lexique).
- Onboarding : [ADR plan onboarding `docs/15` §7] et l'écran `EcranOnboarding`.
- Enum : `lib/domain/enums/niveau_experience.dart` ; usages existants :
  `accueil_notifier.dart`, `evaluateur_recommandations.dart`.
