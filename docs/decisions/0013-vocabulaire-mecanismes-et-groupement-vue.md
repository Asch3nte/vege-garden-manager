# ADR-0013 — Extension du vocabulaire de mécanismes, marqueur « autre », groupement de la vue & raison de confiance

- **Statut** : Accepté — lots 1–6 livrés
- **Date** : 2026-06-17

> ⚠️ **Révisions ultérieures** (traçabilité) :
> - **[ADR-0014](0014-calcul-associations-exhaustif-explicable.md)** (2026-06-18) **supprime** les phrases de confiance génériques (`confianceExpl*`, Décision 5) au profit d'une **explication exhaustive par critère** ; **rend dérivables** les mécanismes ajoutés ici (`competitionEau/Espace`, `partageMaladies`, `ameublissementSol`, `attractionAuxiliaires`) ; le marqueur « Autre » (Décision 3) subsiste pour les paires curatées non typées.

- **Contexte** : à l'usage réel de la vue Associations (cf. capture « Courge
  musquée »), trois irritants subsistent après [ADR-0012](0012-associations-directionnelles-refonte-vue.md) :

  1. **Libellés répétés.** Plusieurs plantes partageant le **même mécanisme et le
     même sens** (ex. *Attire les pollinisateurs* → thym, framboisier, fraisier)
     affichent chacune la même puce + la même flèche → bruit visuel.
  2. **Nœuds orphelins.** Une paire curatée **non typée** (ex. *Pomme de terre* :
     « Concurrence pour l'espace et l'eau », sans `type:`) n'affiche **ni puce ni
     rien** sous son nom — l'utilisateur ne comprend pas la relation depuis la vue.
  3. **Confiance non expliquée.** Le bandeau de fiche montre « Suggéré · élevée »
     mais **pas pourquoi** l'inférence est élevée / moyenne / faible.

  Un audit du corpus (114 paires curatées) révèle la cause profonde du point 2 :
  **34 paires restent non typées**, non par oubli mais parce que le vocabulaire
  d'[ADR-0010](0010-associations-multi-mecanismes.md) (14 mécanismes) **ne couvre
  pas** certains mécanismes pourtant clairs et récurrents. Sur ces 34 :

  | Catégorie | ~Nb | Cause |
  |---|---|---|
  | **Mécanisme réel mais absent du vocabulaire** | ~16 | manque d'enum (voir Décision 1) |
  | **Réellement générique** (« association favorable documentée », « mêmes besoins en eau », « trio classique ») | ~10 | la raison **n'énonce aucun mécanisme** → typer = inventer une donnée (interdit, ADR-0012 Lot 6) |
  | Doublons / sans raison | reste | bruit de contenu à nettoyer |

  Décision actée avec le dev : **étendre le vocabulaire** aux manques réels, et
  **assumer** le résidu générique via un marqueur **« autre »** de présentation
  (jamais un faux mécanisme), tout en **groupant** la vue et en **expliquant** la
  confiance.

---

## Décision 1 — Quatre mécanismes manquants ajoutés au vocabulaire

L'audit fait remonter **4 mécanismes réels** non modélisés. On les ajoute aux
enums d'[ADR-0010](0010-associations-multi-mecanismes.md), avec libellés i18n,
gestion par le validateur/mapper YAML, et — pour les bénéfices — un rattachement
à une **famille d'effet** ([ADR-0011](0011-scoring-ponderation-associations.md),
`familleDe`, exhaustif par construction) :

| Nouveau mécanisme | Type | Famille d'effet | Exemple de paire débloquée |
|---|---|---|---|
| `attractionAuxiliaires` (attire prédateurs/parasitoïdes — **≠** pollinisateurs) | bénéfice | `protectionRavageurs` | aneth : « Attire les insectes auxiliaires contre les chenilles » |
| `ameublissementSol` (racines qui décompactent pour les voisines) | bénéfice | `fertilite` (élargie : *fertilité **et structure** du sol*) | radis : « Ameublit le sol pour les carottes » |
| `partageMaladies` (hôte commun fongique/sol, **inter-familles**) | conflit | — | « Favorisent mutuellement le mildiou », « Verticillium avec les Solanacées » |
| `competitionEau` | conflit | — | « Concurrence hydrique si plantée trop près » |
| `competitionEspace` | conflit | — | pomme de terre : « Concurrence pour l'espace et l'eau » |

> Les **conflits ne portent pas de famille** : le scoreur ([ADR-0011](0011-scoring-ponderation-associations.md))
> ne pondère pas les conflits (ce sont des avertissements, ordonnés par confiance
> seule). Aucun ajout à `FamilleEffetAssociation` côté conflit.

`attractionAuxiliaires` et `partageMaladies` ne sont **pas dérivables** des traits
actuels → ils restent **curatés-only** (légitime : un mécanisme n'a pas à être
inféré par le moteur pour être un libellé valide). `ameublissementSol`,
`competitionEau/Espace` pourront recevoir une règle de dérivation plus tard (hors
périmètre).

## Décision 2 — Typer les ~16 paires correspondantes (contenu)

