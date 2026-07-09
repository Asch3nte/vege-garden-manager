# FICHES À CRÉER — Base de connaissances « plantes potagères »

> Feuille de route de contenu pour la base YAML (`assets/fiches_plantes/`).
> Organisation conforme à **ADR-0005** : `Famille botanique → Espèce (fiche mère)
> → Variétés (fiches filles)`. On créera les fiches **par batchs** en repartant
> de ce document.

## Légende

| Marque | Signification |
|--------|---------------|
| ✅ | Fiche **déjà créée** (ID indiqué) |
| ⬜ | Fiche **à créer** |
| 🔡 | Espèce à **très grand nombre de cultivars** — la liste ci-dessous est une sélection notable, extensible à l'infini au fil des batchs |

## Conventions de nommage (rappel ADR-0005)

- Espèce : `[CAT3]-[NUM3]` — ex. `LEG-024`
- Variété : `[CAT3]-[NUM3]-V[NUM3]` — ex. `LEG-024-V001`
- Codes catégorie : `LEG`=légume · `ARO`=aromatique · `FRU`=fruit ·
  `PFR`=petit-fruit · `FLE`=fleur · `CER`=céréale · `ENG`=engrais-vert
- Numéros **séquentiels et immuables**, jamais réattribués.
- La **famille** doit exister dans `_familles/*.yaml` (sinon la créer d'abord).

---

# 🥕 LÉGUMES (`LEG`)

## Solanaceae — Solanacées

### Tomate — *Solanum lycopersicum* ✅ `LEG-001` 🔡
- ✅ `V001` Cœur de Bœuf
- ✅ `V002` Cerise
- ✅ `V003` San Marzano
- ✅ `V004` Noire de Crimée
- ✅ `V005` Andine Cornue
- ✅ `V006` Marmande
- ✅ `V007` Ananas
- ✅ `V008` Rose de Berne
- ✅ `V009` Montfavet
- ✅ `V010` Roma
- ✅ `V011` Tigerella
- ⬜ Green Zebra
- ⬜ Black Cherry
- ⬜ Cornue des Andes (si distinguée de l'Andine)
- ⬜ Beefsteak
- ⬜ Saint-Pierre
- ⬜ Coeur de Boeuf Orange
- ⬜ Téton de Vénus
- ⬜ Cœur de Bœuf Blanc / Green
- ⬜ Yellow Submarine (jaune poire)
- ⬜ Poire jaune / Poire rouge
- ⬜ Costoluto Fiorentino
- ⬜ Brandywine
- ⬜ Gardener's Delight
- ⬜ Sungold (cerise orange)
- ⬜ Fantasio (F1 résistante mildiou)
- ⬜ Maestria (F1 résistante)
- ⬜ Cœur de Pigeon

### Aubergine — *Solanum melongena* ✅ `LEG-002`
- ✅ `V001` Violette de Florence
- ✅ `V002` Aubergine de Barbentane
- ✅ `V003` Aubergine Black Beauty
- ✅ `V005` Aubergine Ronde de Valence
- ✅ `V004` Aubergine Listada de Gandia
- ⬜ Longue Violette de Barbentane
- ⬜ Blanche (Dourga / White Egg)
- ⬜ Thaï (verte longue)
- ⬜ Rosa Bianca

### Poivron — *Capsicum annuum* ✅ `LEG-019`
- ✅ `V001` Corno di Toro
- ✅ `V002` Poivron California Wonder
- ✅ `V005` Poivron Yolo Wonder
- ✅ `V003` Poivron Marconi
- ✅ `V004` Poivron Doux d'Espagne
- ⬜ Lamuyo
- ⬜ Sucette de Provence
- ⬜ Doux des Landes

### Piment — *Capsicum spp.* ⬜ *(id à attribuer au moment de la création)* 🔡
> À arbitrer : espèce distincte ou variétés sous *C. annuum/chinense/frutescens*.
- ⬜ Piment d'Espelette (*C. annuum*)
- ⬜ Piment de Cayenne
- ⬜ Jalapeño
- ⬜ Habanero (*C. chinense*)
- ⬜ Doux long des Landes
- ⬜ Gorria / Basque
- ⬜ Oiseau (*C. frutescens*)
- ⬜ Padrón

### Pomme de terre — *Solanum tuberosum* ✅ `LEG-020` 🔡
- ✅ `V001` Charlotte
- ✅ `V002` Pomme de terre Bintje
- ✅ `V003` Pomme de terre Ratte
- ⬜ Amandine
- ⬜ Nicola
- ⬜ Rosabelle
- ✅ `V005` Pomme de terre Désirée
- ✅ `V004` Pomme de terre Vitelotte
- ✅ `V006` Pomme de terre Belle de Fontenay
- ⬜ Monalisa
- ⬜ Agata
- ⬜ Pompadour
- ⬜ Roseval

### Physalis / Coqueret du Pérou — *Physalis peruviana* ⬜ *(id à attribuer au moment de la création)*
- ⬜ Goldie
- ⬜ Amour en cage (Physalis alkekengi — ornemental, à distinguer)

### Tomatillo — *Physalis philadelphica* ⬜ *(id à attribuer au moment de la création)*
- ⬜ Verde
- ⬜ Purple

---

## Cucurbitaceae — Cucurbitacées

### Courgette — *Cucurbita pepo* ✅ `LEG-011`
- ✅ `V001` Black Beauty
- ✅ `V004` Courgette Verte des Maraîchers
- ✅ `V002` Courgette Ronde de Nice
- ✅ `V003` Courgette Gold Rush
- ⬜ Grisette de Provence
- ✅ `V005` Courgette Costata Romanesca
- ⬜ Blanche de Virginie
- ⬜ Courgette-tromba / Tromboncino

### Courge musquée — *Cucurbita moschata* ✅ `LEG-010`
- ✅ `V001` Butternut Ponca
- ✅ `V002` Courge Butternut Waltham
- ✅ `V003` Courge Musquée de Provence
- ✅ `V004` Courge Longue de Nice
- ⬜ Sucrine du Berry

### Potimarron — *Cucurbita maxima* ✅ `LEG-021`
- ✅ `V001` Rouge Vif d'Étampes
> Note : Rouge Vif d'Étampes est un potiron (*maxima*) ; vérifier le
> rattachement espèce vs. « Potimarron » lors du batch.
- ✅ `V002` Potimarron Red Kuri / Uchiki Kuri
- ⬜ Giraumon Turban
- ✅ `V003` Potimarron Bleu de Hongrie
- ✅ `V004` Potimarron Marina di Chioggia
- ⬜ Buttercup
- ⬜ Hubbard
- ⬜ Courge de Siam

### Potiron — *Cucurbita maxima* ⬜ *(id à attribuer au moment de la création)* (si séparé du potimarron)
- ⬜ Jaune Gros de Paris
- ⬜ Atlantic Giant
- ⬜ Galeux d'Eysines

### Courge / Pâtisson & autres *pepo* — ⬜ *(id à attribuer au moment de la création)*
- ⬜ Pâtisson Blanc
- ⬜ Pâtisson Panaché Vert et Blanc
- ⬜ Spaghetti végétal
- ⬜ Delicata
- ⬜ Gland (Acorn)
- ⬜ Jack Be Little (mini)
- ⬜ Sweet Dumpling

### Concombre — *Cucumis sativus* ✅ `LEG-009`
- ✅ `V001` Marketmore
- ⬜ Le Généreux
- ✅ `V002` Concombre Vert Long Maraîcher
- ✅ `V003` Concombre Blanc Long Parisien
- ✅ `V004` Concombre Lemon
- ⬜ Beit Alpha (libanais)

### Cornichon — *Cucumis sativus* ⬜ *(id à attribuer au moment de la création)* (ou variété du concombre)
- ⬜ Vert Petit de Paris
- ⬜ Fin de Meaux
- ⬜ Vorgebirgstrauben

### Melon — *Cucumis melo* ✅ `LEG-030`
> Espèce mère créée (lot « potagères courantes »). Variétés encore à créer :
- ⬜ Charentais
- ⬜ Cantaloup de Bellegarde
- ⬜ Petit Gris de Rennes
- ⬜ Sucrin de Tours
- ⬜ Ananas d'Amérique
- ⬜ Melon d'eau / de conserve

### Pastèque — *Citrullus lanatus* ✅ `LEG-041`
- ⬜ Sugar Baby
- ⬜ Crimson Sweet
- ⬜ Charleston Gray
- ⬜ À confiture (à graines rouges)

### Gourde / Calebasse — *Lagenaria siceraria* ⬜ *(id à attribuer au moment de la création)*
- ⬜ Pèlerine
- ⬜ Massue d'Hercule

### Chayotte / Christophine — *Sechium edule* ⬜ *(id à attribuer au moment de la création)*

---

## Brassicaceae — Brassicacées (crucifères)

### Chou brocoli — *Brassica oleracea* var. *italica* ✅ `LEG-006`
- ✅ `V001` Calabrese
- ⬜ De Cicco
- ⬜ Romanesco (à arbitrer : brocoli vs chou-fleur)
- ⬜ Pourpre du Cap / Purple Sprouting

### Chou cabus (pommé) — *Brassica oleracea* var. *capitata* ✅ `LEG-007`
- ✅ `V001` Rouge (Cabus rouge)
- ⬜ Cœur de Bœuf des Vertus
- ⬜ Quintal d'Alsace (chou à choucroute)
- ⬜ De Milan / Milan de Pontoise (frisé)
- ⬜ Nantais hâtif
- ⬜ Point de Bruxelles

### Chou-fleur — *Brassica oleracea* var. *botrytis* ✅ `LEG-008`
- ✅ `V001` de Bretagne
- ⬜ Merveille de Toutes Saisons
- ⬜ Géant d'Automne
- ⬜ Romanesco
- ⬜ Violet de Sicile

### Chou de Bruxelles — *Brassica oleracea* var. *gemmifera* ✅ `LEG-031`
> Espèce mère créée (lot « potagères courantes »). Variétés encore à créer :
- ⬜ de Rosny
- ⬜ Long Island
- ⬜ Groninger

### Chou frisé / Kale — *Brassica oleracea* var. *sabellica* ✅ `LEG-032`
> Espèce mère créée (lot « potagères courantes »). Variétés encore à créer :
- ⬜ Kale Vert Demi-Nain
- ⬜ Cavolo Nero / Noir de Toscane
- ⬜ Redbor (rouge)
- ⬜ Rouge de Russie (Red Russian)

### Chou-rave — *Brassica oleracea* var. *gongylodes* ✅ `LEG-036`
- ⬜ Blanc de Vienne
- ⬜ Bleu de Vienne
- ⬜ Superschmelz

### Chou pommé de Chine / Pé-tsaï — *Brassica rapa* subsp. *pekinensis* ⬜ *(id à attribuer au moment de la création)*
- ⬜ Michihili
- ⬜ Nagaoka F1

### Pak choï — *Brassica rapa* subsp. *chinensis* ✅ `LEG-038`
- ⬜ Blanc / Baby

### Navet — *Brassica rapa* subsp. *rapa* ✅ `LEG-015`
- ✅ `V001` Boule d'Or
- ⬜ de Nancy (à collet violet)
- ⬜ des Vertus Marteau
- ⬜ Blanc Globe à collet violet
- ⬜ Milan Rouge

### Rutabaga — *Brassica napus* var. *napobrassica* ✅ `LEG-037`
- ⬜ Wilhelmsburger
- ⬜ à collet rouge

### Radis — *Raphanus sativus* ✅ `LEG-022`
- ✅ `V001` Cherry Belle
- ⬜ de 18 jours
- ⬜ National 2
- ⬜ Flamboyant
- ⬜ Glaçon (blanc long)
- ⬜ Noir Gros Rond d'Hiver
- ⬜ Rose de Chine
- ⬜ Green Meat / Green Luobo
- ⬜ Daïkon (radis blanc japonais)

### Roquette — *Eruca vesicaria* ✅ `LEG-035`
- ⬜ Cultivée
- ⬜ Sauvage (*Diplotaxis tenuifolia*)

### Cresson de fontaine — *Nasturtium officinale* ⬜ *(id à attribuer au moment de la création)*

### Cresson alénois — *Lepidium sativum* ✅ `LEG-039`

### Moutarde — *Brassica juncea* ⬜ *(id à attribuer au moment de la création)*
- ⬜ Rouge / Red Giant
- ⬜ Mizuna (*B. rapa* var. *nipposinica*)
- ⬜ Mibuna

### Raifort — *Armoracia rusticana* ⬜ *(id à attribuer au moment de la création)*

---

## Apiaceae — Apiacées (ombellifères)

### Carotte — *Daucus carota* ✅ `LEG-004` 🔡
- ✅ `V001` Nantaise Améliorée
- ⬜ de Colmar à cœur rouge
- ⬜ Touchon
- ⬜ Chantenay à cœur rouge
- ⬜ de Meaux
- ⬜ Jaune du Doubs
- ⬜ Blanche des Vosges
- ⬜ Violette (Purple Haze / Cosmic Purple)
- ⬜ Marché de Paris (ronde)

### Céleri-rave — *Apium graveolens* var. *rapaceum* ✅ `LEG-005`
- ✅ `V001` Brilliant
- ⬜ Géant de Prague
- ⬜ Monarch

### Céleri branche — *Apium graveolens* var. *dulce* ✅ `LEG-034`
- ⬜ Vert d'Elne
- ⬜ Doré Chemin
- ⬜ Plein Blanc Pascal

### Panais — *Pastinaca sativa* ✅ `LEG-033`
- ⬜ Demi-Long de Guernesey
- ⬜ Half Long White
- ⬜ Tender and True

### Fenouil (bulbe) — *Foeniculum vulgare* var. *azoricum* ✅ `LEG-024`
> Espèce mère créée (lot « fleurs compagnes »). Variétés encore à créer :
- ⬜ Doux de Florence
- ⬜ Zefa Fino
- ⬜ Romanesco

### Persil-racine — *Petroselinum crispum* var. *tuberosum* ⬜ *(id à attribuer au moment de la création)*
> (Le persil aromatique est en `ARO-002`.)

---

## Fabaceae — Fabacées (légumineuses)

### Haricot — *Phaseolus vulgaris* ✅ `LEG-013` 🔡
- ✅ `V001` vert Fin de Bagnols
- ⬜ Contender (nain mangetout)
- ⬜ Beurre de Rocquencourt (nain jaune)
- ⬜ Tarbais (à rames, grain)
- ⬜ Coco de Paimpol
- ⬜ Flageolet Chevrier
- ⬜ Borlotto / Coco rose (Lingot)
- ⬜ Mangetout à rames Or du Rhin
- ⬜ Roi des Belges
- ⬜ Blue Lake
- ⬜ Soissons (gros grain blanc)

### Haricot d'Espagne — *Phaseolus coccineus* ⬜ *(id à attribuer au moment de la création)*
- ⬜ à fleurs rouges
- ⬜ Blanc géant

### Pois — *Pisum sativum* ✅ `LEG-018`
- ✅ `V001` mangetout Carouby (de Maussane)
- ⬜ Petit Provençal (à grains)
- ⬜ Merveille de Kelvedon
- ⬜ Serpette Guilloteau
- ⬜ Roi des Conserves
- ⬜ Corne de Bélier (mangetout)
- ⬜ Petit pois Douce Provence

### Fève — *Vicia faba* ✅ `LEG-026`
> Espèce mère créée (lot « potagères courantes »). Variétés encore à créer :
- ⬜ d'Aguadulce à très longue cosse
- ⬜ de Séville
- ⬜ Superaguadulce
- ⬜ The Sutton (naine)

### Lentille — *Lens culinaris* ⬜ *(id à attribuer au moment de la création)*
- ⬜ Verte du Puy
- ⬜ Blonde
- ⬜ Corail (rose)
- ⬜ Beluga (noire)

### Pois chiche — *Cicer arietinum* ⬜ *(id à attribuer au moment de la création)*

### Soja (edamame) — *Glycine max* ⬜ *(id à attribuer au moment de la création)*

### Arachide — *Arachis hypogaea* ⬜ *(id à attribuer au moment de la création)*

---

## Asteraceae — Astéracées (composées)

### Laitue — *Lactuca sativa* ✅ `LEG-014` 🔡
- ✅ `V001` Batavia Rouge Grenobloise
- ⬜ Reine de Mai (pommée de printemps)
- ⬜ Merveille des Quatre Saisons
- ⬜ Grosse Blonde Paresseuse
- ⬜ Rougette de Montpellier
- ⬜ Feuille de Chêne (blonde / rouge)
- ⬜ Lollo Rossa / Lollo Bionda
- ⬜ Sucrine
- ⬜ Romaine Blonde Maraîchère
- ⬜ Romaine Ballon
- ⬜ à couper (Gloire du Dauphiné)
- ⬜ Iceberg / Batavia Blonde de Paris
- ⬜ Craquerelle du Midi

### Chicorée frisée / scarole — *Cichorium endivia* ⬜ *(id à attribuer au moment de la création)*
- ⬜ Frisée de Ruffec
- ⬜ Frisée Wallonne
- ⬜ Scarole Cornet d'Anjou
- ⬜ Scarole Géante Maraîchère

### Chicorée sauvage / Endive — *Cichorium intybus* ⬜ *(id à attribuer au moment de la création)*
- ⬜ Witloof (endive / chicon)
- ⬜ Pain de Sucre
- ⬜ Rouge de Vérone (Trévise)
- ⬜ Chioggia (Radicchio)
- ⬜ Barbe de Capucin
- ⬜ Sauvage améliorée / à café

### Artichaut — *Cynara cardunculus* var. *scolymus* ✅ `LEG-023`
- ✅ `V001` Vert de Laon
- ⬜ Violet de Provence
- ⬜ Gros Vert de Laon (si distinct)
- ⬜ Camus de Bretagne
- ⬜ Blanc Hyérois

### Cardon — *Cynara cardunculus* ⬜ *(id à attribuer au moment de la création)*
- ⬜ de Tours épineux
- ⬜ Plein Blanc Inerme

### Salsifis — *Tragopogon porrifolius* ⬜ *(id à attribuer au moment de la création)*
- ⬜ Blanc géant / Mammouth

### Scorsonère — *Scorzonera hispanica* ⬜ *(id à attribuer au moment de la création)*
- ⬜ Géante Noire de Russie

### Topinambour — *Helianthus tuberosus* ✅ `LEG-044`
- ⬜ Fuseau
- ⬜ Rouge du Limousin
- ⬜ Patate (blanc)

---

## Amaranthaceae — Amaranthacées (ex-Chénopodiacées)

### Betterave — *Beta vulgaris* ✅ `LEG-003`
- ✅ `V001` Chioggia
- ⬜ de Détroit / Noire Plate d'Égypte
- ⬜ Crapaudine
- ⬜ Blanche / Albina
- ⬜ Burpee's Golden (jaune)
- ⬜ Cylindra (allongée)

### Bette / Blette (poirée) — *Beta vulgaris* var. *cicla* ✅ `LEG-029`
> Espèce mère créée (lot « potagères courantes »). Variétés encore à créer :
- ⬜ Verte à cardes blanches
- ⬜ à cardes Blondes à couper (épinard perpétuel)
- ⬜ Bright Lights / Five Colors (multicolore)
- ⬜ Rhubarb Chard (à carde rouge)

### Épinard — *Spinacia oleracea* ✅ `LEG-012`
- ✅ `V001` Géant d'Hiver
- ⬜ Monstrueux de Viroflay
- ⬜ Matador
- ⬜ America
- ⬜ Butterflay

### Arroche — *Atriplex hortensis* ⬜ *(id à attribuer au moment de la création)*
- ⬜ Rouge
- ⬜ Blonde

### Épinard-fraise — *Chenopodium foliosum* ⬜ *(id à attribuer au moment de la création)*

### Quinoa — *Chenopodium quinoa* ⬜ *(id à attribuer au moment de la création)* (ou céréale)

---

## Amaryllidaceae — Amaryllidacées (ex-Alliacées)

### Oignon — *Allium cepa* ✅ `LEG-016`
- ✅ `V001` Rouge de Florence
- ⬜ Jaune Paille des Vertus
- ⬜ Blanc de Paris / Hâtif de Paris
- ⬜ Rouge de Brunswick
- ⬜ des Cévennes (doux)
- ⬜ Rosé de Roscoff
- ⬜ de Mulhouse (à conserver)
- ⬜ Sturon

### Échalote — *Allium cepa* var. *aggregatum* ✅ `LEG-027`
> Espèce mère créée (lot « potagères courantes »). Variétés encore à créer :
- ⬜ Grise (de Jersey)
- ⬜ Longue / de Jersey rose
- ⬜ Cuisse de Poulet

### Ail — *Allium sativum* ✅ `LEG-025`
> Espèce mère créée (lot « fleurs compagnes »). Variétés encore à créer :
- ⬜ Blanc de la Drôme
- ⬜ Rose de Lautrec
- ⬜ Violet de Cadours
- ⬜ Fructidor
- ⬜ Rouge (d'automne)
- ⬜ des Ours (*A. ursinum*, aromatique sauvage)

### Poireau — *Allium ampeloprasum* var. *porrum* ✅ `LEG-017`
- ✅ `V001` Bleu de Solaise
- ⬜ de Carentan
- ⬜ Monstrueux d'Elbeuf
- ⬜ Gros Long d'Été
- ⬜ Malabare
- ⬜ d'Hiver Géant d'Hiver

### Ciboule / Cive — *Allium fistulosum* ⬜ *(id à attribuer au moment de la création)*
> (La ciboulette aromatique est en `ARO-003`.)
- ⬜ Rouge
- ⬜ Blanche hâtive

---

## Convolvulaceae — Convolvulacées

### Patate douce — *Ipomoea batatas* ✅ `LEG-048`
- ⬜ Beauregard (chair orange)
- ⬜ Évangéline
- ⬜ O'Henry (chair blanche)
- ⬜ Murasaki (peau violette)

---

## Polygonaceae — Polygonacées

### Oseille — *Rumex acetosa* ✅ `LEG-046`
- ⬜ Large de Belleville
- ⬜ Sanguine (à feuilles veinées de rouge)
- ⬜ Petite oseille / oseille des prés

### Rhubarbe — *Rheum rhabarbarum* ✅ `LEG-045`
- ⬜ Victoria
- ⬜ Framboozen Rood
- ⬜ Mira / Goliath

---

## Malvaceae — Malvacées

### Gombo (okra) — *Abelmoschus esculentus* ⬜ *(id à attribuer au moment de la création)*
- ⬜ Clemson Spineless
- ⬜ Rouge de Bourgogne

---

## Autres familles — légumes divers

### Mâche — *Valerianella locusta* (Caprifoliaceae) ✅ `LEG-028`
> Espèce mère créée (lot « potagères courantes »). Variétés encore à créer :
- ⬜ Verte de Cambrai
- ⬜ Coquille de Louviers
- ⬜ Ronde maraîchère
- ⬜ à grosse graine

### Pourpier — *Portulaca oleracea* (Portulacaceae) ⬜ *(id à attribuer au moment de la création)*
- ⬜ Doré à large feuille
- ⬜ Vert

### Tétragone (épinard de Nouvelle-Zélande) — *Tetragonia tetragonioides* ⬜ *(id à attribuer au moment de la création)*

### Crosne du Japon — *Stachys affinis* (Lamiaceae) ⬜ *(id à attribuer au moment de la création)*

### Maïs doux — *Zea mays* var. *saccharata* (Poaceae) ⬜ *(id à attribuer au moment de la création)*
- ⬜ Golden Bantam
- ⬜ Country Gentleman
- ⬜ Double Standard
> (Voir aussi § Céréales pour le maïs grain/pop-corn.)

### Asperge — *Asparagus officinalis* (Asparagaceae) ✅ `LEG-047`
- ⬜ d'Argenteuil hâtive
- ⬜ Violette d'Albenga
- ⬜ Verte Précoce d'Argenteuil
- ⬜ Mary Washington

### Igname — *Dioscorea spp.* ⬜ *(id à attribuer au moment de la création)*

### Manioc — *Manihot esculenta* ⬜ *(id à attribuer au moment de la création)*

---

# 🌿 AROMATIQUES & CONDIMENTAIRES (`ARO`)

## Lamiaceae — Lamiacées

### Basilic — *Ocimum basilicum* ✅ `ARO-001` 🔡
- ⬜ `V…` Grand Vert (à grandes feuilles)
- ⬜ Genovese
- ⬜ Pourpre / Dark Opal
- ⬜ Fin Vert Compact (à petites feuilles)
- ⬜ Citron (*O. × africanum*)
- ⬜ Cannelle
- ⬜ Thaï (*O. basilicum* var. *thyrsiflora*)
- ⬜ Sacré / Tulsi (*O. tenuiflorum*)

### Menthe — *Mentha* spp. ✅ `ARO-005` (Menthe poivrée *M. × piperita*)
- ✅ `V001` Menthe Verte (*M. spicata*)
- ⬜ Menthe Marocaine
- ⬜ Menthe Bergamote
- ⬜ Menthe Pomme
- ⬜ Menthe Chocolat
- ⬜ Menthe aquatique / Pouliot

### Thym — *Thymus vulgaris* ✅ `ARO-004`
- ✅ `V001` Thym Citron (*T. × citriodorus*)
- ⬜ Thym commun (compact)
- ⬜ Thym serpolet (*T. serpyllum*)
- ⬜ Thym d'hiver / Faustini

### Romarin — *Salvia rosmarinus* ⬜ *(id à attribuer au moment de la création)*
- ⬜ Officinal dressé
- ⬜ Rampant / Prostratus

### Sauge — *Salvia officinalis* ⬜ *(id à attribuer au moment de la création)*
- ⬜ Officinale
- ⬜ Purpurascens (pourpre)
- ⬜ Tricolor
- ⬜ Ananas (*S. elegans*)

### Origan — *Origanum vulgare* ⬜ *(id à attribuer au moment de la création)*
- ⬜ Commun
- ⬜ Doré (Aureum)

### Marjolaine — *Origanum majorana* ⬜ *(id à attribuer au moment de la création)*

### Mélisse — *Melissa officinalis* ⬜ *(id à attribuer au moment de la création)*
- ⬜ Citronnelle
- ⬜ Panachée (Aurea)

### Sarriette — *Satureja* spp. ⬜ *(id à attribuer au moment de la création)*
- ⬜ des jardins (annuelle, *S. hortensis*)
- ⬜ vivace / des montagnes (*S. montana*)

### Hysope — *Hyssopus officinalis* ⬜ *(id à attribuer au moment de la création)*

## Apiaceae — Apiacées aromatiques

### Persil — *Petroselinum crispum* ✅ `ARO-002`
- ✅ `V001` Frisé
- ⬜ Commun / Plat (Géant d'Italie)
- ⬜ Frisé Vert Foncé

### Coriandre — *Coriandrum sativum* ✅ `ARO-006`
- ✅ `V001` Santos (montaison lente)
- ⬜ Commune / à graines

### Aneth — *Anethum graveolens* ✅ `ARO-007`

### Cerfeuil — *Anthriscus cerefolium* ⬜ *(id à attribuer au moment de la création)*
- ⬜ Commun
- ⬜ Frisé

### Cumin — *Cuminum cyminum* ⬜ *(id à attribuer au moment de la création)*

### Carvi — *Carum carvi* ⬜ *(id à attribuer au moment de la création)*

### Livèche (ache des montagnes) — *Levisticum officinale* ⬜ *(id à attribuer au moment de la création)*

### Anis vert — *Pimpinella anisum* ⬜ *(id à attribuer au moment de la création)*

## Autres aromatiques

### Ciboulette — *Allium schoenoprasum* ✅ `ARO-003`
- ✅ `V001` Ciboulette ail (*Allium tuberosum*)
- ⬜ Commune

### Estragon — *Artemisia dracunculus* (Asteraceae) ⬜ *(id à attribuer au moment de la création)*
- ⬜ français / vrai
- ⬜ de Russie

### Laurier-sauce — *Laurus nobilis* (Lauraceae) ⬜ *(id à attribuer au moment de la création)*

### Verveine citronnelle — *Aloysia citrodora* (Verbenaceae) ⬜ *(id à attribuer au moment de la création)*

### Fenouil aromatique — *Foeniculum vulgare* (feuillage) ⬜ *(id à attribuer au moment de la création)*
> (Le fenouil bulbe est en § Légumes / Apiaceae.)

### Gingembre — *Zingiber officinale* (Zingiberaceae) ⬜ *(id à attribuer au moment de la création)*

### Curcuma — *Curcuma longa* (Zingiberaceae) ⬜ *(id à attribuer au moment de la création)*

### Raifort → voir `LEG-044` (Brassicaceae, condiment-racine)

---

# 🍓 PETITS FRUITS (`PFR`)

### Fraisier — *Fragaria × ananassa* ✅ `PFR-001` 🔡
- ✅ `V001` Gariguette
- ⬜ Mara des Bois (remontante)
- ⬜ Charlotte
- ⬜ Ciflorette
- ⬜ Cireine
- ⬜ Maestro
- ⬜ Sengana
- ⬜ Fraisier des bois (*Fragaria vesca*)
- ⬜ Reine des Vallées (des bois remontant)

### Framboisier — *Rubus idaeus* ✅ `PFR-002`
- ✅ `V001` Heritage (remontant)
- ⬜ Meeker (non remontant)
- ⬜ Malling Promise
- ⬜ Zeva
- ⬜ Fall Gold (jaune)
- ⬜ Willamette

### Groseillier rouge / blanc — *Ribes rubrum* ✅ `PFR-003`
- ✅ `V001` Jonkheer Van Tets (rouge)
- ⬜ Versaillaise Rouge
- ⬜ Blanche de Versailles / Blanka
- ⬜ Rovada
- ⬜ Junifer

### Cassis — *Ribes nigrum* ✅ `PFR-004`
- ✅ `V001` Noir de Bourgogne
- ⬜ Andega
- ⬜ Ben Sarek
- ⬜ Titania

### Myrtille — *Vaccinium corymbosum* ✅ `PFR-005`
- ✅ `V001` Bluecrop
- ⬜ Duke
- ⬜ Bluetta
- ⬜ Patriot
- ⬜ Myrtille sauvage / airelle (*V. myrtillus*)

### Groseillier à maquereau — *Ribes uva-crispa* ⬜ *(id à attribuer au moment de la création)*
- ⬜ Invicta
- ⬜ Captivator (sans épines)
- ⬜ Hinnonmäki Rouge / Jaune

### Casseille (cassis × groseille) — *Ribes × nidigrolaria* ⬜ *(id à attribuer au moment de la création)*

### Mûre (ronce) — *Rubus fruticosus* ⬜ *(id à attribuer au moment de la création)*
- ⬜ Thornless Evergreen (sans épines)
- ⬜ Chester
- ⬜ Loch Ness

### Mûre-framboise (Tayberry / Loganberry) — *Rubus* hybrides ⬜ *(id à attribuer au moment de la création)*

### Baie de mai (camérisier) — *Lonicera caerulea* ⬜ *(id à attribuer au moment de la création)*

### Argousier — *Hippophae rhamnoides* ⬜ *(id à attribuer au moment de la création)*

### Goji (baie) — *Lycium barbarum* ⬜ *(id à attribuer au moment de la création)*

### Amélanchier — *Amelanchier* spp. ⬜ *(id à attribuer au moment de la création)*

### Raisin de table — *Vitis vinifera* (Vitaceae) ⬜ *(id à attribuer au moment de la création)* (ou fruit)
- ⬜ Chasselas
- ⬜ Muscat de Hambourg
- ⬜ Cardinal
- ⬜ Italia

---

# 🌸 FLEURS COMESTIBLES / COMPAGNES (`FLE`)

> Utiles au potager (compagnonnage, pollinisateurs, plantes-pièges).
> Plusieurs sont déjà citées comme **associations** sans fiche dédiée
> (`capucine`, `soucis`…). À transformer en fiches.

### Capucine — *Tropaeolum majus* (Tropaeolaceae) ✅ `FLE-001`
> Espèce mère créée (lot « fleurs compagnes »). Variétés encore à créer :
- ⬜ Grande naine
- ⬜ Grimpante

### Souci — *Calendula officinalis* (Asteraceae) ✅ `FLE-002`

### Œillet d'Inde / Rose d'Inde — *Tagetes* spp. (Asteraceae) ⬜ *(id à attribuer au moment de la création)*
- ⬜ Œillet d'Inde (*T. patula*)
- ⬜ Rose d'Inde (*T. erecta*)
- ⬜ Tagète minute (*T. minuta*, anti-nématodes)

### Bourrache — *Borago officinalis* (Boraginaceae) ⬜ *(id à attribuer au moment de la création)*

### Cosmos — *Cosmos bipinnatus* (Asteraceae) ⬜ *(id à attribuer au moment de la création)*

### Tournesol — *Helianthus annuus* (Asteraceae) ⬜ *(id à attribuer au moment de la création)*

### Souci / Zinnia — *Zinnia elegans* (Asteraceae) ⬜ *(id à attribuer au moment de la création)*

### Phacélie — *Phacelia tanacetifolia* (Boraginaceae) ⬜ *(id à attribuer au moment de la création)*
> (Aussi engrais vert / mellifère — voir § Engrais verts.)

### Lavande — *Lavandula* spp. (Lamiaceae) ⬜ *(id à attribuer au moment de la création)*

---

# 🌾 CÉRÉALES (`CER`)

### Blé — *Triticum aestivum* (Poaceae) ⬜ *(id à attribuer au moment de la création)*
### Maïs (grain / pop-corn) — *Zea mays* ⬜ *(id à attribuer au moment de la création)*
### Orge — *Hordeum vulgare* ⬜ *(id à attribuer au moment de la création)*
### Avoine — *Avena sativa* ⬜ *(id à attribuer au moment de la création)*
### Seigle — *Secale cereale* ⬜ *(id à attribuer au moment de la création)*
### Sarrasin (blé noir) — *Fagopyrum esculentum* (Polygonaceae) ⬜ *(id à attribuer au moment de la création)*
### Millet — *Panicum miliaceum* ⬜ *(id à attribuer au moment de la création)*
### Épeautre — *Triticum spelta* ⬜ *(id à attribuer au moment de la création)*

---

# 🌱 ENGRAIS VERTS (`ENG`)

### Moutarde blanche — *Sinapis alba* (Brassicaceae) ✅ `ENG-001`
> Espèce mère créée (lot « fleurs compagnes »). ⚠ Brassicacée : partage
> maladies/ravageurs avec les choux (défavorable en rotation/voisinage).
### Phacélie — *Phacelia tanacetifolia* ⬜ *(id à attribuer au moment de la création)*
### Trèfle incarnat — *Trifolium incarnatum* (Fabaceae) ⬜ *(id à attribuer au moment de la création)*
### Trèfle blanc — *Trifolium repens* ⬜ *(id à attribuer au moment de la création)*
### Vesce commune — *Vicia sativa* (Fabaceae) ⬜ *(id à attribuer au moment de la création)*
### Luzerne — *Medicago sativa* (Fabaceae) ⬜ *(id à attribuer au moment de la création)*
### Sarrasin (couvre-sol) — *Fagopyrum esculentum* ⬜ *(id à attribuer au moment de la création)*
### Seigle fourrager — *Secale cereale* ⬜ *(id à attribuer au moment de la création)*
### Féverole — *Vicia faba* var. *minor* ⬜ *(id à attribuer au moment de la création)*
### Lupin — *Lupinus* spp. (Fabaceae) ⬜ *(id à attribuer au moment de la création)*
### Radis fourrager — *Raphanus sativus* var. *oleiformis* ⬜ *(id à attribuer au moment de la création)*
### Sarrasin / Nyger / Ray-grass — à compléter ⬜

---

## Notes pour les batchs de création

1. **Vérifier la famille** dans `_familles/*.yaml` avant chaque espèce ; créer la
   fiche famille manquante d'abord (schéma `_schema/famille_schema.yaml`).
2. **Attribuer les IDs** en continuité stricte du `_schema/id_registry.yaml`
   (les `LEG-024+`, `ARO-007+`, `PFR-006+`, `FLE-001+`, `CER-001+`, `ENG-001+`
   proposés ci-dessus sont **indicatifs** : recaler sur le registre réel au moment
   de créer, sans jamais réutiliser un numéro).
3. **Héritage sparse** (ADR-0005) : une fiche variété ne déclare que ce qui
   diffère de la mère.
4. **Arbitrages à trancher** signalés dans le texte :
   - Piment : espèce distincte vs variétés de *Capsicum*.
   - Potiron vs Potimarron (rattachement *Cucurbita maxima*).
   - Cornichon : espèce vs variété du concombre.
   - Maïs / sarrasin / phacélie : catégorie légume vs céréale vs engrais vert.
   - Raisin : petit-fruit vs fruit.
5. Les listes marquées 🔡 (tomate, pomme de terre, laitue, carotte, haricot,
   basilic, fraisier…) sont **non exhaustives par nature** : compléter au fil des
   batchs selon les priorités du dev.
6. Prioriser en batch 1 les espèces **potagères courantes manquantes** (piment,
   fève, échalote, ail, mâche, blette, fenouil, chou de Bruxelles, kale, melon,
   pastèque) et les **fleurs compagnes déjà citées en associations** (capucine,
   souci, œillet d'Inde) pour résorber les références orphelines du registre.
```
