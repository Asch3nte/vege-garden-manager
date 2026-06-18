# ADR-0008 — Vue Réseau du Catalogue : layout par familles, mode focus, et résolveur d'associations unifié

- **Statut** : Accepté
- **Date** : 2026-06-12
- **Contexte** : [ADR-0007](0007-vue-reseau-exploratoire.md) a doté la vue **Réseau**
  du Catalogue (`lib/presentation/widgets/vue_reseau_catalogue.dart`) d'un modèle
  de transformation explicite (zoom/pan), du recadrage animé, de
  l'anti-chevauchement des libellés (#8b) et du découpage BOX 1 (réseau) / BOX 2
  (feuille de fiches). Le **placement des nœuds** y reste une **spirale de Fermat
  plante-agnostique** : l'ordre n'a aucun sens botanique, les familles sont
  éparpillées. `docs/15` §10 (« à revoir ensuite ») relève deux dettes :

  1. **Positionnement initial par famille** — regrouper visuellement les espèces
     d'une même famille botanique (la donnée existe, pipeline ADR-0006 complet).
  2. **Compteurs de compagnons incohérents** entre la vue Réseau (bidirectionnel,
     sur **toutes** les espèces) et la fiche détaillée (unidirectionnel, sur les
     espèces **filtrées**) → écarts du type 17 / 2 / 0 pour la même plante.

  **Cadrage de l'échelle** (revue dev 2026-06-12) : à terme le catalogue peut
  compter beaucoup de fiches, mais le graphe ne représente que les **espèces
  (mères) potagères** — **pas** les variétés (une fiche par variété gonfle le
  total mais reste hors graphe), **pas** les ornementales. L'ordre de grandeur
  visé est donc **quelques centaines** de nœuds, pas des milliers.

  Deux constats structurants encadrent la décision :

  - Le **coût calcul** d'un placement par forces se maîtrise (quelques centaines
    de nœuds, solve unique à l'init, déterministe) — ce n'est pas le facteur
    limitant.
  - La **lisibilité** d'un node-link **complet** s'effondre bien avant le CPU :
    au-delà de quelques centaines de nœuds densément reliés, on obtient un
    *hairball* esthétique mais inexploitable pour *lire une relation précise*.
    Aucun algorithme de layout ne corrige cela — c'est une limite de l'œil, pas
    de la machine.

  Le besoin réel se dédouble donc : une **vue d'ensemble** lisible qui fait
  ressortir les **familles**, et une **vue d'analyse** focalisée qui fait
  ressortir les **types de relations** (bonnes / à éviter) d'une plante.

---

## Décision 1 — Un **résolveur d'associations unifié** (bidirectionnel, toutes espèces)

Les deux vues dérivent aujourd'hui les compagnons différemment :

| | Vue Réseau (`_compter`) | Fiche détaillée (`fiche_plante_detail.dart`) |
|---|---|---|
| **Direction** | bidirectionnelle (`i→j` **ou** `j→i`) | unidirectionnelle (`_fiche.sAssocieBienAvec` seul) |
| **Périmètre** | toutes les espèces (`vue.toutesMeres`) | liste **filtrée** (`vue.fiches`) |
| **Précédence** | bon > à éviter | bon et à éviter indépendants |

On **unifie** sur une **seule sémantique canonique** :

- **Bidirectionnelle** — le compagnonnage est une relation **mutuelle** : si l'une
  des deux fiches déclare l'association, elle vaut dans les deux sens (les données
  source sont souvent renseignées d'un seul côté).
- **Sur toutes les espèces mères** — les compagnons d'une plante ne doivent **pas**
  dépendre du filtre catégorie/famille/recherche actif. La fiche affichait jusque‑là
  une liste tronquée par le filtre courant ; c'est corrigé.
- **Précédence bon > à éviter** — si un couple est à la fois « bon » dans un sens
  et « à éviter » dans l'autre (cas marginal des données), il compte **une fois**,
  comme **bon**. Règle unique, appliquée des deux côtés.

**Mise en œuvre** : un **service pur** (couche `domain`, p. ex.
`domain/services/resolveur_compagnonnage.dart`) exposant, pour une fiche et un
catalogue d'espèces, ses compagnons `bons` et `àÉviter` (entités ou ids). Il
n'utilise que les **prédicats publics** de l'entité (`sAssocieBienAvec` /
`entreEnConflitAvec`) → respecte l'encapsulation, testable sous l'objectif de
couverture `domain` (80 %). **La vue Réseau ET la fiche détaillée le consomment**
→ les compteurs et les listes **coïncident par construction**.

