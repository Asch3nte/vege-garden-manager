# ADR-0010 — Modèle d'associations multi-mécanismes (permaculture)

- **Statut** : Accepté — **Lots 1 à 4 livrés** (2026-06-16)
- **Date** : 2026-06-15
- **Contexte** : la vocation de Pot'à Gérer est de promouvoir des cultures
  **naturelles et permacoles**. Or, aujourd'hui, les associations de plantes se
  réduisent à deux listes d'`id` (« bénéfiques » / « négatives ») exposées par
  les prédicats `FichePlante.sAssocieBienAvec` / `entreEnConflitAvec`, résolues
  par `ResolveurCompagnonnage` (ADR-0008) en `bon` / `aEviter` / `aucune`. Deux
  limites :

  1. **La raison n'est pas modélisée.** Le YAML porte une `raison_i18n` par
     paire (`associations.beneficies[].raison_i18n`), mais elle **n'est même pas
     chargée** dans le domaine, et surtout elle est en **texte libre** : le
     programme ne « sait » pas *pourquoi* deux plantes vont ensemble.
  2. **Aucune dérivation.** Seules les paires saisies à la main existent. L'app
     ne peut pas *suggérer* des associations permacoles classiques (maïs +
     haricot grimpant, tomate + œillet d'Inde, carotte + oignon…) à partir de ce
     qu'elle sait déjà des plantes.

  Pourtant **les données structurées nécessaires existent déjà** largement :
  - `usages` (`UsagePlante`) : `repulsif`, `mellifere`, `pollinisateur`,
    `couvreSol`, `briseVent`, `tuteurVivant`, `engraisVert`…
  - traits : `cultureVerticale`, `fixeAzote` + `besoinAzote`, `ensoleillement` /
    `ensoleillementMin`, `hauteurAdulteCm`, `dureeAvantRecolteJours`,
    `espacementCm` ;
  - famille : `ravageursCommuns` / `maladiesCommunes` — **référentiel normalisé
    `Bioagresseur`** livré par [ADR-0006](0006-fiches-famille-botanique.md)
    Lot 4a.

  Le manque n'est donc pas (surtout) de la donnée : c'est de **typer** les
  mécanismes d'association et de les **raisonner**.

---

## Décision 1 — Une taxonomie typée des mécanismes d'association

On qualifie chaque association par un **mécanisme** (enum), traduisible et
exploitable par le moteur, plutôt que par du texte libre. Une raison libre
(`raison_i18n`) reste possible **en complément** pour la nuance éditoriale.

### Bénéfices (`TypeBeneficeAssociation`)

| Mécanisme | Principe | Dérivable de | Exemple |
|---|---|---|---|
| **tuteurStructurel** | une plante sert de support physique à une grimpante | support : `tuteurVivant` ou (hauteur élevée + tige solide) × grimpant : `cultureVerticale` + charge compatible | maïs + haricot grimpant |
| **etagementLumiere** | étager la végétation / faire de l'ombre aux plantes qui la tolèrent | A `plein_soleil` & haute × B `ensoleillementMin: mi_ombre/ombre` | maïs ⟶ laitue ; tomate + basilic |
| **repulsionRavageur** | une plante répulsive éloigne un ravageur ciblé du voisin sensible | A `repulsif` + `repulsifContre:[slug]` × B sensible au slug (famille) | tomate + œillet d'Inde |
| **brouillageOlfactif** | mélange d'odeurs qui désoriente les ravageurs (souvent réciproque) | aromatiques fortes se protégeant mutuellement | carotte + oignon/poireau |
| **attractionPollinisateurs** | attirer les pollinisateurs au profit d'une plante entomophile | A `mellifere` **ou** `pollinisateur` × B entomophile | bourrache + courgette |
| **plantePiege** | détourner un ravageur sur une plante-appât | A + `piegeA:[slug]` × B sensible | capucine + fève (pucerons) |
| **fixationAzote** | une légumineuse enrichit le sol pour une gourmande | A `fixeAzote` × B `besoinAzote: eleve` | haricot + maïs |
| **couvreSol** | couvrir le sol (adventices, humidité) | usage `couvreSol` / port étalé bas | courge (milpa) |
| **briseVent** | protéger du vent | usage `briseVent` | haie + cultures sensibles |
| **successionTemporelle** | cycle court + cycle long sur la même place | `dureeAvantRecolte` court (A) vs long (B) | radis + carotte ; ail + mâche |

> **Note d'implication sémantique.** `usages` est un `Set<UsagePlante>`
> (plusieurs valeurs par plante). Certaines valeurs **en impliquent** d'autres
> sans réciprocité — une plante **mellifère** attire de fait les pollinisateurs
> (mellifère ⟹ pollinisateur, pas l'inverse). Le modèle stocke les usages
> **littéralement** (pas d'implication auto) ; c'est la **règle de dérivation**
> qui applique l'implication (la règle `attractionPollinisateurs` se déclenche
> sur `mellifere` *ou* `pollinisateur`). À centraliser dans la politique
> d'associations, comme `AccesNiveau` pour les paliers.

### Conflits (`TypeConflitAssociation`)

| Mécanisme | Dérivable de |
|---|---|
| **memeFamilleRavageurs** | A.famille == B.famille → ravageurs/maladies partagés (référentiel `Bioagresseur`) |
| **competitionLumiere** | deux `plein_soleil` hautes côte à côte |
| **competitionAzote** | deux `besoinAzote: eleve` |
| **allelopathie** | **curaté** (non dérivable) — ex. fenouil, juglone du noyer |

---

## Décision 2 — Deux couches complémentaires

**A. Couche curatée (typée).** On enrichit `associations.beneficies/defavorables`
d'un champ `type:` (le mécanisme) et on **charge enfin la raison** dans le
domaine. Le couple (paire → mécanisme [+ raison]) devient une **value object**.
C'est la source d'autorité, sous contrôle éditorial.

> **Choix d'implémentation (Lot 1).** Plutôt qu'un VO générique unique, on a
> retenu **deux classes distinctes** — `AssociationBenefique` (mécanisme
> `TypeBeneficeAssociation?`) et `AssociationConflit` (mécanisme
> `TypeConflitAssociation?`) — pour garder les deux enums de mécanismes séparés
> au typage. Chacune porte `cibleId` + mécanisme optionnel + `raison(locale)`.
> Cf. `docs/05` §4.8.

> ⮑ Débloque immédiatement **[ADR-0008](0008-vue-reseau-familles-et-focus.md)
> Lot « Raisons »** et `docs/15` §8 #11 : la « raison » affichée devient un
> **libellé typé** (localisé), plus du texte opaque.

**B. Couche dérivée (moteur pur).** Des **règles** (`application/engine/`)
infèrent des associations **typées** à partir des traits/usages/bioagresseurs,
avec une **raison auto-générée** et un **niveau de confiance**. C'est ce qui rend
l'app *intelligente* : proposer la milpa ou tomate+œillet sans qu'aucune paire
n'ait été saisie. Réutilisable par le moteur de recommandation pour le
**placement**.

Précédence : une association **curatée prime** sur une suggestion dérivée
(l'éditorial peut confirmer, nuancer ou contredire une règle).

---

## Décision 3 — Nouveaux champs (légers, optionnels)

Sur `FichePlante` / le YAML :
- `repulsif_contre: [slug]` — ravageurs/maladies que la plante **repousse**
  (référencent le **référentiel `Bioagresseur`** ; intégrité référentielle comme
  `rotation.famille`).
- `piege_a: [slug]` — ravageurs que la plante **piège**.
- `charge_tuteur:` (optionnel) `legere | moyenne | lourde` — pour la contrainte
  « grimpante pas trop lourde pour le support » (ex. haricot = légère, courge
  coureuse = lourde). À défaut, dérivation approchée par catégorie/hauteur.

Sur le mécanisme curaté : `type:` (enum) + `raison_i18n` (optionnelle, nuance).

Aucune migration BDD : ce sont des données de **catalogue YAML embarqué**, pas
des tables utilisateur.

---

## Décision 4 — Garde-fous

1. **Rétrocompatible** : les fiches sans `type:` restent valides (le type est
   alors `null` / « non précisé » et la paire compte comme aujourd'hui).
2. **Jamais de fausse donnée** (règle docs/15) : une suggestion dérivée est
   **présentée comme suggestion** (avec sa raison), distincte d'une association
   curatée ; on n'invente pas de raison sur une paire curatée muette.
3. **Divulgation progressive** ([ADR-0009](0009-paliers-experience-divulgation-progressive.md))
   : les suggestions dérivées avancées peuvent être gardées (inter+/expert) ; le
   cœur (paires curatées bon/à-éviter) reste visible à tous.

---

## Découpage en lots livrables (après Bloc 1 d'ADR-0006)

Chaque lot laisse l'app verte (`flutter analyze` + suite). Tests en parallèle.

| Lot | Périmètre | Dépendance |
|---|---|---|
| **1 — Modèle typé + raisons chargées + UI** ✅ | enums `TypeBeneficeAssociation` / `TypeConflitAssociation` ; VO `AssociationBenefique` / `AssociationConflit` (cible + type + raison) ; `FichePlante` charge `type`+`raison_i18n` ; `ResolveurCompagnonnage` expose mécanisme + raison (`beneficeEntre`/`conflitEntre`, `CompagnonAvecRaison`) ; **vue Associations affiche la puce mécanisme typé + la raison éditoriale** (libellés ARB `assocMeca*`). | ADR-0008 |
| **2 — Champs ciblés** ✅ | `repulsif_contre` / `piege_a` (slugs `Bioagresseur`, `Set<String>` sur `FichePlante` + prédicats `repousse`/`piege`) + **intégrité référentielle** (`VerificateurIntegriteRepulsifs` : couverture + cohérence `piege_a`⟹ravageur, gardé par `catalogue_reel_test`) ; enum `ChargeTuteur` + champ `charge_tuteur` (sous `cycle`). Validateur + schéma à jour. | ADR-0006 Lot 4a ✅ |
| **3 — Moteur de dérivation** ✅ | `MoteurDerivationAssociations` (pur, `application/engine/`) → `SuggestionAssociation` scellée (`SuggestionBenefique`/`SuggestionConflit`) + `NiveauConfiance` ; règles bénéfices (fixation azote, pollinisateurs, tuteur, étagement, succession, couvre-sol, brise-vent, brouillage, répulsion/piège via `ResolveurFamille`) et conflits (même famille, concurrence lumière/azote) ; `suggestionsNouvelles` applique la **précédence curatée** ; tests par règle. | Lots 1–2 |
| **4 — Intégration reco/placement + UI** ✅ | reco : bonus d'association **dérivée** dans `EvaluateurRecommandations` (curatée 1.0 > dérivée 0.8 > rien 0.5, `RaisonReco.associationDeriveeFavorable`), calculé par `RecommanderPlantes` (≥ moyen, traits seuls) ; UI : la **vue Associations** affiche les suggestions dérivées (puce mécanisme + badge « Suggéré » + confiance), **gardées par palier** (intermédiaire+, `AccesNiveau.vueReseau`). | Lot 3, ADR-0009 |

---

## Conséquences

### Positives
- Aligne le produit sur sa **vocation permacole** : l'app *raisonne* les
  associations au lieu de réciter des paires.
- **Réutilise** l'existant (usages, traits, référentiel bioagresseurs) ; peu de
  donnée neuve.
- **Débloque** les « raisons » d'ADR-0008 / docs/15 §8 #11 via les mécanismes
  typés.
- Source unique et testable (règles pures), cohérente avec la Clean Architecture.

### Négatives / risques
- Le moteur de dérivation peut produire des suggestions **trop génériques** ou
  fausses → calibrer les règles, garder la précédence curatée, afficher la
  confiance.
- Surface éditoriale : typer les paires existantes est un travail de contenu
  (mitigé : `type` optionnel, migration incrémentale).

---

## Liens
- [ADR-0006](0006-fiches-famille-botanique.md) — référentiel `Bioagresseur` (pré-requis du Lot 2).
- [ADR-0008](0008-vue-reseau-familles-et-focus.md) — Lot « Raisons » débloqué par le Lot 1.
- [ADR-0009](0009-paliers-experience-divulgation-progressive.md) — gating des suggestions avancées.
- Registre : `docs/15` §4 (catalogue), §8 #11 (raisons des associations).
- Code : `lib/domain/enums/usage_plante.dart`, `lib/domain/entities/fiche_plante.dart`, `lib/domain/services/resolveur_compagnonnage.dart`.
