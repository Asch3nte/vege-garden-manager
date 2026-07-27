# ADR-0019 — Regroupement des tâches par geste (agrégation d'affichage, notification unique par jour)

- **Statut** : **Accepté** — livré (2026-07-27)
- **Date** : 2026-07-27
- **Contexte immédiat** : la décision a été prise en séance après la correction
  d'un bug de duplication de tâches (§ « Ce qui a déclenché la décision »). Le
  dev avait le souvenir d'un travail antérieur sur « une seule tâche d'arrosage
  par jour » — **aucune trace** n'existait en code, en doc ni dans l'historique
  git ; au contraire, docs/15 actait « tâche urgente + notification **par
  plantation** » et [ADR-0015](0015-arrosage-intelligent-canicule.md) est
  titré « moteur + UI **par plantation** ». Cet ADR existe d'abord pour que
  l'arbitrage ne se reperde pas une seconde fois.

---

## Contexte

### Le modèle en place

`Tache` est une entité à **cible unique** (`CibleTache` + `cibleId` : potager,
parcelle, plantation ou équipement). `GenererTachesArrosage` matérialise en
conséquence **une tâche par plantation** ayant soif — c'est cette tâche qui
porte la cible, la priorité, la date de réalisation et l'historique, et c'est
elle que l'utilisateur coche quand *cette* culture est arrosée.

### Les deux symptômes observés

1. **Le mur de tâches.** Un jour où cinq cultures ont soif produit cinq lignes
   « Arroser » quasi identiques dans l'agenda et sur le tableau de bord. La
   lecture est mauvaise : l'information utile (« il faut arroser aujourd'hui »)
   est noyée dans la répétition.
2. **Le mur de notifications.** Pire, `_programmerNotification` était appelée
   **par plantation**, avec un id `arrosage_<plantationId>_<date>` : cinq
   cultures assoiffées = **cinq notifications** au même instant, toutes portant
   le même texte « Une de vos cultures a besoin d'eau aujourd'hui ». C'est le
   symptôme le plus pénalisant en usage réel.

### Ce qui a déclenché la décision