On type dans les fiches YAML les paires dont la `raison_i18n` exprime clairement
l'un des 4 nouveaux mécanismes (ou un mécanisme **existant** mal repéré au Lot 6,
ex. *couvre le sol*, *sous-couvert*). Gardé par `catalogue_reel_test`. **Aucune
réécriture de raison** : on ne fait que poser le `type:` là où la raison le dit
déjà. Débloque notamment **Pomme de terre** (point 2 du contexte).

## Décision 3 — Marqueur « autre » pour le résidu réellement générique

Les paires dont la raison **n'énonce aucun mécanisme** (« association favorable
documentée », « mêmes besoins en eau »…) **restent non typées dans le YAML** (pas
de fausse donnée). Mais elles **ne sont plus orphelines dans la vue** : une paire
curatée sans `type:` reçoit une **puce neutre « Autre »** (libellé i18n, couleur
atténuée, **pas** une couleur de famille), et **toute la raison éditoriale**
s'affiche dans le **bandeau de la fiche** ouverte depuis la vue (Décision 5).

> « Autre » est une **notion de présentation**, dérivée de l'absence de `type:` —
> **aucun** mécanisme `autre` n'est ajouté au domaine (pas de pollution du scoring
> ni des familles). Le savoir reste dans la raison, montré en entier sur la fiche.

## Décision 4 — Groupement de la vue par (mécanisme, sens, côté)

Dans la constellation, les plantes d'un **même côté** (bon / à-éviter) partageant
la **même clé** sont **groupées** :

```
clé = (mécanisme typé  | raison libre si « Autre »,  sens,  côté)
```

- Le **sens** fait partie de la clé → *Fixe l'azote · reçoit* (pois) et
  *Fixe l'azote · mutuel* (haricot) **ne sont pas** groupés (exemple du dev).
- Le groupe « Autre » se regroupe par **texte de raison** (à défaut de mécanisme),
  pour ne pas mélanger des relations sans rapport.
- **Rendu** : chaque plante **garde sa bulle tappable**, les membres d'un groupe
  sont posés **côte à côte** ; le **libellé (puce mécanisme/Autre + sens)
  s'affiche une seule fois** au-dessus du cluster (fin de la répétition).
- **Une seule flèche** relie le centre à **l'ancrage du groupe** (barycentre des
  bulles), tête orientée selon le **sens commun** (donne / reçoit / mutuel) —
  plus de flèche par bulle. Un groupe à **1 membre** garde une flèche solo.

Le layout anti-chevauchement d'[ADR-0012](0012-associations-directionnelles-refonte-vue.md)
(`LayoutVueAssociations`) est adapté pour placer des **groupes** (ancres) au lieu
de nœuds isolés, puis répartir les membres autour de chaque ancre sans
chevauchement.

## Décision 5 — Raison de confiance & détails dans la fiche (depuis la vue)

Le bandeau de fiche ([ADR-0012](0012-associations-directionnelles-refonte-vue.md)
`_BandeauAssociation`), affiché **uniquement** quand la fiche est ouverte depuis
la vue Associations (fiche « modifiée »), est enrichi :

- pour une suggestion **dérivée**, la ligne « Suggéré · *niveau* » est complétée
  d'une **phrase expliquant le niveau** (i18n, dérivée du **mécanisme + niveau**),
  ex. *« Élevée : fixateur d'azote × plante gourmande »*, *« Moyenne : inférence
  plausible sur 1–2 traits »*, *« Faible : signal générique »* ;
- pour une paire **« Autre »**, le bandeau montre **tous les détails** de la
  relation (raison complète, sens), puisque la vue n'en montre que le marqueur.

Aucune phrase n'est inventée : l'explication mappe le **couple (mécanisme,
niveau)** déjà décidé par le moteur ([ADR-0010](0010-associations-multi-mecanismes.md)).

## Décision 6 — Précédence du conflit : **une seule appartenance par paire**

Une paire peut porter à la fois un signal **bénéfique** et un signal **conflit**
(ex. pomme de terre × artichaut : étagement *et* concurrence azote ; pomme de
terre × tomate : même famille). À l'affichage, une plante ne doit apparaître que
d'**un seul côté**. Règle retenue (sûreté d'abord) : **le conflit l'emporte** —
si une espèce se retrouve dans les deux ensembles, elle est **retirée des bons**
et ne reste qu'en « à éviter ».

> Choix pragmatique aligné sur l'attente utilisateur (pomme de terre + tomate =
> *uniquement* à éviter) et sur la sécurité (un avertissement ne doit pas être
> noyé). *Alternative écartée* : un score net bon−mauvais — mal défini, les
> bénéfices (pondérés par famille × confiance) et les conflits (avertissements,
> confiance seule) n'étant pas sur la même échelle ([ADR-0011](0011-scoring-ponderation-associations.md)).

## Décision 7 — Banderole d'état des préférences

La vue affiche, **au-dessus** du filtre Tout/Donne/Reçoit/Mutuel, une banderole
indiquant l'état du **profil de pondération** ([ADR-0011](0011-scoring-ponderation-associations.md)) :
« normales (par défaut) » ou la liste des familles ajustées. Objectif : que le
split bon/à-éviter ne **surprenne** pas quand un profil non-défaut le biaise.