**Conséquence visible** : la fiche détaillée listera désormais **plus** de
compagnons qu'avant (liste complète, bidirectionnelle, indépendante du filtre) —
changement assumé, validé en revue dev.

---

## Décision 2 — Layout **par bulles de famille** : packing de cercles déterministe

> **Révision après prototype.** Un premier prototype *force-directed* (répulsion +
> attraction par arête + cohésion famille) a été essayé : il laissait les
> familles **s'interpénétrer** (les arêtes inter-familles tirent les nœuds les
> uns vers les autres) et l'enveloppe convexe des halos faisait des **angles**.
> Revue dev : on exige **familles jamais chevauchantes** + **halos sans angle**.
> Ces deux contraintes sont **incompatibles** avec « espèce tirée à la frontière
> de plusieurs familles » (une espèce appartient à **une seule** famille). On
> tranche pour le **non-chevauchement** → modèle de **packing de bulles**.

On **remplace la spirale de Fermat** par un placement **piloté par la famille** :
chaque famille est un **cercle** (rayon ∝ nombre d'espèces), les cercles sont
**packés sans chevauchement**, et les espèces sont disposées **à l'intérieur**.

- **Algorithme** (`LayoutReseauFamilles`, `presentation/widgets/reseau/`) :
  1. **placement interne** : les espèces d'une famille en **spirale phyllotaxique**
     (angle d'or) — distribution régulière et naturelle dans un disque ;
  2. **rayon** de chaque famille = rayon du nuage interne + marge (plancher pour
     les familles à 1 espèce) ;
  3. **packing** des cercles : init déterministe sur une spirale, puis relaxation
     par **séparation de collisions + gravité** (compacité), suivie d'une passe
     **séparation-seule** qui **garantit l'invariant : aucun chevauchement**.
  Les **arêtes d'association** sont acceptées par l'API mais **n'influencent pas**
  le placement (garder les familles disjointes prime sur rapprocher les espèces
  liées) ; elles restent de simples traits, leur polarité étant donnée par la
  couleur.

- **Déterminisme (verrouillé)** : familles ordonnées par nom, placement interne
  et packing **sans aucun aléa**, itérations figées → **rendu identique à chaque
  lancement**. La mémoire spatiale de l'utilisateur est préservée.

- **Solve statique « one-shot »** : calculé **une fois à l'init** puis **figé**
  (pas de simulation vivante : pas de jiggle, pas de coût continu). Coût mesuré
  sur le catalogue réel (34 espèces / 12 familles) : **négligeable** ; le packing
  est en O(familles²) par itération (quelques dizaines de familles).

- **Adaptation à l'ajout de fiches** : catalogue **embarqué au build** → le
  layout est **recalculé au démarrage** sur les fiches présentes (nouvelles
  espèces intégrées dans leur famille, **bulles redimensionnées automatiquement**,
  packing rééquilibré), **déterministe**. Tout changement n'arrive **qu'entre
  versions**, jamais en session.

- **Option différée — précalcul au build** : si le nombre d'espèces le justifiait,
  précalculer les positions par un script et les livrer en **asset** (0 coût
  runtime). Non retenu **maintenant** (coût d'init négligeable à cette échelle).

**Rejeté — secteurs angulaires** (chaque famille = un quartier du disque) : net,
mais quartiers **jointifs** (pas de respiration entre familles) et **à angles**.
**Rejeté — force-directed** (prototype, cf. encadré) : familles chevauchantes.

**Faisabilité — note honnête** : placer chaque espèce dans le cercle de sa
famille est **toujours possible** (l'appartenance est une partition). Arranger les
familles pour que **toutes** celles qui s'associent soient adjacentes (arêtes
courtes, sans croisement) est en général **impossible** — problème de
**planarité** ; le compagnonnage, empirique, n'a aucune raison d'être planaire.
Les arêtes inter-bulles **se croisent** donc, et c'est **assumé** : c'était déjà
le cas avec la spirale, et la **sélection met les liens en avant** en atténuant
le reste.

---

## Décision 3 — **Deux modes** : Overview (familles) + Focus (ego-réseau)

Plutôt qu'un graphe unique « qui fait tout » (illisible à grande échelle), la vue
Réseau (BOX 1) porte **deux modes** ; BOX 2 (feuille panneau + variétés) est
inchangée.

### Mode **Overview** — exploration par familles (par défaut)
- La constellation force-directed (Décision 2), avec **halos de famille**
  (Décision 4). Rôle = **ambiance + point d'entrée**, on n'y prétend pas lire
  chaque relation.
- Toute la machinerie d'ADR-0007 reste valable **par-dessus** : `_TransformReseau`
  (zoom/pan), recadrage animé, anti-chevauchement des **libellés** (#8b).
- **Rendu au canvas** des nœuds (`CustomPaint` : disques + initiales), avec
  hit-testing dans le peintre — pour tenir la charge de quelques centaines de
  nœuds sans empiler autant de widgets `Positioned`/`GestureDetector`.
- **Recherche manuelle par nom** : un **champ de recherche** overlay
  (`_BarreRecherche`) retrouve une espèce par son nom. La correspondance
  **sélectionne** le nœud et **recadre** dessus (réutilise le comportement de
  clic). Insensible à la casse/aux accents.

### Focus & détail — **deux vues distinctes** (révisé en revue dev)
> **Révision (revue dev).** Itérations successives. Aboutissement : **deux vues
> nommées différemment**, pour éviter la confusion.

**1. « Réseau » — focus dans la constellation (vue générale).** Cliquer une
plante la **met en focus dans la constellation** : ses compagnons liés d'une
**même famille** se **fusionnent en un seul nœud** (`_GroupeFocusReseau`,
`_coucheFocus`) — **nom de famille au-dessus**, **disque** (compteur), **espèces
listées en dessous**, chaque nom **cliquable → re-focus** sur cette espèce. Les
nœuds non liés s'**atténuent et rétrécissent** ; les halos restent. Compact, pour
explorer « qui s'associe avec qui ».
> **Tweak #2 (revue dev).** La plante **sélectionnée fusionne dans le nœud de sa
> propre famille** : on groupe `{sel, …voisins}` (et non les seuls voisins). Si un
> lien partage sa famille (ex. Tomate + Pomme de terre → Solanaceae), tous deux
> apparaissent sous **un seul** nœud de famille (la sélection listée **en premier**,
> relation neutre ; les liens vert/rouge ; le compteur du disque = taille du
> groupe). Il n'y a **plus de disque « nœud sélectionné » distinct** ; on rouvre sa
> fiche en re-touchant son **nom** dans la liste.
> **Supersession assumée.** Ce regroupement **remplace l'anti-chevauchement #8b
> d'ADR-0007 en focus** (les libellés individuels espacés) : les bulles de famille
> étant déjà disjointes, un nœud groupé par famille gère la séparation. #8b reste
> en code mais **n'est plus appliqué au rendu en focus** (positions canoniques).

**2. « Associations » — vue détail d'une espèce (granulaire).** L'ancien dialogue
plein écran (`vue_associations.dart`, `afficherVueAssociations`), **dégroupé** :
**une espèce = un nœud**, bons à gauche / à-éviter à droite, légendes, `InteractiveViewer`,
un compagnon tapé ouvre sa fiche. **Accessible depuis la vue « Fiches »** (un
bouton ⬡ par carte d'espèce) : on scrolle les fiches et, d'un clic, on a le détail
des associations d'une plante. **Emplacement raison réservé** par nœud (vide tant
que la donnée n'existe pas, cf. Décision 5) — c'est cette vue qui portera **le
pourquoi** des associations. État vide géré.

### Affinements Overview (revue dev)
- **Bulles scalées au zoom** (déroge à la *taille pixel constante* d'ADR-0007) :
  le disque d'un nœud = rayon virtuel × échelle, **borné** entre un plancher et la
  taille actuelle (`_rayonEcran`). Dézoomé → bulles petites (tout tient à
  l'écran) ; zoomé → bulles pleines (initiale ré-affichée au-delà d'un seuil).
  Les **libellés** gardent une taille écran constante.
- **Noms au zoom** : en vue globale, un nœud affiche son **nom complet** dès qu'il
  **tient sans chevaucher** un autre disque ou un autre libellé (passe gloutonne
  `_labelsQuiTiennent`). Plus on zoome, plus il y a de noms.
- **Focus (sélection) plus lisible** : les nœuds **non liés** sont **plus
  atténués** (opacité 0.15) **et réduits de moitié** (les **halos gardent leur
  taille**) ; seules les **familles du focus** gardent leur label, les autres ne
  montrent que le halo.
- **Labels de famille** dans une **pastille au-dessus du halo** (ne collisionnent
  plus avec les bulles internes).
- **Couleur de relation sur les labels** : en focus, le **fond du nom** d'un nœud
  lié est **vert** (bon compagnon) ou **rouge** (à éviter) — tons *container* M3
  pour rester lisible (tweak #1).
- **Recherche repliée** en **bouton loupe** ; l'ouvrir déplie le champ ; **l'effacer
  (croix)** referme + revient à la vue globale (désélection + recentrage) ;
  **taper en dehors** d'un champ **vide** le replie (sans désélectionner).
- **Contrôles d'affichage repliés** (`_ControlesZoom`, bouton ⚙) sur le même
  modèle : ouvrir → zoom +/−/recentrer **+ 2 bascules** : **afficher les liens**
  et **afficher les noms de famille** ; **taper en dehors** referme (`TapRegion`).
- **Hitbox agrandie « au plus proche » (tweak #3)** : un `onTapUp` sur le canvas
  sélectionne le **nœud le plus proche** du point touché tant qu'il est à
  ≤ `_hitboxMax` (28 px) — les disques rapetissés au dézoom restent faciles à
  taper, **sans changer le visuel**. L'affectation au plus proche borne donne des
  cellules (Voronoï) **non chevauchantes et déformables par construction**. Les
  taps **précis** sur un disque (ou un nom groupé, un contrôle, la recherche) sont
  captés par le widget visé qui **gagne l'arène de gestes** → le canvas ne traite
  que les taps « autour ». Compromis assumé : tap + scale dans le même
  `GestureDetector` font que le **scale ne s'engage qu'après franchissement du
  slop de tap** (le tout premier segment d'un pan est absorbé) — comportement
  standard de Flutter (cf. `InteractiveViewer` + tap), négligeable à l'usage. Le
  fallback `Listener` prévu n'a **pas** été nécessaire.
- **Compteur de variétés retiré (tweak #1)** : la vue **Fiches**
  (`_CarteFiche`, `ecran_catalogue.dart`) ne montre plus de compteur de variétés
  en trailing — **flèche seule** conservée.

---

## Décision 4 — **Halos de famille** « blobby » (cercle packé adouci)

Chaque famille est soulignée par une **bulle translucide colorée et labellisée**
(`presentation/widgets/reseau/halo_famille.dart`) :

- **Forme** : le **cercle packé** de la famille (Décision 2), rendu en contour
  **« blobby »** — légèrement irrégulier (3 harmoniques sinus, phase semée sur le
  nom → déterministe), **lissé aux quadratiques de Bézier** donc **sans angle**.
  L'ondulation est **vers l'intérieur uniquement** (rayon ≤ rayon packé) → deux
  familles voisines **ne se touchent jamais** (l'invariant de non-chevauchement
  est préservé). *Choix validé en revue dev* contre l'enveloppe convexe (à
  angles) et le cercle parfait (trop géométrique). **Label = nom de la famille**
  en haut de la bulle. Métaballs envisagées comme évolution (forme épousant les
  vrais membres) mais gain modeste tant que le placement interne est phyllotaxique
  → non retenu pour l'instant.
- **Dégénérescences** : famille à 1–2 espèces → petite bulle (rayon plancher),
  même rendu, jamais de forme vide.
- **Couleur** : les **nœuds restent colorés par catégorie** (`couleurCategorie`,
  inchangé) ; les **halos portent l'identité famille** (teinte déterministe
  dérivée du nom, remplissage faible alpha + label).
- Les halos sont **décoratifs et non interactifs** (peints **sous** les nœuds via
  `_PeintreFoyers`) ; ils ne capturent aucun geste.

---

## Décision 5 — **Raisons** des associations : hors périmètre (bloqué data)

Afficher **pourquoi** deux plantes s'associent (maladie partagée, fixation
d'azote, complémentarité lumière…) reste **bloqué** par la donnée : le contenu
éditorial famille (`_familles/*.yaml` : `associations_note`, `ennemis_communs_note`)
est **vide** et le référentiel maladies/ravageurs n'est **pas normalisé**
(cf. [ADR-0006](0006-fiches-famille-botanique.md) **Lot 4**, `docs/15` §4 et §8 #11).

Le **mode Focus réserve l'emplacement** (une ligne « raison » par arête) sans le
remplir. Aucune valeur inventée : tant que la donnée n'existe pas, l'emplacement
reste absent/neutre. Ce lot se débloquera **avec** ADR-0006 Lot 4, sans rejouer
le layout.

---

## Découpage en lots livrables

Comme ADR-0007 : **chaque lot laisse l'app verte** (`flutter analyze` + suite
complète) et est livrable seul. Tests écrits **en parallèle**.

| Lot | Décision | Contenu | Dépendance |
|---|---|---|---|
| **1** ✅ | D1 | **Résolveur d'associations unifié** (service `domain` pur, bidir + toutes espèces, précédence bon>éviter) ; `vue_reseau_catalogue` **et** `fiche_plante_detail` branchés dessus → compteurs alignés. + tests domaine. | — |
| **2** ✅ | D2 | **Layout par bulles de famille** (`LayoutReseauFamilles` : packing de cercles déterministe + spirale phyllotaxique interne) **remplaçant** la spirale de Fermat ; baseline recadrée sur l'union des bulles. + tests (déterminisme, non-chevauchement, confinement). | — |
| **3** | D4 | **Halos blobby ✅** (`halo_famille.dart`, `_PeintreFoyers`) **remontés ici** ; reste le **rendu canvas des nœuds** (perf, hit-testing peintre) — **différé** (widgets `Positioned` OK à quelques dizaines d'espèces). | Lot 2 |
| **4** ✅ | D3 | **Deux vues** : **« Réseau »** — focus dans la constellation, **regroupement des liens par famille** (`_coucheFocus`/`_GroupeFocusReseau`, noms cliquables → re-focus ; supersède #8b en focus) ; **« Associations »** — vue détail dégroupée (`vue_associations.dart`, une espèce = un nœud), **ouverte depuis la vue Fiches** (bouton ⬡ par carte), emplacement raison réservé. | Lot 1, 2 |
| **5** ✅ | D3 | **Recherche manuelle par nom** (`_BarreRecherche` overlay → sélection + recadrage du nœud trouvé, normalisation casse/accents, message « aucun résultat »). Branchée sur la sélection actuelle ; bénéficiera du Focus quand il atterrira. | Lot 2 |
| **Bloqué** | D5 | **Raisons** par association dans le Focus. | ADR-0006 Lot 4 + référentiel maladies/ravageurs |

> Ordre recommandé : **1** (petit, indépendant, corrige un écart visible) → **2**
> (cœur du layout) → **3** (halos + rendu canvas) → **4** (focus). Possibilité de
> **prototype jetable** du seul Lot 2 (calcul de positions) pour juger rendu/perf
> avant de brancher le reste.

---

## Conséquences

- **Positif** : la vue Réseau devient **lisible à l'échelle visée** (familles en
  Overview, relations en Focus) et **scalable** (rendu canvas, solve déterministe
  borné, porte ouverte au précalcul build) ; les **compteurs/listes de compagnons
  coïncident** partout (un seul résolveur) ; l'effet « espèce à la frontière de
  familles » émerge naturellement ; l'infra ADR-0007 (transform, anti-chevauchement)
  est **réutilisée**, pas jetée ; la séparation Overview/Focus **déverrouille
  proprement** les raisons (Lot bloqué) sans refonte ultérieure.
- **Négatif / coût** : on réimplémente un mini-moteur de forces (réglage des
  constantes à itérer) ; deux modes = plus de surface UI/tests ; la fiche
  détaillée **change de contenu** (compagnons plus nombreux) ; choix visuel
  « couleur nœud (catégorie) vs halo (famille) » à valider sur prototype.
- **Dépendances** : aucune dépendance externe nouvelle (forces, enveloppe convexe
  et rendu sont faits main au-dessus de Flutter — conforme à la stack validée).
  Le **Lot Raisons** reste subordonné à ADR-0006 Lot 4.
- **Supersession** : remplace le seul **placement** (spirale de Fermat → bulles
  de famille) d'ADR-0007. **Conserve tout le reste** : modèle de transformation,
  zoom/pan, **recadrage in-situ + anti-chevauchement #8a/#8b** au clic (le Focus
  est **additif**, pas un remplacement), découpage BOX 1 / BOX 2.