La session portait initialement sur un bug distinct : **cocher une tâche en
recréait une identique**. Cause racine trouvée : les mappers écrivaient les
dates en UTC ISO-8601 mais les relisaient sans repasser en local, donc
`_memeJour` comparait un jour UTC à un jour local et ne reconnaissait jamais la
tâche existante (corrigé par `DateIso`, docs/15 §8 #1bis). Ce bug **gonflait**
le nombre de tâches d'arrosage, ce qui a mis le sujet du regroupement sur la
table — mais la multiplicité de base, elle, était **conforme au modèle** et
n'était pas un bug.

### La question à trancher

Le regroupement est-il une propriété du **domaine** (une tâche composite existe
en tant qu'objet) ou de la **présentation** (N tâches réelles, une ligne) ?

---

## Décision — agrégation à l'affichage, le domaine ne bouge pas

`Tache` reste **une par cible**. Un value object d'application,
`GesteGroupe` (`lib/application/state/geste_groupe.dart`), agrège les tâches par
`(jour local, TypeTache)` et devient l'unité que les écrans rendent.

**Justification.** L'unité de travail réelle *est* « arroser les tomates » :
c'est elle qui porte la cible, la priorité, la route de notification et
l'historique de réalisation. Le regroupement, lui, n'est qu'une manière de
**lire** cette liste. Faire remonter une notion de groupe dans le domaine
reviendrait à modéliser une contrainte d'affichage — et à payer une migration
de schéma pour un objet qui, dans le périmètre demandé, ne porte **aucune
donnée propre** (ni note, ni durée réelle, ni identité que l'utilisateur
nommerait).

### Ce que `GesteGroupe` expose

| Membre | Rôle |
|---|---|
| `type`, `jour` | La clé de regroupement (jour = minuit **local**). |
| `taches` | Les tâches groupées, non faites d'abord puis par heure (immuable). |
| `estSeule` / `tacheUnique` | Un groupe de 1 se rend comme une ligne ordinaire. `tacheUnique` lève un `StateError` sur un groupe multiple (pas de silence). |
| `nombre`, `nombreFaites`, `tachesAFaire` | Les agrégats de progression. |
| `toutesFaites`, `aucuneFaite`, `partiellementFaite` | L'état tri-state de la case du groupe. |
| `priorite` | Le **maximum** des sous-tâches : une culture urgente garde la ligne urgente. |
| `premierInstant` | La position du groupe dans la journée. |
| `grouper(taches)` | La fabrique, seule voie de construction. |

**Ordre stable et volontaire** : groupes avec du travail restant d'abord, puis
premier instant, puis ordre de déclaration de `TypeTache` en départage — pour
qu'une couleur/un geste ne saute pas d'une place à l'autre entre deux
rafraîchissements.

### Une seule règle, deux surfaces

`GesteGroupe.grouper` est consommé par **`CalendrierVue.GroupeJour.gestes`**
*et* **`AccueilVue.gestesDuJour`**. C'est délibéré : les deux écrans montrent
les mêmes tâches, une divergence de regroupement serait un bug invisible et
durable. Les listes brutes (`taches`, `tachesDuJour`) restent exposées — les
compteurs (« N tâches à faire ») comptent toujours des **tâches réelles**, pas
des groupes.

### Règle de bascule — un groupe partiellement fait se complète

C'est l'arbitrage le moins évident, et il ne figurait pas dans la demande
initiale.

- Groupe **partiellement fait** → l'action « tout cocher » **complète** les
  tâches restantes. Elle ne bascule pas.
- Groupe **entièrement fait** → l'action **rouvre** tout (donc réversible).

**Pourquoi** : taper « fait » sur une ligne à moitié cochée doit être une
progression, jamais une annulation. Si l'action était une bascule symétrique,
l'utilisateur qui a coché les tomates puis tape le groupe **défairait** son
propre travail. Les deux notifiers appliquent la même règle
(`CalendrierNotifier.cocherGroupe`, `AccueilNotifier.basculerGeste`).

### Interaction — le tap ne coche pas

Sur une carte de groupe, **taper le résumé déplie/replie** ; cocher tout le
groupe passe par un **bouton dédié** (case tri-state). Un tap mal placé ne doit
pas terminer cinq cultures d'un coup. Les sous-lignes, elles, restent cochables
au tap — leur portée est d'une seule tâche, donc sans danger.

### Notifications — une par jour, comptant ce qui **reste**

`GenererTachesArrosage` programme désormais **une** notification par jour, id
`arrosage_<yyyy-MM-dd>`, dont le corps porte le nombre de cultures concernées.

Deux raffinements sont apparus en écrivant les tests, et ne figuraient pas non
plus dans la demande :

- Une culture **déjà cochée** n'est pas comptée. Arroser et cocher à 7 h ne doit
  pas produire un ping à 8 h. Le compte reflète ce qu'il **reste** à faire, pas
  ce que la météo a diagnostiqué.
- Un jour qui n'a plus besoin d'arrosage **annule** sa notification
  (`AbstractNotificationService.annuler`), au lieu de laisser une notification
  périmée programmée.

L'id étant scopé au jour, relancer le générateur **réécrit** la notification
avec un compte à jour au lieu d'en empiler une nouvelle.

### Effet de bord aligné — pastilles du calendrier

Corrigé dans la même session et cohérent avec la décision :
`GroupeJour.typesPresents` expose les types **distincts** du jour, et la grille
mensuelle dessine **un point par type**, plus un par tâche. Le plafond « 3 points
+ N » compte désormais des types.

---

## Options écartées

### A. Tâche composite en domaine (`tacheParenteId` ou entité `GroupeTache`)

Une entité parente porterait les enfants. Coût : migration de schéma drift,
mapper, repository, **cascade de suppression**, export/import JSON, et
réécriture du dédoublonnage de `GenererTachesArrosage` (dont la logique venait
d'être stabilisée). Gain réel : la possibilité qu'un groupe porte ses propres
données.

**Écartée** parce que ce gain est nul dans le périmètre demandé — aucune note,
durée ni identité de groupe n'a été souhaitée — et parce que le coût est
irréversible (une migration ne se déjoue pas). À reconsidérer **si et seulement
si** un besoin de donnée au niveau du groupe apparaît.

### B. Multi-cible sur `Tache` (une tâche, plusieurs `cibleId`)

Déjà identifié comme hors-modèle dans docs/15 §5 (« le multi-cible dépasse le
modèle actuel »). Casserait la résolution de nom de cible, le conseil d'arrosage
par plantation (ADR-0015) et la notion d'historique par culture. Écartée.

### C. Regrouper aussi la **génération** (une tâche « Arroser » ciblant le potager)

Séduisant en apparence, mais on perdrait *quelle* culture arroser, l'affichage
du nom de la cible, et la capacité de cocher culture par culture — c'est-à-dire
exactement ce que la demande voulait conserver. Écartée.

---

## Conséquences

### Positives

- Une journée à cinq arrosages se lit sur **une ligne**, sans rien perdre : le
  détail est à un tap, et chaque culture reste cochable séparément.
- **Une** notification par jour au lieu de N, et un compte qui reflète le
  travail restant — le gain d'usage le plus net du lot.
- **Zéro migration**, zéro risque sur les données existantes ; la décision est
  réversible par simple retrait d'une couche de présentation.
- Accueil et Calendrier partagent la même règle : ils ne peuvent plus diverger.
- Un groupe de 1 rend l'affichage d'avant à l'identique — aucune régression
  visuelle sur les cas non répétitifs.

### Négatives / vigilances

- **Le titre personnalisé d'une tâche disparaît du résumé.** L'en-tête d'un
  groupe affiche le libellé du *type* (`l10n.typeTache`) ; une tâche manuelle
  « Arroser en profondeur » ne montre son titre qu'une fois le groupe déplié.
  Accepté : le titre reste visible sur la sous-ligne. À revoir si l'usage montre
  que des titres personnalisés se perdent trop souvent.
- **L'état déplié/replié n'est pas persistant.** Il vit dans le `State` du
  widget, avec une `ValueKey` sur `(jour, type)` pour survivre aux rechargements
  déclenchés par un cochage. Il repart replié à chaque entrée dans l'écran.
- **Cocher un groupe fait N écritures** séquentielles (une par tâche). Le volume
  est petit (quelques cultures) ; si un potager très fourni le rendait sensible,
  il faudrait une écriture par lot au niveau du repository.
- Le regroupement se fait sur `(jour local, type)` : il **dépend donc du
  round-trip correct des dates**. C'est précisément ce que `DateIso` garantit
  désormais, et ce que teste `generer_taches_arrosage_persistance_test.dart`.

---

## Tests (écrits en parallèle)

| Fichier | Couverture |
|---|---|
| `test/unit/application/geste_groupe_test.dart` | Clés de regroupement (type/jour), agrégats de progression, priorité = max, ordres (intra-groupe et inter-groupes), `tacheUnique` refusant un groupe multiple, immuabilité des listes. |
| `test/unit/application/calendrier_notifier_test.dart` | `gestes` par jour ; les 3 règles de bascule (complet, partiel → complète sans défaire, tout fait → rouvre). |
| `test/unit/application/accueil_notifier_test.dart` | `gestesDuJour` ; mêmes 3 règles ; le compteur continue de compter des tâches. |
| `test/widget/ecran_calendrier_test.dart` | Repli/dépli, sous-lignes ciblées, « tout cocher », cochage d'une sous-tâche isolée, vue Mois groupée à l'identique. |
| `test/widget/ecran_accueil_test.dart` | Mêmes parcours sur le tableau de bord. |
| `test/unit/application/generer_taches_arrosage_test.dart` | Notification unique comptée, culture déjà cochée exclue, annulation quand plus rien à arroser, non-empilement sur runs répétés. |

---

## Références

- [ADR-0015](0015-arrosage-intelligent-canicule.md) — conseil et tâches
  d'arrosage **par plantation** (modèle que cet ADR conserve, en changeant
  seulement sa restitution).
- [docs/15 §5](../15-elements-differes.md) — registre de l'écran Calendrier
  (entrées « Regroupement des tâches par geste » et « Pastilles du mois »).
- [docs/15 §8 #1bis](../15-elements-differes.md) — le bug de round-trip des
  dates corrigé dans la même session (`DateIso`).
