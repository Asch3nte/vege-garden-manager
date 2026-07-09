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
- ⬜ Barbentane (violette allongée)
- ⬜ Black Beauty
- ⬜ Ronde de Valence
- ⬜ Listada de Gandia (zébrée)
- ⬜ Longue Violette de Barbentane
- ⬜ Blanche (Dourga / White Egg)
- ⬜ Thaï (verte longue)
- ⬜ Rosa Bianca

### Poivron — *Capsicum annuum* ✅ `LEG-019`
- ✅ `V001` Corno di Toro
- ⬜ California Wonder (carré)
- ⬜ Yolo Wonder
- ⬜ Marconi
- ⬜ Doux d'Espagne (long)
- ⬜ Lamuyo
- ⬜ Sucette de Provence
- ⬜ Doux des Landes

### Piment — *Capsicum spp.* ⬜ `LEG-024` 🔡
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
- ⬜ Bintje
- ⬜ Ratte
- ⬜ Amandine
- ⬜ Nicola
- ⬜ Rosabelle
- ⬜ Désirée
- ⬜ Vitelotte (violette)
- ⬜ Belle de Fontenay
- ⬜ Monalisa
- ⬜ Agata
- ⬜ Pompadour
- ⬜ Roseval

### Physalis / Coqueret du Pérou — *Physalis peruviana* ⬜ `LEG-025`
- ⬜ Goldie
- ⬜ Amour en cage (Physalis alkekengi — ornemental, à distinguer)

### Tomatillo — *Physalis philadelphica* ⬜ `LEG-026`
- ⬜ Verde
- ⬜ Purple

---

## Cucurbitaceae — Cucurbitacées

### Courgette — *Cucurbita pepo* ✅ `LEG-011`
- ✅ `V001` Black Beauty
- ⬜ Verte des Maraîchers
- ⬜ Ronde de Nice
- ⬜ Gold Rush (jaune)
- ⬜ Grisette de Provence
- ⬜ Costata Romanesca
- ⬜ Blanche de Virginie
- ⬜ Courgette-tromba / Tromboncino

### Courge musquée — *Cucurbita moschata* ✅ `LEG-010`
- ✅ `V001` Butternut Ponca
- ⬜ Butternut Waltham
- ⬜ Musquée de Provence
- ⬜ Longue de Nice
- ⬜ Sucrine du Berry

### Potimarron — *Cucurbita maxima* ✅ `LEG-021`
- ✅ `V001` Rouge Vif d'Étampes
> Note : Rouge Vif d'Étampes est un potiron (*maxima*) ; vérifier le
> rattachement espèce vs. « Potimarron » lors du batch.
- ⬜ Potimarron Red Kuri / Uchiki Kuri
- ⬜ Giraumon Turban
- ⬜ Bleu de Hongrie
- ⬜ Marina di Chioggia
- ⬜ Buttercup
- ⬜ Hubbard
- ⬜ Courge de Siam

### Potiron — *Cucurbita maxima* ⬜ `LEG-027` (si séparé du potimarron)
- ⬜ Jaune Gros de Paris
- ⬜ Atlantic Giant
- ⬜ Galeux d'Eysines

### Courge / Pâtisson & autres *pepo* — ⬜ `LEG-028`
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
- ⬜ Vert Long Maraîcher
- ⬜ Blanc Long Parisien
- ⬜ Lemon (rond jaune)
- ⬜ Beit Alpha (libanais)

### Cornichon — *Cucumis sativus* ⬜ `LEG-029` (ou variété du concombre)
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

### Pastèque — *Citrullus lanatus* ⬜ `LEG-031`
- ⬜ Sugar Baby
- ⬜ Crimson Sweet
- ⬜ Charleston Gray
- ⬜ À confiture (à graines rouges)

### Gourde / Calebasse — *Lagenaria siceraria* ⬜ `LEG-032`
- ⬜ Pèlerine
- ⬜ Massue d'Hercule

### Chayotte / Christophine — *Sechium edule* ⬜ `LEG-033`

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

### Chou-rave — *Brassica oleracea* var. *gongylodes* ⬜ `LEG-036`
- ⬜ Blanc de Vienne
- ⬜ Bleu de Vienne
- ⬜ Superschmelz

### Chou pommé de Chine / Pé-tsaï — *Brassica rapa* subsp. *pekinensis* ⬜ `LEG-037`
- ⬜ Michihili
- ⬜ Nagaoka F1

