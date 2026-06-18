# ADR-0011 — Scoring & pondération des associations (profil personnalisable)

- **Statut** : Accepté — **Lots 1 à 4 livrés** (2026-06-16)
- **Date** : 2026-06-16

> ⚠️ **Révisions ultérieures** (traçabilité / rétropédalage) :
> - **[ADR-0012](0012-associations-directionnelles-refonte-vue.md)** (2026-06-16) **étend** le rôle des *familles d'effet* : en plus de servir d'unité de pondération (ici), elles deviennent le **libellé affiché** dans la vue Associations (à la place du mécanisme précis). Le tri par score, le top-N et le « voir plus » de cet ADR sont **conservés** ; s'y ajoutent le sens (donne/reçoit/mutuel) et un filtre par direction.
>   - *Pour revenir en arrière* : réafficher le mécanisme précis comme libellé dans `vue_associations.dart` (le modèle de scoring est inchangé).
> - **[ADR-0013](0013-vocabulaire-mecanismes-et-groupement-vue.md)** (2026-06-17) ajoute des mécanismes au vocabulaire et les rattache à `familleDe` : `attractionAuxiliaires` → **protectionRavageurs**, `ameublissementSol` → **fertilite** (dont la portée est **élargie** à *fertilité **et structure** du sol*). Les nouveaux conflits (`partageMaladies`, `competitionEau/Espace`) **ne portent pas de famille** (les conflits ne sont pondérés que par confiance — inchangé).
>   - *Pour revenir en arrière* : le scoring est inchangé ; retirer les nouveaux mécanismes de `familleDe` suffit.
> - **[ADR-0014](0014-calcul-associations-exhaustif-explicable.md)** (2026-06-18) **revient sur** *« les conflits ne sont pas pondérés »* : les conflits deviennent **pondérables** par **famille de conflit** (concurrence ressources / risque sanitaire / allélopathie), pour que tout mécanisme dérivable soit priorisable par l'utilisateur. `score(conflit) = poids(familleConflit) × facteur(confiance)` ; défaut `normal` → comportement inchangé.
>   - *Pour revenir en arrière* : fixer le poids conflit à `normal` (neutre) redonne le tri par confiance seule.
- **Contexte** : le moteur de dérivation d'[ADR-0010](0010-associations-multi-mecanismes.md)
  (Lot 3) dérive **volontairement large** — une même plante peut matcher de
  nombreux mécanismes, dans les deux sens, pour de nombreuses voisines. Résultat :
  la **vue Associations devient chaotique** (trop de nœuds, sans hiérarchie). Or :

  1. Toutes les associations ne se valent pas : un gain structurel fort (maïs +
     haricot) n'a pas le même intérêt qu'un effet diffus à faible confiance.
  2. **Ce n'est pas une science exacte** : l'efficacité dépend du terrain, du
     climat, des pratiques. Un jardinier peut constater que les effets répulsifs
     « ne marchent pas chez lui » et vouloir **prioriser le gain de place**.

  Il manque donc (a) un **score** pour trier/élaguer, et (b) une **pondération
  ajustable** par l'utilisateur expérimenté.

---

## Décision 1 — Score d'une association

Un score numérique ordonne et élague l'affichage (et pondère le bonus de reco) :

```
score(bénéfice) = poids(familleEffet(mécanisme)) × facteurConfiance(confiance)
```

- `facteurConfiance` : `eleve → 1.0`, `moyen → 0.7`, `faible → 0.4` (constantes
  du scoreur, calibrables).
- **Conflits** : pas concernés par les poids (ce sont des *avertissements*, pas
  des préférences) ; ils sont ordonnés par confiance et restent candidats à
  l'affichage.
- **Curaté** : une association curatée **fait autorité** ([ADR-0010] précédence)
  → **toujours affichée**, jamais élaguée. Le score ne sert qu'à ordonner/limiter
  les **suggestions dérivées**.

Le scoring vit dans un calculateur **pur** `ScoreurAssociations`
(`application/engine/`), qui prend le profil de poids **en paramètre**. Le
`MoteurDerivationAssociations` reste inchangé (il produit ; le scoreur classe).

## Décision 2 — Pondération par **famille d'effets**

Plutôt que 14 poids individuels (intimidant), on regroupe les mécanismes
**bénéfiques** en **familles d'effets** (`FamilleEffetAssociation`), source unique
de vérité (fonction `familleDe(mécanisme)`, comme `AccesNiveau`) :

| Famille | Mécanismes |
|---|---|
| **gainDePlace** | tuteurStructurel, etagementLumiere, successionTemporelle |
| **protectionRavageurs** | repulsionRavageur, plantePiege, brouillageOlfactif |
| **fertilite** | fixationAzote |
| **pollinisation** | attractionPollinisateurs |
| **couvertureAbri** | couvreSol, briseVent |