---

## Découpage en lots livrables

Chaque lot laisse l'app verte (`flutter analyze` + suite). Tests en parallèle.

| Lot | Périmètre | Dépendance |
|---|---|---|
| **1 — Vocabulaire** | +`attractionAuxiliaires`,`ameublissementSol` (bénéfice) ; +`partageMaladies`,`competitionEau`,`competitionEspace` (conflit) ; `familleDe` étendu ; libellés i18n `mecanismeBenefice/Conflit` ; validateur/mapper YAML ; phrases de confiance i18n. Tests (mapping exhaustif, i18n, validateur). | ADR-0010/0011 |
| **2 — Contenu** | Typer les ~16 paires curatées correspondantes (YAML), Pomme de terre incluse ; nettoyage doublons/raisons vides repérés à l'audit ; `catalogue_reel_test`. | Lot 1 |
| **3 — Fiche enrichie** | Phrase de confiance (Décision 5) + détails complets pour « Autre » dans `_BandeauAssociation` ; puce « Autre » (Décision 3) pour les non typées. Tests widget. | Lot 1 |
| **4 — Groupement de la vue** | View-model groupé par (mécanisme/raison, sens, côté) ; libellé partagé une fois ; `LayoutVueAssociations` adapté (ancres de groupe + membres) ; `_Peintre` **flèche unique** par groupe ; filtre par sens conservé. Tests layout + filtre. | Lots 1–3 |
| **5 — Finitions de la vue** (usage réel) | (1) **auto-fit** : canvas dimensionné à la boîte englobante du contenu + `InteractiveViewer(constrained:false)` recentré à l'échelle « tout visible » à chaque changement de jeu affiché ; (2) **légendes retirées** (« N bons compagnons / à éviter ») ; (3) **clic réparé** — le canvas couvrant tout le contenu, les bulles redeviennent **hit-testables** (un enfant peint hors des bornes du parent via `Clip.none` n'est pas cliquable) ; (4) **libellés non tronqués** (cluster ≥ 144 px, label sur ≤ 3 lignes sans `…`) ; (5) **forme arrondie** tamisée (couleur du côté, alpha 0.06) derrière chaque cluster, **flèche pointant sur le bord du rectangle** (intersection rayon×rect) → plus de collision tête/bulle ; (6) **« Suggéré » → « Suggestion »** ; (7) ligne **« Hors suggestion »** sur les clusters curatés (pendant de « Suggestion · … »), élaborée dans le bandeau de fiche. Tests (clic, Hors suggestion, Autre). | Lot 4 |
| **6 — Précédence conflit + banderole** (usage réel) | (Décision 6) dedup **conflit > bénéfice** dans `afficherVueAssociations` (`bons.removeWhere(id ∈ aEviter)`) → une plante d'un seul côté ; (Décision 7) `_BasAppBar` = `_BandeauPreferences` (état du profil) au-dessus du filtre ; **fix overflow** des clusters (hauteur du `Positioned` libérée, estimations de boîte élargies). Tests (précédence, banderole défaut/perso). | Lots 4–5 |

---

## Conséquences

### Positives
- **Couverture honnête** : ~16 paires de plus typées → entrent dans le
  groupement, le scoring et les familles ; le résidu reste vrai (« Autre » + détail).
- **Lisibilité** : un libellé + une flèche par groupe au lieu de N répétitions.
- **Transparence** : l'utilisateur comprend *pourquoi* une suggestion est plus ou
  moins sûre, et ce que recouvre une relation « Autre ».
- **Pas de fausse donnée** : aucun mécanisme inventé ; « Autre » est purement
  présentationnel.

### Négatives / risques
- **Révise ADR-0010/0011** : nouveaux mécanismes + famille élargie → note de
  révision à porter sur les ADR antérieurs (traçabilité).
- Le groupement complexifie le layout (ancres + membres) — atténué en réutilisant
  l'algorithme anti-chevauchement existant.
- La clé de groupe par **raison libre** (« Autre ») est sensible aux variations de
  formulation ; acceptable (faible volume, regroupement « best-effort »).

---

## Liens
- [ADR-0010](0010-associations-multi-mecanismes.md) — taxonomie typée, dérivation (révisé : +5 mécanismes).
- [ADR-0011](0011-scoring-ponderation-associations.md) — familles d'effets, scoring (révisé : famille `fertilite` élargie, +`attractionAuxiliaires`).
- [ADR-0012](0012-associations-directionnelles-refonte-vue.md) — sens, familles-labels, bandeau fiche, anti-chevauchement (base de la vue groupée).
- Capture de référence : vue « Courge musquée » (libellés répétés, Pomme de terre orpheline).
- Code : `lib/presentation/widgets/vue_associations.dart`, `fiche_plante_detail.dart`, `reseau/layout_vue_associations.dart`, `domain/enums/type_*_association.dart`, `domain/enums/famille_effet_association.dart`.