### Pak choï — *Brassica rapa* subsp. *chinensis* ⬜ `LEG-038`
- ⬜ Blanc / Baby

### Navet — *Brassica rapa* subsp. *rapa* ✅ `LEG-015`
- ✅ `V001` Boule d'Or
- ⬜ de Nancy (à collet violet)
- ⬜ des Vertus Marteau
- ⬜ Blanc Globe à collet violet
- ⬜ Milan Rouge

### Rutabaga — *Brassica napus* var. *napobrassica* ⬜ `LEG-039`
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

### Roquette — *Eruca vesicaria* ⬜ `LEG-040`
- ⬜ Cultivée
- ⬜ Sauvage (*Diplotaxis tenuifolia*)

### Cresson de fontaine — *Nasturtium officinale* ⬜ `LEG-041`

### Cresson alénois — *Lepidium sativum* ⬜ `LEG-042`

### Moutarde — *Brassica juncea* ⬜ `LEG-043`
- ⬜ Rouge / Red Giant
- ⬜ Mizuna (*B. rapa* var. *nipposinica*)
- ⬜ Mibuna

### Raifort — *Armoracia rusticana* ⬜ `LEG-044`

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

### Céleri branche — *Apium graveolens* var. *dulce* ⬜ `LEG-045`
- ⬜ Vert d'Elne
- ⬜ Doré Chemin
- ⬜ Plein Blanc Pascal

### Panais — *Pastinaca sativa* ⬜ `LEG-046`
- ⬜ Demi-Long de Guernesey
- ⬜ Half Long White
- ⬜ Tender and True

### Fenouil (bulbe) — *Foeniculum vulgare* var. *azoricum* ✅ `LEG-024`
> Espèce mère créée (lot « fleurs compagnes »). Variétés encore à créer :
- ⬜ Doux de Florence
- ⬜ Zefa Fino
- ⬜ Romanesco

### Persil-racine — *Petroselinum crispum* var. *tuberosum* ⬜ `LEG-048`
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

### Haricot d'Espagne — *Phaseolus coccineus* ⬜ `LEG-049`
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

### Lentille — *Lens culinaris* ⬜ `LEG-051`
- ⬜ Verte du Puy
- ⬜ Blonde
- ⬜ Corail (rose)
- ⬜ Beluga (noire)

### Pois chiche — *Cicer arietinum* ⬜ `LEG-052`

### Soja (edamame) — *Glycine max* ⬜ `LEG-053`

### Arachide — *Arachis hypogaea* ⬜ `LEG-054`

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

### Chicorée frisée / scarole — *Cichorium endivia* ⬜ `LEG-055`
- ⬜ Frisée de Ruffec
- ⬜ Frisée Wallonne
- ⬜ Scarole Cornet d'Anjou
- ⬜ Scarole Géante Maraîchère

### Chicorée sauvage / Endive — *Cichorium intybus* ⬜ `LEG-056`
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

### Cardon — *Cynara cardunculus* ⬜ `LEG-057`
- ⬜ de Tours épineux
- ⬜ Plein Blanc Inerme

### Salsifis — *Tragopogon porrifolius* ⬜ `LEG-058`
- ⬜ Blanc géant / Mammouth

### Scorsonère — *Scorzonera hispanica* ⬜ `LEG-059`
- ⬜ Géante Noire de Russie

### Topinambour — *Helianthus tuberosus* ⬜ `LEG-060`
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

### Arroche — *Atriplex hortensis* ⬜ `LEG-062`
- ⬜ Rouge
- ⬜ Blonde

### Épinard-fraise — *Chenopodium foliosum* ⬜ `LEG-063`

### Quinoa — *Chenopodium quinoa* ⬜ `LEG-064` (ou céréale)

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

### Ciboule / Cive — *Allium fistulosum* ⬜ `LEG-067`
> (La ciboulette aromatique est en `ARO-003`.)
- ⬜ Rouge
- ⬜ Blanche hâtive

---

## Convolvulaceae — Convolvulacées

### Patate douce — *Ipomoea batatas* ⬜ `LEG-068`
- ⬜ Beauregard (chair orange)
- ⬜ Évangéline
- ⬜ O'Henry (chair blanche)
- ⬜ Murasaki (peau violette)

---

