# ADR-0019 — Report de la fonctionnalité « Post-récolte » de V1 vers V1.1

- **Statut** : **Accepté** — la fonctionnalité **sort du périmètre V1** et est
  reportée en **V1.1**. Aucune ligne de code à écrire pour cette décision ; le
  présent document acte le report et aligne le suivi.
- **Date** : 2026-07-17

---

## Contexte

La roadmap (docs/13 §1 « V1 — scope validé ») listait, sur **une seule ligne** :
« Post-récolte (conservation, recettes) ». C'était la **seule** trace de spec :
aucun détail fonctionnel dans [docs/02](../02-fonctionnalites-v1.md), aucun
modèle de domaine, aucun ADR de cadrage.

Côté code, la fonctionnalité est **quasiment inexistante** :

- deux clés i18n **orphelines** subsistent — `plusPostRecolte` /
  `plusPostRecolteSub` (« Conservation & transformation »), traduites fr **et**
  en ;
- ces clés **ne sont plus affichées** : l'entrée a été retirée du menu Plus, et
  `ecran_plus.dart` la classe déjà « upcoming/V2 » dans sa docstring ;
- **aucune** entité domaine, **aucun** écran, **aucune** donnée, **aucun**
  modèle de conservation ou de recette.

Il y avait donc une **incohérence de suivi** : docs/13 §1 la donnait « V1 »
alors que le code et le commentaire d'`ecran_plus.dart` la traitaient déjà comme
reportée. Au moment où **tout le reste de la V1 est livré**, c'est le **dernier
trou de périmètre** — et un **greenfield complet**, potentiellement lourd
(méthodes de conservation par plante, éventuellement recettes → nouveau modèle
de données + source YAML + UI dédiée).

## Décision

**Post-récolte est reportée en V1.1.** Cette décision tranche l'incohérence en
faveur de ce que le code reflète déjà, et **ferme le périmètre V1** sans laisser
de dette silencieuse.

Raisons :

1. **Absence totale de spec.** Une parenthèse « conservation, recettes » ne
   suffit pas à cadrer un chantier ; il faudrait d'abord un ADR de modèle
   (entités, source de données, périmètre), soit le travail d'une feature à part
   entière.
2. **Périmètre douteux.** « Recettes » relève davantage de l'accompagnement
   culinaire que de la gestion de potager (la philosophie du produit, docs/01) ;
   à instruire séparément plutôt qu'à embarquer par défaut.
3. **Coût/valeur au stade actuel.** Tout le reste de la V1 étant livré, ouvrir
   ici un greenfield conséquent retarderait la **pré-release** sans bénéfice
   proportionné. La V1.1 est le bon réceptacle (aux côtés des photos, de
   `Traitement`, de la sensibilité météo par plante).

### Sort des clés i18n orphelines

Les clés `plusPostRecolte` / `plusPostRecolteSub` sont **conservées** telles
quelles : elles décrivent l'entrée de menu qui sera rebranchée en V1.1, sont
déjà traduites dans les deux langues, et les retirer pour les réintroduire plus
tard serait du churn inutile. Elles sont donc **réservées V1.1**, non un oubli.

## Alternatives écartées

- **A — Planifier en V1.** Aurait imposé un ADR de cadrage puis un chantier
  greenfield conséquent avant la pré-release, sans spec préalable ni demande
  forte. Écartée : mauvais rapport coût/valeur à ce stade.
- **B — Laisser l'incohérence.** Garder docs/13 §1 « V1 » sans rien livrer
  aurait maintenu une entrée de suivi **fausse** (interdit par la discipline de
  suivi du projet). Écartée.

## Conséquences

- **Positives** : périmètre V1 **fermé et cohérent** (code = docs = suivi) ;
  voie dégagée vers la pré-release ; la fonctionnalité reste **explicitement
  tracée** pour V1.1, pas oubliée.
- **Négatives / neutres** : la V1 ne propose pas d'accompagnement post-récolte
  (impact faible — jamais livré ni promis dans l'app). Un futur ADR de cadrage
  V1.1 restera nécessaire avant toute implémentation.

## Renvois

- [docs/13 §1](../13-roadmap-et-versioning.md) — scope V1 (ligne post-récolte
  retirée) ; [docs/13 §2](../13-roadmap-et-versioning.md) — V1.1 (post-récolte
  ajoutée).
- `lib/presentation/screens/ecran_plus.dart` — docstring alignée sur ce report ;
  clés ARB `plusPostRecolte(Sub)` réservées V1.1.
- [RESTE_A_FAIRE.md](../../RESTE_A_FAIRE.md) — item d'arbitrage clos.
