# ADR-0014 — Calcul d'associations exhaustif & explicable (+ fiche min/max)

- **Statut** : Accepté — **lots 1 à 8 livrés** (2026-06-18)
- **Date** : 2026-06-17 (révisé 2026-06-18 : ajout de la Décision 0, extension du schéma)
- **Contexte** : à l'usage (vue « Artichaut »), deux manques apparaissent dans le
  **moteur de dérivation** ([ADR-0010](0010-associations-multi-mecanismes.md)) et
  sa restitution :

  1. **Règles trop grossières / critères ignorés.** Beaucoup de règles ne testent
     qu'une *présence* de trait, pas une *comparaison réelle*. Ex. « Étagement /
     ombre » se déclenche dès que la centrale est **haute (≥150 cm)** et que la
     voisine **tolère** la mi-ombre (`soleilMin`) — **sans vérifier que la voisine
     est nettement plus basse**, et **sans distinguer** « tolère » de « préfère »
     l'ombre. Comme ~18 légumes ont `soleilMin: mi_ombre` tout en ayant `soleil:
     plein_soleil` (leur **optimum**), l'artichaut « ombre » tout le potager.
     Plusieurs critères du modèle (**eau, espace/`espacementCm`, périodes,
     familles partagées**) et plusieurs mécanismes déjà définis en
     [ADR-0013](0013-vocabulaire-mecanismes-et-groupement-vue.md)
     (`competitionEau`, `competitionEspace`, `partageMaladies`) **ne sont pas
     exploités**.
  2. **Explication floue.** Le bandeau de fiche affiche des phrases génériques
     (« inférence plausible à partir d'un ou deux traits »). L'utilisateur ne
     peut pas savoir **quelles variables** ont produit l'association.

  Décision actée avec le dev : le moteur doit devenir **le plus précis possible**
  (toute variable disponible exploitée, comparaisons réelles), et **chaque
  variable entrant dans un calcul doit être explicitement notifiée** dans la
  fiche — *rien dans le flou*. Les fiches doivent aussi afficher les **min–max**
  (ex. exposition « mi-ombre à plein soleil »).

---

## Décision 0 — Extension du schéma de fiche (pour ne **rien** laisser hors calcul)

Pour que **toutes** les possibilités entrent dans le calcul (objectif « le moins
d'approximation possible »), on ajoute au schéma de fiche les traits manquants :

- **`enracinement`** (nouvel enum `EnracinementPlante { superficiel, moyen,
  profond, pivotant }`) — décrit la profondeur/forme racinaire. Rend
  `ameublissementSol` **dérivable** (une racine `pivotant`/`profond` décompacte
  pour une voisine `superficiel`) et affine la concurrence racinaire.
- **`usages: [attire_auxiliaires]`** (nouvelle valeur `UsagePlante.attireAuxiliaires`)
  — la plante attire les **auxiliaires** (prédateurs/parasitoïdes). Rend
  `attractionAuxiliaires` **dérivable** (elle protège une voisine sujette à des
  ravageurs de sa famille).

Champs **optionnels** (rétrocompatibles) : une règle qui en dépend est **ignorée**
quand l'info manque (aucune fausse donnée). Les fiches sont enrichies au fil de
l'eau (donnée agronomique connue : carotte/radis = `pivotant`, laitue =
`superficiel`, aneth/fenouil = `attire_auxiliaires`…). BDD greenfield + fiches
YAML → **aucune migration drift**.

Avec la Décision 0, **seule `allelopathie` reste curatée** (phénomène chimique
sans trait mesurable) ; **tous les autres mécanismes deviennent dérivables**.

## Décision 1 — Évidences structurées : chaque association porte ses critères

Une suggestion dérivée porte désormais la **liste des critères évalués qui ont
contribué** : un `Set<CritereAssociation>` (enum de domaine). Chaque règle, quand
elle se déclenche, **déclare** les sous-conditions qui l'ont validée.

- L'enum `CritereAssociation` énumère **toutes** les sous-conditions du moteur
  (ex. `fixeAzote`, `besoinAzoteEleveCible`, `plusHauteQueCible`, `prefereOmbre`,
  `tolereOmbre`, `eauElevee2x`, `familleCommune`, `maladieCommune`, …).
- La couche présentation possède un **explicateur** : pour chaque critère, une
  phrase localisée **avec les valeurs réelles** des deux fiches (ex. « Artichaut
  culmine à 150 cm, Laitue à 30 cm »). La vue Associations a déjà les **deux
  fiches** + `l10n` → elle construit la liste complète et la passe au bandeau.

> Le moteur reste **pur** (il ne produit que des enums) ; le formatage localisé
> et les valeurs vivent en présentation. La logique (« quels critères ont fait
> foi ») reste **unique** (côté moteur), pas de duplication/dérive.

## Décision 2 — La phrase de confiance vague est **remplacée** par la liste exhaustive

Fini « inférence plausible à partir d'un ou deux traits ». Le bandeau de fiche
(ouvert depuis la vue) liste **tous** les facteurs (Décision 1), chacun avec sa
valeur. Le **niveau de confiance** (faible/moyenne/élevée) reste affiché comme
*étiquette de tri*, mais il est désormais **dérivé du nombre et de la force des
critères réunis** (calibrage en Lot 2), et **toujours** accompagné du détail.
Les `confianceExpl*` génériques d'[ADR-0013](0013-vocabulaire-mecanismes-et-groupement-vue.md)
sont **supprimés**.

## Décision 3 — Règles **précises** : matrice mécanisme → critères

Chaque règle passe d'une présence à une **comparaison réelle** (seuils
explicites, calibrables). Matrice cible (a = centre, b = voisine ; sens *donne*) :

### Bénéfices
| Mécanisme | Critères précis (tous notifiés) | Confiance |
|---|---|---|
| **Fixe l'azote** | `a.fixeAzote` **+** `b.besoinAzote = élevé` | élevée |
| **Étagement / ombre** | `a` plein soleil **+** `a` haute **+** `b` **nettement plus basse** (`b.hMax ≤ a.hMax × 0,5`) **+** `b` **préfère** (`b.soleil ∈ {mi-ombre, ombre}`) *ou* **tolère** (`b.soleilMin ∈ {mi-ombre, ombre}`) l'ombre | **préfère → moyenne ; tolère → faible** |
| **Tuteur naturel** | `a` support (tuteur vivant *ou* haut non-grimpant) **+** `a` **plus haute que** `b` **+** `b` grimpante **+** `b.chargeTuteur ≠ lourde` | moyenne |
| **Attire pollinisateurs** | (`a` mellifère *ou* pollinisateur) **+** `b` entomophile | moyenne |
| **Attire auxiliaires** | `a` usage `attire_auxiliaires` **+** la famille de `b` a des ravageurs connus (que les auxiliaires régulent) | moyenne |
| **Succession** | chevauchement **calendaire** réel (Décision 5) ; repli durée court×long si périodes absentes | faible→moyenne |
| **Couvre-sol / Brise-vent** | usage correspondant sur `a` | faible |
| **Brouillage olfactif** | `a` & `b` aromatiques **+** l'une répulsive | faible |
| **Éloigne un ravageur / Plante-piège** | `a` répulsive/piège contre un bioagresseur **de la famille de** `b` (slug) | élevée |
| **Ameublit le sol** | `a.enracinement ∈ {pivotant, profond}` **+** `b.enracinement = superficiel` (la racine profonde décompacte pour la superficielle) | moyenne |

### Conflits
| Mécanisme | Critères précis | Confiance |
|---|---|---|
| **Même famille** | familles botaniques normalisées égales | élevée |
| **Concurrence lumière** | `a` & `b` **exigent** le plein soleil (`soleil = plein_soleil` **et** non tolérantes ombre) **+** toutes deux hautes | moyenne |
| **Concurrence azote** | `a.besoinAzote = élevé` **+** `b.besoinAzote = élevé` | moyenne |
| **Concurrence eau** | `a.eau = élevé` **+** `b.eau = élevé` | moyenne |
| **Concurrence espace** | `a.espacementCm` **et** `b.espacementCm` ≥ seuil « étalé » (ex. 70 cm) | moyenne |
| **Maladies partagées** | familles **différentes** **+** intersection non vide de leurs `maladiesCommunes` (via `ResolveurFamille`) | moyenne |
| **Allélopathie** | *(curaté : chimique, pas de trait)* | — |

> **Complémentarité = absence de conflit, pas un faux bénéfice.** Quand les
> besoins (eau/lumière/espace) **diffèrent**, on **n'émet pas** le conflit
> correspondant ; on n'invente pas pour autant un bénéfice « ressources
> complémentaires » (cela inonderait la vue). Le critère « besoins différents »
> est donc utilisé pour **ne pas** signaler une concurrence, ce qui est notifié
> à l'utilisateur dans la fiche le cas échéant.

## Décision 4 — Activer les mécanismes dormants **dérivables**

`competitionEau`, `competitionEspace`, `partageMaladies`, **`ameublissementSol`**
et **`attractionAuxiliaires`** reçoivent une règle (Décisions 0 & 3). Seule
`allelopathie` **reste curatée** (chimique, sans trait mesurable).

## Décision 5 — Succession **calendaire** (périodes réelles)

`successionTemporelle` s'appuie sur `PeriodesCulture` (semis/plantation/récolte) :
deux cultures se succèdent si **l'occupation de l'une se libère avant l'autre**
(récolte de A avant plantation/semis de B, ou inverse). Les périodes étant
indexées par **hémisphère × climat**, l'évaluation prend l'hémisphère/climat de
l'utilisateur ; **repli** sur l'heuristique de durée (court ≤60 j × long ≥100 j)
quand les périodes manquent. Critères notifiés : les fenêtres concernées.

## Décision 6 — Fiche : afficher les **min–max** + bandeau exhaustif

- **Squelette de fiche** : afficher les fourchettes quand un min existe et
  diffère du principal — ex. exposition « **mi-ombre à plein soleil** » (au lieu
  de « plein soleil »), hauteur « 100–150 cm », pH « 6,0–7,0 ». Source de vérité
  unique : un helper de formatage des plages.
- **Bandeau d'association** (depuis la vue) : liste **tous** les facteurs
  (Décision 1) avec leurs valeurs ; le niveau de confiance reste en étiquette.

## Décision 8 — **Tout mécanisme dérivable est pondérable** par l'utilisateur

Exigence : tout ce que le moteur sait dériver doit pouvoir être **priorisé par
l'utilisateur** dans les paramètres (« c'est plus important pour mon usage »).

- **Bénéfices** : déjà pondérables par **famille d'effet**
  ([ADR-0011](0011-scoring-ponderation-associations.md)). Les nouveaux bénéfices
  dérivables se rattachent à des familles **existantes** (`ameublissementSol →
  fertilité`, `attractionAuxiliaires → protection ravageurs`) → **automatiquement
  pondérables**, sans nouveau curseur.
- **Conflits** : aujourd'hui **non pondérés** (avertissements, triés par confiance
  seule). On **étend la pondération aux conflits** via des **familles de conflit**
  (regroupement thématique, peu de curseurs) :
  - **Concurrence ressources** : `competitionLumiere`, `competitionEau`,
    `competitionEspace`, `competitionAzote` ;
  - **Risque sanitaire** : `memeFamilleRavageurs`, `partageMaladies` ;
  - **Allélopathie** : `allelopathie`.

  Le profil porte donc aussi un poids par **famille de conflit** ; le scoreur
  devient `score(conflit) = poids(familleConflit) × facteur(confiance)` (au lieu
  de la confiance seule), et un poids **`ignore`** **masque** cette classe
  d'avertissements. Le panneau de pondération expose ces familles en plus des
  familles de bénéfice.

> Révise [ADR-0011](0011-scoring-ponderation-associations.md) (qui posait
> *« les conflits ne sont pas pondérés »*). Garde-fou : par défaut, toutes les
> familles (bénéfice **et** conflit) sont à **`normal`** → comportement inchangé.

---

## Découpage en lots livrables

Chaque lot laisse l'app verte (`flutter analyze` + suite). Tests en parallèle.

| Lot | Périmètre | Dépendance |
|---|---|---|
| **1 — Schéma & domaine** | enum `EnracinementPlante` ; `UsagePlante.attireAuxiliaires` ; champ `enracinement` (optionnel) sur `FichePlante` ; mapper + validateur + `_schema` YAML ; libellés i18n. Tests (mapping/validateur). | — |
| **2 — Évidences & explicabilité** | enum `CritereAssociation` ; `criteres` (`Set`) sur `SuggestionAssociation` ; explicateur présentation `expliquerAssociation(mecanisme, ficheCentre, ficheCible, sens, criteres)` → `List<String>` avec valeurs ; bandeau de fiche listant tout ; **suppression** des `confianceExpl*` génériques ; i18n des critères. Tests (chaque critère → phrase). | ADR-0010/0013 |
| **3 — Précision des règles existantes** | étagement (écart de hauteur + préfère/tolère), tuteur (plus haut que la cible), concurrence lumière (plein soleil **exigé**) ; **recalibrage de la confiance** depuis les critères. Tests (cas limites). | Lots 1–2 |
| **4 — Mécanismes dormants dérivés** | règles `competitionEau`, `competitionEspace`, `partageMaladies`, `ameublissementSol`, `attractionAuxiliaires`. Tests. | Lots 1–2 |
| **5 — Succession calendaire** | `successionTemporelle` via `PeriodesCulture` (hémisphère/climat utilisateur) + repli durée. Tests. | Lot 2 |
| **6 — Fiche min–max** | helper de formatage des plages ; exposition/hauteur/pH en fourchette dans la fiche. Tests widget. | — |
| **7 — Contenu** | enrichir les fiches existantes (`enracinement`, `attire_auxiliaires`) avec la donnée agronomique connue ; `catalogue_reel_test`. | Lot 1 |
| **8 — Pondération des conflits** | `FamilleEffetConflit` (3 familles) + poids dans `ProfilPonderationAssociations` ; scoreur pondère les conflits ; panneau de pondération + persistance ; `ignore` masque la classe. Tests. | ADR-0011 |

---

## Conséquences

### Positives
- **Précision** : comparaisons réelles (hauteur, eau, espace, soleil, périodes,
  maladies de famille) au lieu de présences brutes → moins de faux positifs
  (artichaut n'« ombre » plus tout le monde), plus de vrais signaux.
- **Transparence totale** : chaque variable du calcul est notifiée dans la fiche,
  avec sa valeur ; plus aucune phrase floue.
- **Fiche plus juste** : les fourchettes (min–max) reflètent la réalité agronomique.
- **Réutilisation** : on exploite enfin tous les champs du modèle de domaine et
  les mécanismes d'[ADR-0013](0013-vocabulaire-mecanismes-et-groupement-vue.md).

### Négatives / risques
- **Révise [ADR-0010](0010-associations-multi-mecanismes.md)** (modèle de
  suggestion + règles) et **[ADR-0013](0013-vocabulaire-mecanismes-et-groupement-vue.md)**
  (suppression des `confianceExpl*`) — notes de révision à porter.
- **Schéma de fiche étendu** (Décision 0) : `enracinement` + usage
  `attire_auxiliaires`. Champs optionnels, rétrocompatibles ; à **renseigner**
  progressivement (Lot 7). Seule `allelopathie` reste curatée. **Discipline
  migration drift** non concernée (catalogue YAML, pas la BDD utilisateur).
- **Calibrage** des seuils (hauteur ×0,5 ; espacement ≥70 cm ; …) à affiner avec
  le dev — exposés en constantes.

---

## Liens
- [ADR-0010](0010-associations-multi-mecanismes.md) — taxonomie & dérivation (révisé : règles précises + évidences).
- [ADR-0011](0011-scoring-ponderation-associations.md) — scoring (révisé : les **conflits deviennent pondérables** par famille de conflit, Décision 8).
- [ADR-0013](0013-vocabulaire-mecanismes-et-groupement-vue.md) — mécanismes (3 activés), bandeau de fiche (enrichi), `confianceExpl*` (retirés).
- Code : `application/engine/moteur_derivation_associations.dart`, `application/engine/suggestion_association.dart`, `domain/enums/critere_association.dart` (nouveau), `presentation/widgets/vue_associations.dart`, `fiche_plante_detail.dart`.