## Polygonaceae — Polygonacées

### Oseille — *Rumex acetosa* ⬜ `LEG-069`
- ⬜ Large de Belleville
- ⬜ Sanguine (à feuilles veinées de rouge)
- ⬜ Petite oseille / oseille des prés

### Rhubarbe — *Rheum rhabarbarum* ⬜ `LEG-070`
- ⬜ Victoria
- ⬜ Framboozen Rood
- ⬜ Mira / Goliath

---

## Malvaceae — Malvacées

### Gombo (okra) — *Abelmoschus esculentus* ⬜ `LEG-071`
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

### Pourpier — *Portulaca oleracea* (Portulacaceae) ⬜ `LEG-073`
- ⬜ Doré à large feuille
- ⬜ Vert

### Tétragone (épinard de Nouvelle-Zélande) — *Tetragonia tetragonioides* ⬜ `LEG-074`

### Crosne du Japon — *Stachys affinis* (Lamiaceae) ⬜ `LEG-075`

### Maïs doux — *Zea mays* var. *saccharata* (Poaceae) ⬜ `LEG-076`
- ⬜ Golden Bantam
- ⬜ Country Gentleman
- ⬜ Double Standard
> (Voir aussi § Céréales pour le maïs grain/pop-corn.)

### Asperge — *Asparagus officinalis* (Asparagaceae) ⬜ `LEG-077`
- ⬜ d'Argenteuil hâtive
- ⬜ Violette d'Albenga
- ⬜ Verte Précoce d'Argenteuil
- ⬜ Mary Washington

### Igname — *Dioscorea spp.* ⬜ `LEG-078`

### Manioc — *Manihot esculenta* ⬜ `LEG-079`

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

### Romarin — *Salvia rosmarinus* ⬜ `ARO-007`
- ⬜ Officinal dressé
- ⬜ Rampant / Prostratus

### Sauge — *Salvia officinalis* ⬜ `ARO-008`
- ⬜ Officinale
- ⬜ Purpurascens (pourpre)
- ⬜ Tricolor
- ⬜ Ananas (*S. elegans*)

### Origan — *Origanum vulgare* ⬜ `ARO-009`
- ⬜ Commun
- ⬜ Doré (Aureum)

### Marjolaine — *Origanum majorana* ⬜ `ARO-010`

### Mélisse — *Melissa officinalis* ⬜ `ARO-011`
- ⬜ Citronnelle
- ⬜ Panachée (Aurea)

### Sarriette — *Satureja* spp. ⬜ `ARO-012`
- ⬜ des jardins (annuelle, *S. hortensis*)
- ⬜ vivace / des montagnes (*S. montana*)

### Hysope — *Hyssopus officinalis* ⬜ `ARO-013`

## Apiaceae — Apiacées aromatiques

