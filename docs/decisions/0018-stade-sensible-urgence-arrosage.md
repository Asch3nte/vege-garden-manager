# ADR-0018 — Phase sensible × stade de croissance → modulation de l'urgence d'arrosage

- **Statut** : **Proposé** — non planifié, **candidat post-V1**. Aucune ligne de
  code. Ce document fige le cadrage et les questions ouvertes pour une session
  ultérieure.
- **Date** : 2026-07-08
- **Prérequis avant toute implémentation** : (1) corpus de fiches réellement
  renseigné en `phases_sensibles` au-delà des 6 espèces seedées ; (2) arbitrage
  de la question de neutralité par palier (ci-dessous) ; (3) recalibration +
  tests du moteur.

---

## Contexte

Les **besoins en eau détaillés** (docs/15 §9, `acces.eauDetaillee`) ont été
livrés **en affichage seul** : le VO optionnel `ArrosageDetaille` porte, entre
autres, un ensemble de `phasesSensibles` (enum `PhaseSensibleEau` :
`germination`, `feuillaison`, `floraison`, `fructification`, `grossissement`) —
les périodes du cycle où un stress hydrique est le plus dommageable. Ce sont des
**faits agronomiques documentés**, pas des chiffres inventés.

Le moteur d'arrosage (`BilanArrosage` / `CalculerBesoinArrosage`, ADR-0015)
**n'en tient pas compte** : il raisonne sur le terme grossier `BesoinEau` +
météo + sol + équipements + `toleranceSecheresse`. Ce choix était délibéré (voir
« Décision principale » ci-dessous, argument ADR-0009).

**Opportunité.** Le couplage le plus pertinent et le plus explicable serait :
*quand une plantation se trouve **dans** une de ses phases sensibles, relever
l'urgence/le besoin d'arrosage*. Message utilisateur immédiatement lisible :
« vos tomates sont en fructification, période sensible → arrosage prioritaire ».

## Forces en présence (les vraies difficultés)

1. **Décalage de granularité.** `PhaseSensibleEau` décrit **5 événements
   biologiques** ; `StadeCroissance` (dérivé par `CalculateurDatesCulture`) n'a
   que **4 stades grossiers** (`levee`, `croissance`, `maturation`, `recolte`),
   **agnostiques de l'espèce** (simple proportion de la durée avant récolte, pas
   de courbe par espèce — cf. `StadeCroissance` docstring & docs/15 §3). Il n'y a
   **pas de correspondance 1:1** :
   - `germination` ↔ `levee` ✅, `feuillaison` ↔ `croissance` ✅ ;
   - mais `floraison`, `fructification`, `grossissement` s'effondrent tous dans
     `croissance`→`maturation` — le stade dérivé **ne sait pas** distinguer
     floraison de fructification. Une table de correspondance
     `PhaseSensibleEau → StadeCroissance` **perd de la précision** (ou en
     invente). C'est la difficulté centrale.

2. **Garde-fou d'ADR-0009 (le point le plus structurant).** Le conseil
   d'arrosage est affiché à **tous les paliers** (débutant compris), alors que
   `arrosageDetaille` est un concept **réservé expert**. Si le moteur consommait
   cette donnée, **le même plant recevrait un conseil différent selon le palier
   de l'utilisateur** → violation de la règle « le gating gouverne l'affichage,
   **jamais** la donnée ni le calcul du cœur ». **À trancher** : soit le calcul
   devient **neutre par palier** (la donnée pilote le cœur **pour tous**, seul le
   *panneau de détail* reste gaté expert), soit on renonce au couplage. L'option
   « neutre par palier » préserve le garde-fou et est privilégiée.

3. **Disponibilité de la donnée.** Hors des 6 espèces seedées, les fiches ne
   portent pas encore `phases_sensibles`. Un couplage moteur n'est utile que
   lorsque le corpus est largement renseigné — sinon le comportement est
   **hétérogène** (certaines fiches modulent, d'autres non).

4. **Calibration.** `BilanArrosage` est une balance **calibrée et testée**
   (facteurs thermique, pluie pondérée, ET₀, tolérance sécheresse). Ajouter un
   multiplicateur de stade impose une **recalibration** et des tests dédiés, pas
   un simple branchement.

## Décision principale (déjà actée, rappelée ici)

Pour la livraison V1, **le moteur reste inchangé** ; le détail est **informatif**.
Raisons : garde-fou ADR-0009 (2), données absentes (3), risque sur un système
livré (4), et unités (`volume_litres_m2` ≠ modèle d'indice 0..1 actuel).

## Décision proposée (à instruire plus tard)

**Option retenue à instruire** : un **multiplicateur borné et neutre par palier**
appliqué à l'indice de besoin de `BilanArrosage` **quand le stade dérivé de la
plantation recouvre une phase sensible déclarée** par sa fiche.

- **Mapping explicite** `PhaseSensibleEau → {StadeCroissance}` (documenté, testé),
  assumant la perte de précision : p. ex. `floraison`/`fructification`/
  `grossissement` → `{croissance, maturation}`. Le mapping vit dans le domaine,
  pas dans le moteur.
- **Amplitude modeste**, même famille que les facteurs existants (ordre de
  `toleranceSecheresse`, ~×1.1–1.2), pour ne pas déséquilibrer la balance.
- **Neutre par palier** : le multiplicateur s'applique **pour tous** (données →
  cœur), l'affichage détaillé restant gaté expert → **garde-fou ADR-0009
  respecté**.
- **Explicabilité** : ajouter un drapeau structuré sur `ConseilArrosage`
  (p. ex. `phaseSensibleActive`) pour que l'UI puisse dire *pourquoi*
  (« période sensible : fructification »), fidèle à l'esprit « conseil
  explicable » d'ADR-0014/0015.

### Alternatives

- **A — Statu quo** : ne rien coupler, garder l'affichage seul. Le plus sûr ;
  perd le gain de pertinence.
- **B — Attendre une courbe de stade par espèce (V2)** : `StadeCroissance` prévoit
  déjà un raffinement V2 par espèce/variété. Coupler **après** ce raffinement
  éviterait le fudge de granularité (1) — au prix d'un report plus lointain.
- **C — Cadence/volume au lieu de l'urgence** : utiliser `frequenceJours` /
  `volumeLitresM2` pour un conseil **quantifié** (« ~4 L/m² tous les 2–3 j ») et
  un vrai **bilan hydrique** (mm pluie vs L/m² besoin). Plus lourd (nouveau
  modèle d'unités), traité séparément le cas échéant.

## Conséquences

- **Positives** : conseil plus pertinent et **raconté simplement** pendant les
  fenêtres critiques ; valorise une donnée déjà saisie ; cohérent avec la
  philosophie « autonomie + explicabilité ».
- **Négatives / risques** : imprécision du mapping (1) ; recalibration de la
  balance (4) ; dépend d'un corpus renseigné (3) ; surface de test élargie.

## Renvois

- ADR-0015 (moteur d'arrosage & facteur thermique) — la balance à étendre.
- ADR-0009 (divulgation progressive) — le garde-fou « gating = affichage seul ».
- docs/15 §9 (besoins en eau détaillés, livré) ; docs/15 §3 (`StadeCroissance`
  grossier, raffinement V2).
