# ADR-0012 — Associations directionnelles & refonte de la vue Associations

- **Statut** : Accepté — **Lots 1 à 6 livrés** (2026-06-17)
- **Date** : 2026-06-16
- **Contexte** : après [ADR-0010](0010-associations-multi-mecanismes.md) (dérivation
  typée) et [ADR-0011](0011-scoring-ponderation-associations.md) (scoring +
  pondération), la **vue Associations** reste difficile à lire en usage réel
  (cf. capture « Carotte ») :

  1. **Texte tronqué partout.** Les nœuds affichent la `raison_i18n` libre des
     paires curatées (texte gris, souvent long) → chevauchements et `…` dans la
     majorité des cas.
  2. **Pas de hiérarchie de lecture des libellés.** 14 mécanismes précis = des
     libellés longs et nombreux.
  3. **Direction perdue.** Le moteur calcule pourtant un **sens** (« A rend
     service à B »), mais la vue fusionne les deux sens et ne le montre pas.
  4. **Placement naïf.** Les nœuds sont posés sur deux arcs ; au-delà de quelques
     compagnons, bulles et labels se chevauchent (l'anti-chevauchement existe
     déjà côté vue Réseau, mais n'est pas réutilisé ici).

  Décision actée avec le dev : on **garde les relations curatées** (elles font
  autorité et encodent un savoir que le moteur ne dérive pas encore, ex.
  carotte + oignon « repousse la mouche »), mais on **change leur restitution**.

---

## Décision 1 — Le libellé affiché est la **famille d'effet**

Dans la constellation, un nœud n'affiche plus le mécanisme précis ni la raison
libre, mais la **famille d'effet** ([ADR-0011](0011-scoring-ponderation-associations.md) :
*gain de place, protection ravageurs, fertilité, pollinisation, couverture/abri*)
— **5 libellés courts, colorés**. C'est la réponse au besoin « regrouper
plusieurs mécanismes sous un même label » : plusieurs mécanismes d'une paire se
réduisent à leur(s) famille(s) (et beaucoup partagent déjà la même famille — ex.
*brouillage olfactif* + *répulsion* = **Protection** → une seule puce).

Le **mécanisme précis** et la **raison éditoriale** ne disparaissent pas : ils
passent sur la fiche (Décision 4).

## Décision 2 — Une paire curatée peut porter **plusieurs mécanismes**

Le champ YAML `type:` accepte désormais **un mécanisme OU une liste** (ex.
`type: [brouillage_olfactif, repulsion_ravageur]`), rétrocompatible avec le
`type:` simple d'ADR-0010. Le VO (`AssociationBenefique`/`AssociationConflit`)
porte un **`Set` de mécanismes** ; la (les) famille(s) en sont dérivées via
`familleDe`. Typer les paires curatées (sens (a)) finit de retirer le texte gris
de la vue.

## Décision 3 — Direction : *Donne / Reçoit / Mutuel*

Chaque association porte un **sens**, vu depuis la plante centrale :

| Sens | Signification | Source |
|---|---|---|
| **donne** (centre → X) | le centre rend service à X | dérivé : `deriver(centre, X)` ; curaté : paire déclarée **dans la fiche du centre** |
| **recoit** (X → centre) | X rend service au centre | dérivé : `deriver(X, centre)` ; curaté : paire déclarée **par la fiche de X** |
| **mutuel** (↔) | les deux | les deux sens présents (ex. *brouillage olfactif*, ou *même famille* pour un conflit) |

- **Rendu** : flèche orientée à l'extrémité du lien (double tête `↔` si mutuel).
- **Filtre** : sélecteur **Tout / Donne / Reçoit / Mutuel**, en plus du tri par
  score et du « voir plus » d'ADR-0011 (bons à gauche / à éviter à droite
  conservés).

> Le résolveur (`ResolveurCompagnonnage`) et le moteur exposent le sens ; la
> fusion des deux directions (qui le perdait) est remplacée par une agrégation
> **qui conserve le sens** (mutuel = union des deux).

## Décision 4 — Zéro texte tronqué : raison en **bandeau de fiche**

La vue n'affiche que **nom + puce(s) famille + flèche** — court par construction,
donc jamais tronqué. La **raison complète** (la `raison_i18n` curatée, ou une
phrase courte auto pour un dérivé) s'affiche en **bandeau coloré** (vert = bon /
rouge = à éviter) **en haut de la fiche** ouverte au tap.

Le comportement de clic est **inchangé** (taper le nœud — bulle ou label — ouvre
la fiche de la plante) ; on enrichit `afficherFichePlanteDetail` d'un **contexte
d'association** optionnel (sens + famille/mécanisme + raison localisée) qui pilote
le bandeau. Pas de « vue plein texte » séparée.

## Décision 5 — Réutiliser l'anti-chevauchement de la vue Réseau