### Persil — *Petroselinum crispum* ✅ `ARO-002`
- ✅ `V001` Frisé
- ⬜ Commun / Plat (Géant d'Italie)
- ⬜ Frisé Vert Foncé

### Coriandre — *Coriandrum sativum* ✅ `ARO-006`
- ✅ `V001` Santos (montaison lente)
- ⬜ Commune / à graines

### Aneth — *Anethum graveolens* ✅ `ARO-007`

### Cerfeuil — *Anthriscus cerefolium* ⬜ `ARO-015`
- ⬜ Commun
- ⬜ Frisé

### Cumin — *Cuminum cyminum* ⬜ `ARO-016`

### Carvi — *Carum carvi* ⬜ `ARO-017`

### Livèche (ache des montagnes) — *Levisticum officinale* ⬜ `ARO-018`

### Anis vert — *Pimpinella anisum* ⬜ `ARO-019`

## Autres aromatiques

### Ciboulette — *Allium schoenoprasum* ✅ `ARO-003`
- ✅ `V001` Ciboulette ail (*Allium tuberosum*)
- ⬜ Commune

### Estragon — *Artemisia dracunculus* (Asteraceae) ⬜ `ARO-020`
- ⬜ français / vrai
- ⬜ de Russie

### Laurier-sauce — *Laurus nobilis* (Lauraceae) ⬜ `ARO-021`

### Verveine citronnelle — *Aloysia citrodora* (Verbenaceae) ⬜ `ARO-022`

### Fenouil aromatique — *Foeniculum vulgare* (feuillage) ⬜ `ARO-023`
> (Le fenouil bulbe est en § Légumes / Apiaceae.)

### Gingembre — *Zingiber officinale* (Zingiberaceae) ⬜ `ARO-024`

### Curcuma — *Curcuma longa* (Zingiberaceae) ⬜ `ARO-025`

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

### Groseillier à maquereau — *Ribes uva-crispa* ⬜ `PFR-006`
- ⬜ Invicta
- ⬜ Captivator (sans épines)
- ⬜ Hinnonmäki Rouge / Jaune

### Casseille (cassis × groseille) — *Ribes × nidigrolaria* ⬜ `PFR-007`

### Mûre (ronce) — *Rubus fruticosus* ⬜ `PFR-008`
- ⬜ Thornless Evergreen (sans épines)
- ⬜ Chester
- ⬜ Loch Ness

### Mûre-framboise (Tayberry / Loganberry) — *Rubus* hybrides ⬜ `PFR-009`

### Baie de mai (camérisier) — *Lonicera caerulea* ⬜ `PFR-010`

### Argousier — *Hippophae rhamnoides* ⬜ `PFR-011`

### Goji (baie) — *Lycium barbarum* ⬜ `PFR-012`

### Amélanchier — *Amelanchier* spp. ⬜ `PFR-013`

### Raisin de table — *Vitis vinifera* (Vitaceae) ⬜ `PFR-014` (ou fruit)
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

### Œillet d'Inde / Rose d'Inde — *Tagetes* spp. (Asteraceae) ⬜ `FLE-003`
- ⬜ Œillet d'Inde (*T. patula*)
- ⬜ Rose d'Inde (*T. erecta*)
- ⬜ Tagète minute (*T. minuta*, anti-nématodes)

### Bourrache — *Borago officinalis* (Boraginaceae) ⬜ `FLE-004`

### Cosmos — *Cosmos bipinnatus* (Asteraceae) ⬜ `FLE-005`

### Tournesol — *Helianthus annuus* (Asteraceae) ⬜ `FLE-006`

### Souci / Zinnia — *Zinnia elegans* (Asteraceae) ⬜ `FLE-007`

### Phacélie — *Phacelia tanacetifolia* (Boraginaceae) ⬜ `FLE-008`
> (Aussi engrais vert / mellifère — voir § Engrais verts.)

### Lavande — *Lavandula* spp. (Lamiaceae) ⬜ `FLE-009`

---

# 🌾 CÉRÉALES (`CER`)

### Blé — *Triticum aestivum* (Poaceae) ⬜ `CER-001`
### Maïs (grain / pop-corn) — *Zea mays* ⬜ `CER-002`
### Orge — *Hordeum vulgare* ⬜ `CER-003`
### Avoine — *Avena sativa* ⬜ `CER-004`
### Seigle — *Secale cereale* ⬜ `CER-005`
### Sarrasin (blé noir) — *Fagopyrum esculentum* (Polygonaceae) ⬜ `CER-006`
### Millet — *Panicum miliaceum* ⬜ `CER-007`
### Épeautre — *Triticum spelta* ⬜ `CER-008`

---

# 🌱 ENGRAIS VERTS (`ENG`)

### Moutarde blanche — *Sinapis alba* (Brassicaceae) ✅ `ENG-001`
> Espèce mère créée (lot « fleurs compagnes »). ⚠ Brassicacée : partage
> maladies/ravageurs avec les choux (défavorable en rotation/voisinage).
### Phacélie — *Phacelia tanacetifolia* ⬜ `ENG-002`
### Trèfle incarnat — *Trifolium incarnatum* (Fabaceae) ⬜ `ENG-003`
### Trèfle blanc — *Trifolium repens* ⬜ `ENG-004`
### Vesce commune — *Vicia sativa* (Fabaceae) ⬜ `ENG-005`
### Luzerne — *Medicago sativa* (Fabaceae) ⬜ `ENG-006`
### Sarrasin (couvre-sol) — *Fagopyrum esculentum* ⬜ `ENG-007`
### Seigle fourrager — *Secale cereale* ⬜ `ENG-008`
### Féverole — *Vicia faba* var. *minor* ⬜ `ENG-009`
### Lupin — *Lupinus* spp. (Fabaceae) ⬜ `ENG-010`
### Radis fourrager — *Raphanus sativus* var. *oleiformis* ⬜ `ENG-011`
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