Chaque famille porte un **poids** `PoidsAssociation { ignore, faible, normal, fort }`
(multiplicateurs `0.0 / 0.5 / 1.0 / 1.5`). `ignore` (= 0) **fait disparaître**
toute une famille — exactement le cas « la répulsion ne marche pas chez moi ».

## Décision 3 — Profil de poids personnalisable (expert)

Un value object `ProfilPonderationAssociations` (map `FamilleEffetAssociation →
PoidsAssociation`) :

- **`ProfilPonderationAssociations.defaut()`** : des poids par défaut sensés,
  **appliqués à tous**.
- **Surcharge persistée** par l'utilisateur, réversible (retour aux défauts
  toujours possible — opt-out friendly, cohérent avec la philosophie projet).
- **Édition réservée au palier expert** ([ADR-0009](0009-paliers-experience-divulgation-progressive.md))
  : nouveau drapeau `AccesNiveau.ponderationAssociations ⟹ expert` (au même titre
  que `rotationAvancee` / `solTexturePh`). Les autres paliers profitent des
  défauts sans voir le réglage.

## Décision 4 — Désencombrement de la vue Associations

- Tri par **score décroissant** de chaque côté (bons / à éviter).
- **Curatées toujours visibles** ; suggestions dérivées limitées aux **N
  meilleures par côté** (N par défaut ≈ 4–5) ; le reste sous un **« voir plus »**.
- Le badge « Suggéré » + la confiance (ADR-0010 Lot 4) restent ; on ajoute, pour
  l'expert, un accès au réglage des poids.

---

## Découpage en lots livrables

Chaque lot laisse l'app verte (`flutter analyze` + suite). Tests en parallèle.

| Lot | Périmètre | Dépendance |
|---|---|---|
| **1 — Modèle de score** ✅ | enum `FamilleEffetAssociation` + `familleDe(mécanisme)` ; enum `PoidsAssociation` (×0/0.5/1/1.5) ; VO `ProfilPonderationAssociations` (`defaut`/`poids`/`multiplicateur`/`avec`/`estDefaut`) ; `ScoreurAssociations` pur (+ `estRetenue`) ; tests. | ADR-0010 Lot 3 ✅ |
| **2 — Persistance + gating** ✅ | profil dans `PreferencesUtilisateur` (colonne JSON `ponderation_associations`, mapper, `copierAvec`) ; setters notifier `definirPoidsAssociation` / `reinitialiserPonderationAssociations` ; `AccesNiveau.ponderationAssociations` (expert) ; round-trip BDD testé. | Lot 1, ADR-0009 |
| **3 — Vue Associations** ✅ | `_NoeudAssoc` scoré ; tri desc (curatées en score `infini`, jamais élaguées) ; top-N dérivées par côté (`_VueAssociations` stateful + `_BoutonVoirPlus`) ; familles `ignore` masquées. | Lot 1 |
| **4 — Réglage expert + reco** ✅ | `PanneauPonderationAssociations` (5 familles × `ChampSegmente<PoidsAssociation>` + reset), sous-route `/plus/ponderation`, entrée gardée expert dans `ecran_plus` ; `RecommanderPlantes.executer(profil:)` pondère le bonus dérivé (seuil = `facteurMoyen`). | Lots 2–3 |

---

## Conséquences

### Positives
- **Vue lisible** : hiérarchisée, élaguée, sans rien cacher d'autorité (curaté).
- **Adaptable au terrain** : l'utilisateur priorise ce qui marche *chez lui* —
  reconnaît que l'art du potager n'est pas une science exacte.
- **Pur & testable** : score = fonction(profil, association) ; le moteur de
  dérivation reste intact.
- Réutilise la divulgation progressive (ADR-0009) et la précédence curatée
  (ADR-0010).

### Négatives / risques
- Surface de réglage supplémentaire (mitigée : par famille, expert seulement,
  défauts pour tous).
- Calibrage des constantes (poids par défaut, facteurs de confiance, N) à
  itérer ; valeurs centralisées dans le scoreur / le profil par défaut.

---

## Liens
- [ADR-0010](0010-associations-multi-mecanismes.md) — dérivation typée (produit les suggestions scorées).
- [ADR-0009](0009-paliers-experience-divulgation-progressive.md) — gating du réglage (expert).
- Registre : `docs/15` §8 #11 (vue Associations).
- Code visé : `lib/application/engine/` (scoreur), `lib/domain/enums/`, `lib/domain/value_objects/`, `lib/presentation/widgets/vue_associations.dart`.