On **reprend le principe** de `LayoutReseauFamilles` (placement *pur,
déterministe, sans chevauchement*) mais, le packing existant groupant par
*famille* (inadapté à l'ego-graphe par *côté*), on écrit un layout **dédié**
`LayoutVueAssociations` : **anneaux concentriques par demi-plan** (bons à gauche,
à-éviter à droite), remplis vers l'extérieur. Le pas (tangentiel et radial) vaut
le **cercle englobant** de la boîte (sa diagonale), ce qui garantit
mathématiquement que deux nœuds d'un même côté ne se chevauchent jamais (bulles
**et** labels à largeur fixe). Le canvas est auto-dimensionné à la boîte
englobante (aucun rognage ; `InteractiveViewer` zoome/déplace).

> **Écart assumé vs intention initiale** : on n'appelle pas littéralement le
> packer de familles (il ne mappe pas l'ego/côtés) ; le layout dédié est plus
> simple et offre une **garantie** de non-chevauchement par côté.

---

## Découpage en lots livrables

Chaque lot laisse l'app verte (`flutter analyze` + suite). Tests en parallèle.

| Lot | Périmètre | Dépendance |
|---|---|---|
| **1 — Sens dans le modèle** ✅ | enum `SensAssociation {donne,recoit,mutuel}` ; `ResolveurCompagnonnage.sensBenefice/sensConflit` + `CompagnonAvecRaison.sens` (curaté, via le côté déclarant) ; `SuggestionAssociation.sens` (dérivé : `deriver`=donne, relabel=recoit, `suggestionsNouvelles` fusionne en mutuel). Tests. | ADR-0010 |
| **2 — Multi-mécanismes + famille-label** ✅ | `type:` accepte token **ou liste** ; VO portent `mecanismes` (`Set`, + getter `mecanisme` de compat) ; mapper + validateur gèrent les deux formes ; helper `famillesDe(Set)` ; rétrocompat totale. Tests. | ADR-0011 |
| **3 — Layout anti-chevauchement** ✅ | `LayoutVueAssociations` pur (`reseau/layout_vue_associations.dart`) : anneaux concentriques par demi-plan (bons gauche / à-éviter droite), chaque anneau rempli à capacité (largeur de boîte en tangentiel, hauteur en radial — plus serré), **surplus en anneaux extérieurs décalés d'un demi-pas** (anti-alignement → un lien ne traverse plus une bulle interne). **Centre recentré** (canvas = vue) ; zoom/pan **élargis** (minScale 0.2, boundaryMargin 2000) pour atteindre le débordement. Tests. | — |
| **4 — Rendu directionnel + filtre** ✅ | `_NoeudAssoc.sens` propagé (curaté + dérivé) ; `_Peintre` dessine des **flèches orientées** (tête côté nœud=donne, côté centre=reçoit, **les deux**=mutuel ; extrémités rognées sur les bulles) ; **filtre** Tout/Donne/Reçoit/Mutuel (`_BarreFiltreSens` en `AppBar.bottom`, ChoiceChips) qui élague la vue. Troncatures des puces de conflit + ligne « Suggéré · … » corrigées au passage. Tests filtre. | Lots 1–3 |
| **5 — Bandeau de raison sur la fiche** ✅ | `ContexteAssociation` (bon/à-éviter + mécanisme + raison + suggéré/confiance) → `afficherFichePlanteDetail` ; `_BandeauAssociation` coloré (vert/rouge) en tête de fiche, **raison complète non tronquée** ; **texte gris retiré de la constellation** (ne reste que nom + puce + flèche). Tests. | Lots 1–2 |
| **6 — Contenu** ✅ | **80 paires curatées typées** dans les fiches (`type:` simple ou liste) là où la `raison_i18n` indique clairement un mécanisme ; paires ambiguës laissées **non typées** (pas de fausse donnée) ; multi-mécanismes (ex. capucine = piège + pollinisateurs) ; gardé par `catalogue_reel_test`. | Lot 2 |

---

## Conséquences

### Positives
- **Lisibilité** : libellés courts (familles), **aucun texte tronqué**, placement
  sans chevauchement.
- **Sens explicite** : flèches + filtre par direction → l'utilisateur comprend
  *qui aide qui* et peut cibler.
- **Réutilisation** : familles (ADR-0011), packing (vue Réseau), précédence
  curatée (ADR-0010) ; pas de moteur réécrit.
- **Le savoir éditorial reste** (raison complète sur la fiche), sans polluer la
  constellation.

### Négatives / risques
- Le `type:` en liste + le sens **revisitent** les VO d'ADR-0010 (Lot 2) — churn
  contenu/code maîtrisé par la rétrocompatibilité.
- Extraire/adapter le packing (Lot 3) est non trivial (le code actuel groupe par
  famille) — l'algorithme de fond est néanmoins déjà là.

---

## Liens
- [ADR-0010](0010-associations-multi-mecanismes.md) — dérivation typée, précédence curatée.
- [ADR-0011](0011-scoring-ponderation-associations.md) — familles d'effets (réutilisées comme libellés), scoring, filtre.
- Capture de référence : vue « Carotte » (texte gris tronqué).
- Code : `lib/presentation/widgets/vue_associations.dart`, `reseau/layout_reseau_familles.dart`, `domain/services/resolveur_compagnonnage.dart`, `application/engine/`.
