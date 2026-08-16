# FICHES À CRÉER — Base de connaissances « plantes potagères »

> Feuille de route de contenu pour la base YAML (`assets/fiches_plantes/`).
> Organisation conforme à **ADR-0005** : `Famille botanique → Espèce (fiche mère)
> → Variétés (fiches filles)`. On crée les fiches **par batchs** en repartant de
> ce document.
>
> **Objectif de contenu assumé : le maximum de fiches, mères ET filles.** Les
> listes de variétés ci-dessous ne sont donc pas des « sélections » mais des
> **files d'attente de création**, organisées par sous-groupe quand l'espèce est
> très cultivarisée. Elles restent extensibles : ajouter une ligne ⬜ dès qu'une
> variété notable est identifiée.

## État au 2026-08-16 (après le lot 13 — piments)

**375 fiches** en base : **100 espèces mères + 275 variétés**, 0 doublon,
0 référence d'association orpheline, registre et fichiers concordants.

| Catégorie | Mères ✅ | Variétés ✅ | Total ✅ | Mères ⬜ | Variétés ⬜ |
|---|---|---|---|---|---|
| 🥕 Légumes (`LEG`) | **52** | **213** | **265** | 54 | 480 |
| 🌿 Aromatiques (`ARO`) | **19** | **35** | **54** | 22 | 43 |
| 🍎 Fruits (`FRU`) | 8 | 8 | 16 | 19 | 115 |
| 🌱 Engrais verts (`ENG`) | 8 | 8 | 16 | 11 | 19 |
| 🍓 Petits fruits (`PFR`) | 5 | 5 | 10 | 10 | 69 |
| 🌾 Céréales (`CER`) | 4 | 4 | 8 | 6 | 12 |
| 🌸 Fleurs (`FLE`) | 4 | 2 | 6 | 17 | 35 |
| **Total** | **100** | **275** | **375** | **139** | **773** |

Soit une **cible de 1 287 fiches** (239 mères + 1 048 variétés) telle que ce
document la décrit aujourd'hui — les listes 🔡 restant ouvertes, le total réel
sera plus élevé. **La base est à ~29 % de la feuille de route.**

**Historique.** Les lots 1→11 (par famille botanique) ont été fusionnés le
2026-07-18 avec un second effort de contenu mené en parallèle sur `main`
(fruits/arbres, céréales, engrais verts, fleurs compagnes) — commit `b165672`.
Ce document avait été perdu lors de cette fusion et **remis à niveau le
2026-08-16** contre `_schema/id_registry.yaml`, qui reste la source de vérité
des IDs.

**Lot 12 — aromatiques (2026-08-16)** : 38 fiches, la catégorie passe de 7 à
19 mères. Créées — 12 mères (romarin, sauge officinale, origan, marjolaine,
mélisse, sarriette des jardins, sarriette vivace, hysope, estragon,
laurier-sauce, cerfeuil, livèche) et 26 variétés, dont les **8 premières
variétés de basilic** (la mère 🔡 n'en avait aucune), 4 menthes, 2 thyms,
2 aneths et les filles des nouvelles mères.

**Lot 13 — piments (2026-08-16)** : 25 fiches appliquant l'arbitrage « une mère
par espèce botanique » — `LEG-049` *C. annuum* (10 variétés), `LEG-050`
*C. chinense* (6), `LEG-051` *C. frutescens* (2), `LEG-052` *C. baccatum* (3).
Le poivron doux `LEG-019` reste distinct.

## Légende

| Marque | Signification |
|--------|---------------|
| ✅ | Fiche **déjà créée** (ID indiqué) |
| ⬜ | Fiche **à créer** |
| 🔡 | Espèce à **très grand nombre de cultivars** — liste organisée par sous-groupe, à compléter en continu |

## Conventions de nommage (rappel ADR-0005)

- Espèce : `[CAT3]-[NUM3]` — ex. `LEG-024`
- Variété : `[CAT3]-[NUM3]-V[NUM3]` — ex. `LEG-024-V001`
- Codes catégorie : `LEG`=légume · `ARO`=aromatique · `FRU`=fruit ·
  `PFR`=petit-fruit · `FLE`=fleur · `CER`=céréale · `ENG`=engrais-vert
- Numéros **séquentiels et immuables**, jamais réattribués.
- La **famille** doit exister dans `_familles/*.yaml` (sinon la créer d'abord).

> ⚠️ **Véracité du contenu.** Les noms de cultivars listés ici sont des noms
> réellement diffusés (catalogues potagers francophones, semences paysannes).
> Les **données chiffrées** de chaque fiche (dates, espacements, températures,
> volumes d'arrosage) doivent être **sourcées à la création** — jamais déduites
> de la liste ni inventées.

---

# 🥕 LÉGUMES (`LEG`)

## Solanaceae — Solanacées

### Tomate — *Solanum lycopersicum* ✅ `LEG-001` 🔡

Créées : ✅ `V001` Cœur de Bœuf · ✅ `V002` Cerise · ✅ `V003` San Marzano ·
✅ `V004` Noire de Crimée · ✅ `V005` Andine Cornue · ✅ `V006` Marmande ·
✅ `V007` Ananas · ✅ `V008` Rose de Berne · ✅ `V009` Montfavet ·
✅ `V010` Roma · ✅ `V011` Tigerella · ✅ `V012` Green Zebra ·
✅ `V013` Black Cherry · ✅ `V014` Beefsteak · ✅ `V015` Saint-Pierre ·
✅ `V016` Costoluto Fiorentino · ✅ `V017` Brandywine ·
✅ `V018` Gardener's Delight · ✅ `V019` Sungold · ✅ `V020` Téton de Vénus ·
✅ `V021` Poire Jaune · ✅ `V022` Fantasio · ✅ `V023` Cœur de Pigeon

**À créer — précoces & climats frais**
- ⬜ Stupice
- ⬜ Sub-Arctic Plenty
- ⬜ Glacier
- ⬜ Précoce de Quimper
- ⬜ Reine des Hâtives
- ⬜ Bloody Butcher

**À créer — cerises & cocktail**
- ⬜ Sweet 100 / Supersweet 100
- ⬜ Matt's Wild Cherry
- ⬜ Ildi (grappe jaune)
- ⬜ Chocolate Cherry
- ⬜ Black Zebra Cherry
- ⬜ Green Grape
- ⬜ Peacevine
- ⬜ Gold Nugget
- ⬜ Yellow Submarine (jaune poire)
- ⬜ Cerise Rouge Grappe

**À créer — charnues / à farcir / beefsteak**
- ⬜ Cornue des Andes (si distinguée de l'Andine)
- ⬜ Cœur de Bœuf Orange
- ⬜ Cœur de Bœuf Blanc / Green
- ⬜ Mortgage Lifter
- ⬜ German Johnson
- ⬜ Big Rainbow
- ⬜ Cuor di Bue
- ⬜ Poivron (tomate à farcir)
- ⬜ Téton de Vénus jaune

**À créer — anciennes colorées**
- ⬜ Black Krim
- ⬜ Cherokee Purple
- ⬜ Paul Robeson
- ⬜ Nyagous
- ⬜ Purple Calabash
- ⬜ Aunt Ruby's German Green
- ⬜ Evergreen
- ⬜ White Beauty
- ⬜ Dr Wyche's Yellow
- ⬜ Kellogg's Breakfast
- ⬜ Amana Orange
- ⬜ Persimmon
- ⬜ Ananas Noire
- ⬜ Striped Roman
- ⬜ Red Zebra
- ⬜ Indigo Rose

**À créer — conserve / séchage**
- ⬜ Amish Paste
- ⬜ Opalka
- ⬜ Principe Borghese
- ⬜ Jersey Devil
- ⬜ Cornabel (F1)

**À créer — hybrides résistants (jardin d'agrément / débutants)**
- ⬜ Maestria (F1)
- ⬜ Pyros (F1)
- ⬜ Ferline (F1)
- ⬜ Cobra (F1)

### Aubergine — *Solanum melongena* ✅ `LEG-002` 🔡
Créées : ✅ `V001` Violette de Florence · ✅ `V002` de Barbentane ·
✅ `V003` Black Beauty · ✅ `V004` Listada de Gandia · ✅ `V005` Ronde de Valence
- ⬜ Longue Violette de Barbentane
- ⬜ Rosa Bianca
- ⬜ Blanche Dourga
- ⬜ White Egg (œuf blanc)
- ⬜ Thaï verte longue
- ⬜ Petit Ronde de Chine
- ⬜ Zebrina / panachée
- ⬜ Bonica (F1)
- ⬜ Slim Jim (à petits fruits, balcon)
- ⬜ Turkish Orange / Ronde orange
- ⬜ Ping Tung Long

### Poivron — *Capsicum annuum* ✅ `LEG-019` 🔡
Créées : ✅ `V001` Corno di Toro · ✅ `V002` California Wonder ·
✅ `V003` Marconi · ✅ `V004` Doux d'Espagne · ✅ `V005` Yolo Wonder
- ⬜ Lamuyo
- ⬜ Sucette de Provence
- ⬜ Doux des Landes
- ⬜ Doux d'Italie
- ⬜ Quadrato d'Asti Giallo
- ⬜ Quadrato d'Asti Rosso
- ⬜ Cuneo Giallo
- ⬜ Chocolate Beauty
- ⬜ Poivron d'Antibes
- ⬜ Nocera Giallo
- ⬜ Topepo Rosso (tomate-poivron)

### Piment — *Capsicum annuum* ✅ `LEG-049` 🔡
> ✅ **Arbitrage tranché (2026-08-16), appliqué au lot 13** : **une fiche mère par
> espèce botanique**. Le poivron doux (`LEG-019`) reste une mère distincte bien
> qu'également *C. annuum* : usage culinaire et conduite assez éloignés pour que
> le jardinier les cherche séparément.

Créées (lot 13) : ✅ `V001` d'Espelette (Gorria) · ✅ `V002` de Cayenne ·
✅ `V003` Jalapeño · ✅ `V004` Serrano · ✅ `V005` Poblano (ancho séché) ·
✅ `V006` Padrón · ✅ `V007` de Bresse · ✅ `V008` Piquillo ·
✅ `V009` Hungarian Hot Wax · ✅ `V010` Chiltepin (var. *glabriusculum*)
- ⬜ Corne de Bouc
- ⬜ Anaheim / New Mexico
- ⬜ Guajillo (mirasol séché)
- ⬜ Pasilla / Chilaca
- ⬜ Piment de Rocamadour
- ⬜ Piment Doux Long des Landes
- ⬜ Numex Big Jim
- ⬜ Piment Long de Nice

### Piment habanero — *Capsicum chinense* ✅ `LEG-050` 🔡
Créées (lot 13) : ✅ `V001` Habanero orange · ✅ `V002` Habanero chocolat ·
✅ `V003` Scotch Bonnet · ✅ `V004` Fatalii · ✅ `V005` Aji Dulce (sans piquant) ·
✅ `V006` Carolina Reaper
- ⬜ Habanero blanc (Peruvian White)
- ⬜ Habanero Red Savina
- ⬜ Trinidad Scorpion
- ⬜ Bhut Jolokia (Ghost pepper)
- ⬜ Madame Jeanette
- ⬜ Datil
- ⬜ 7 Pot Douglah

### Piment oiseau — *Capsicum frutescens* ✅ `LEG-051`
Créées (lot 13) : ✅ `V001` Tabasco · ✅ `V002` Malagueta
- ⬜ Piment oiseau de Cayenne
- ⬜ Siling Labuyo
- ⬜ Kambuzi

### Piment aji — *Capsicum baccatum* ✅ `LEG-052`
Créées (lot 13) : ✅ `V001` Aji Amarillo · ✅ `V002` Aji Limón (Lemon Drop) ·
✅ `V003` Bishop's Crown
- ⬜ Aji Panca
- ⬜ Aji Cristal
- ⬜ Brazilian Starfish
- ⬜ Peppadew / Juanita

### Piment rocoto — *Capsicum pubescens* ⬜ *(5e espèce cultivée, mère à créer)*
> Seule espèce du genre à graines noires et à fleurs violettes, et la plus
> tolérante au froid (cultivée jusqu'à 3 000 m dans les Andes) — d'où son
> intérêt réel sous climat tempéré frais.
- ⬜ Rocoto rouge
- ⬜ Rocoto Manzano jaune
- ⬜ Locoto bolivien

### Pomme de terre — *Solanum tuberosum* ✅ `LEG-020` 🔡
Créées : ✅ `V001` Charlotte · ✅ `V002` Bintje · ✅ `V003` Ratte ·
✅ `V004` Vitelotte · ✅ `V005` Désirée · ✅ `V006` Belle de Fontenay

**À créer — chair ferme**
- ⬜ Amandine
- ⬜ Nicola
- ⬜ Roseval
- ⬜ Pompadour
- ⬜ Chérie
- ⬜ Annabelle
- ⬜ BF15
- ⬜ Corne de Gatte

**À créer — chair tendre / polyvalente**
- ⬜ Monalisa
- ⬜ Agata
- ⬜ Samba
- ⬜ Rosabelle
- ⬜ Naturella

**À créer — chair farineuse / four & purée**
- ⬜ Manon
- ⬜ Marabel
- ⬜ Caesar
- ⬜ Agria
- ⬜ Bleue d'Artois

**À créer — anciennes & colorées**
- ⬜ Rouge des Flandres
- ⬜ Blue Congo
- ⬜ Highland Burgundy Red
- ⬜ Institut de Beauvais
- ⬜ Bleu de La Manche

**À créer — résistantes au mildiou (variétés robustes)**
- ⬜ Sarpo Mira
- ⬜ Bionica
- ⬜ Carolus
- ⬜ Alouette

### Physalis / Coqueret du Pérou — *Physalis peruviana* ⬜ *(id à attribuer)*
- ⬜ Goldie
- ⬜ Schönbrunner Gold
- ⬜ Giant Poha Berry
> (L'amour-en-cage ornemental *P. alkekengi* → voir § Fleurs.)

### Tomatillo — *Physalis philadelphica* ⬜ *(id à attribuer)*
- ⬜ Verde / Toma Verde
- ⬜ Purple / De Milpa
- ⬜ Grande Rio Verde

### Morelle de Balbis (litchi tomate) — *Solanum sisymbriifolium* ⬜ *(id à attribuer)*

### Poire-melon / Pépino — *Solanum muricatum* ⬜ *(id à attribuer)*

---

## Cucurbitaceae — Cucurbitacées

### Courgette — *Cucurbita pepo* ✅ `LEG-011` 🔡
Créées : ✅ `V001` Black Beauty · ✅ `V002` Ronde de Nice · ✅ `V003` Gold Rush ·
✅ `V004` Verte des Maraîchers · ✅ `V005` Costata Romanesca
- ⬜ Grisette de Provence
- ⬜ Blanche de Virginie
- ⬜ Tromboncino / courgette-tromba (*C. moschata*)
- ⬜ Ronde de Piacenza
- ⬜ Génovese
- ⬜ Verte non coureuse d'Italie
- ⬜ Diamant (F1)
- ⬜ Nimba
- ⬜ Bianca di Trieste
- ⬜ Coucourzelle

### Courge musquée — *Cucurbita moschata* ✅ `LEG-010`
Créées : ✅ `V001` Butternut Ponca · ✅ `V002` Butternut Waltham ·
✅ `V003` Musquée de Provence · ✅ `V004` Longue de Nice
- ⬜ Sucrine du Berry
- ⬜ Butternut Early Nutter
- ⬜ Musquée de Provence Noire
- ⬜ Pleine de Naples
- ⬜ Seminole Pumpkin
- ⬜ Trombolino d'Albenga

### Potimarron / courge *maxima* — *Cucurbita maxima* ✅ `LEG-021`
Créées : ✅ `V001` Potiron Rouge Vif d'Étampes · ✅ `V002` Red Kuri (Uchiki Kuri) ·
✅ `V003` Bleu de Hongrie · ✅ `V004` Marina di Chioggia
> ⚠️ **Arbitrage encore ouvert** : `V001` est un *potiron* rattaché à une mère
> nommée « Potimarron ». Deux options : (a) renommer la mère en « Courge
> *Cucurbita maxima* », (b) créer une mère « Potiron » distincte. Trancher avant
> le prochain batch cucurbitacées.
- ⬜ Giraumon Turban (Bonnet turc)
- ⬜ Buttercup
- ⬜ Hubbard vert
- ⬜ Hubbard bleu / Blue Ballet
- ⬜ Courge de Siam
- ⬜ Galeux d'Eysines
- ⬜ Jaune Gros de Paris
- ⬜ Atlantic Giant
- ⬜ Rouge Vif d'Étampes (si mère « Potiron » créée)
- ⬜ Sweet Meat
- ⬜ Amande / Amoro
- ⬜ Delica (F1)
- ⬜ Potimarron Solor

### Pâtisson — *Cucurbita pepo* ✅ `LEG-040`
Créées : ✅ `V001` Blanc · ✅ `V002` Panaché Vert et Blanc · ✅ `V003` Jaune
- ⬜ Orange (Sunburst)
- ⬜ Vert foncé
- ⬜ Custard White

### Courge spaghetti & autres *pepo* d'hiver — ⬜ *(id à attribuer)*
- ⬜ Spaghetti végétal (mère probable)
- ⬜ Delicata
- ⬜ Gland / Acorn (Table Queen)
- ⬜ Jack Be Little (mini)
- ⬜ Sweet Dumpling
- ⬜ Pomme d'Or
- ⬜ Citrouille de Halloween (Jack O'Lantern)
- ⬜ Courge éponge / Luffa (*Luffa* spp., mère distincte)

### Concombre — *Cucumis sativus* ✅ `LEG-009` 🔡
Créées : ✅ `V001` Marketmore · ✅ `V002` Vert Long Maraîcher ·
✅ `V003` Blanc Long Parisien · ✅ `V004` Lemon
- ⬜ Le Généreux
- ⬜ Beit Alpha (libanais)
- ⬜ Tanja
- ⬜ Bella (F1)
- ⬜ Crystal Apple
- ⬜ Poona Kheera
- ⬜ Rocky (mini snack)
- ⬜ Chinois Long
- ⬜ De Russie / Russian
- ⬜ Vert Petit de Paris (→ voir cornichon)

### Cornichon — *Cucumis sativus* ⬜ *(id à attribuer)*
> **Arbitrage ouvert** : espèce/type distinct ou variétés du concombre.
> **Recommandation** : fiche mère « Cornichon » distincte (conduite, récolte et
> usage nettement différents) même si botaniquement identique.
- ⬜ Vert Petit de Paris
- ⬜ Fin de Meaux
- ⬜ Vorgebirgstrauben
- ⬜ National
- ⬜ Amorosa (F1)
- ⬜ Cornichon de Bourbonne

### Melon — *Cucumis melo* ✅ `LEG-030` 🔡
Créées : ✅ `V001` Charentais · ✅ `V002` Petit Gris de Rennes ·
✅ `V003` Cantaloup de Bellegarde · ✅ `V004` Sucrin de Tours
- ⬜ Ananas d'Amérique à chair verte
- ⬜ Melon d'eau / de conserve (à confire)
- ⬜ Vert olive d'hiver
- ⬜ Jaune canari
- ⬜ Noir des Carmes
- ⬜ Prescott Fond Blanc
- ⬜ Ogen
- ⬜ Galia
- ⬜ Honeydew / Blanc d'Antibes
- ⬜ Boule d'Or
- ⬜ Banana Melon

### Pastèque — *Citrullus lanatus* ✅ `LEG-041`
Créées : ✅ `V001` Sugar Baby · ✅ `V002` Crimson Sweet · ✅ `V003` Charleston Gray
- ⬜ À confiture (à graines rouges)
- ⬜ Moon and Stars
- ⬜ Blacktail Mountain
- ⬜ Petite Yellow (chair jaune)
- ⬜ Klondike Blue Ribbon
- ⬜ Janosik

### Gourde / Calebasse — *Lagenaria siceraria* ⬜ *(id à attribuer)*
- ⬜ Pèlerine (bouteille)
- ⬜ Massue d'Hercule
- ⬜ Cou-tors
- ⬜ Gourde-calebasse ronde

### Chayotte / Christophine — *Sechium edule* ⬜ *(id à attribuer)*

### Melon amer / Margose — *Momordica charantia* ⬜ *(id à attribuer)*

### Courge cireuse / Bénincasa — *Benincasa hispida* ⬜ *(id à attribuer)*

---

## Brassicaceae — Brassicacées (crucifères)

### Chou brocoli — *Brassica oleracea* var. *italica* ✅ `LEG-006`
Créées : ✅ `V001` Calabrese · ✅ `V002` De Cicco · ✅ `V003` Pourpre du Cap
- ⬜ Vert Calabrais hâtif
- ⬜ Waltham 29
- ⬜ Rudolph (à jets, hivernal)
- ⬜ Brocoli à jets Early Purple Sprouting
- ⬜ Brocoli à jets White Sprouting
- ⬜ Broccolini / Bimi
> Note : le Romanesco est rattaché au chou-fleur (`LEG-008-V004`).

### Chou cabus (pommé) — *Brassica oleracea* var. *capitata* ✅ `LEG-007` 🔡
Créées : ✅ `V001` Rouge (Cabus rouge) · ✅ `V002` Cœur de Bœuf des Vertus ·
✅ `V003` Quintal d'Alsace · ✅ `V004` Nantais hâtif
- ⬜ De Milan de Pontoise (frisé)
- ⬜ Chou de Milan Gros des Vertus
- ⬜ Chou de Milan Aubervilliers
- ⬜ Point de Bruxelles
- ⬜ Précoce de Louviers
- ⬜ Brunswick
- ⬜ Tête de Pierre grosse
- ⬜ Rouge Tête Noire
- ⬜ Blanc de Bonneuil (à choucroute)
- ⬜ Chou de Pontoise

### Chou-fleur — *Brassica oleracea* var. *botrytis* ✅ `LEG-008`
Créées : ✅ `V001` De Bretagne · ✅ `V002` Merveille de Toutes Saisons ·
✅ `V003` Géant d'Automne · ✅ `V004` Chou Romanesco · ✅ `V005` Violet de Sicile
- ⬜ Boule de Neige
- ⬜ Nautilus (F1)
- ⬜ Cheddar (orange)
- ⬜ Graffiti (violet)
- ⬜ Tardif d'Angers
- ⬜ Walcheren Winter

### Chou de Bruxelles — *Brassica oleracea* var. *gemmifera* ✅ `LEG-031`
Créées : ✅ `V001` de Rosny · ✅ `V002` Long Island · ✅ `V003` Groninger
- ⬜ Sanda
- ⬜ Falstaff (rouge)
- ⬜ Nautic (F1)
- ⬜ Demi-Nain de la Halle

### Chou frisé / Kale — *Brassica oleracea* var. *sabellica* ✅ `LEG-032`
Créées : ✅ `V001` Vert Demi-Nain · ✅ `V002` Cavolo Nero · ✅ `V003` Redbor
- ⬜ Rouge de Russie (Red Russian)
- ⬜ Frisé Grand Vert
- ⬜ Kale Westlandse Winter
- ⬜ Chou palmier Nero di Toscana (si distinct du Cavolo Nero)
- ⬜ Chou plume / Kale à moelle
- ⬜ Chou perpétuel Daubenton (bouturé)

### Chou-rave — *Brassica oleracea* var. *gongylodes* ✅ `LEG-036`
Créées : ✅ `V001` Blanc de Vienne · ✅ `V002` Bleu de Vienne · ✅ `V003` Superschmelz
- ⬜ Delicacy Purple
- ⬜ Noriko
- ⬜ Gigante

### Chou pommé de Chine / Pé-tsaï — *Brassica rapa* subsp. *pekinensis* ⬜ *(id à attribuer)*
- ⬜ Michihili
- ⬜ Nagaoka F1
- ⬜ Granaat
- ⬜ Chou de Pékin Bilko

### Pak choï — *Brassica rapa* subsp. *chinensis* ✅ `LEG-038`
Créées : ✅ `V001` de Canton · ✅ `V002` de Shanghai
- ⬜ Joi Choi (F1)
- ⬜ Baby Pak Choï
- ⬜ Tatsoi (rosette)

### Navet — *Brassica rapa* subsp. *rapa* ✅ `LEG-015`
Créées : ✅ `V001` Boule d'Or · ✅ `V002` de Nancy · ✅ `V003` des Vertus Marteau ·
✅ `V004` Milan Rouge
- ⬜ Blanc Globe à collet violet
- ⬜ Jaune Boule d'Or (si distinct)
- ⬜ Noir long d'Alsace
- ⬜ Navet de Croissy
- ⬜ Navet de Pardailhan
- ⬜ Snowball

### Rutabaga — *Brassica napus* var. *napobrassica* ✅ `LEG-037`
Créées : ✅ `V001` Wilhelmsburger · ✅ `V002` à collet rouge
- ⬜ Champion à collet rouge
- ⬜ Best of All
- ⬜ Gowrie

### Radis — *Raphanus sativus* ✅ `LEG-022` 🔡
Créées : ✅ `V001` Cherry Belle · ✅ `V002` de 18 jours · ✅ `V003` National 2 ·
✅ `V004` Flamboyant · ✅ `V005` Glaçon · ✅ `V006` Noir Gros Rond d'Hiver
- ⬜ Rose de Chine
- ⬜ Green Meat / Green Luobo
- ⬜ Daïkon (radis blanc japonais)
- ⬜ Radis Noir Long Maraîcher
- ⬜ Radis Violet de Gournay
- ⬜ Radis Rond Écarlate
- ⬜ Radis Sora
- ⬜ Radis Zlata (jaune)
- ⬜ Radis Rat-tail / à siliques (*R. caudatus*)
- ⬜ Radis Misato Rose (cœur rouge)

### Roquette cultivée — *Eruca vesicaria* ✅ `LEG-035`
- ⬜ Cultivée à large feuille
- ⬜ Roquette Astra
- ⬜ Roquette Rucola Coltivata

### Roquette sauvage — *Diplotaxis tenuifolia* ⬜ *(mère distincte à créer)*
- ⬜ Sauvage vivace
- ⬜ Sylvetta

### Cresson de fontaine — *Nasturtium officinale* ⬜ *(id à attribuer)*
- ⬜ à larges feuilles

### Cresson alénois — *Lepidium sativum* ✅ `LEG-039`
- ⬜ Commun
- ⬜ Frisé / Curled
- ⬜ Cresson à large feuille

### Moutarde brune / de Chine — *Brassica juncea* ⬜ *(id à attribuer)*
- ⬜ Red Giant
- ⬜ Green in the Snow
- ⬜ Moutarde japonaise Osaka Purple
> (La moutarde blanche engrais vert est en `ENG-001`.)

### Mizuna — *Brassica rapa* var. *nipposinica* ⬜ *(id à attribuer)*
- ⬜ Mizuna verte
- ⬜ Mizuna pourpre
- ⬜ Mibuna

### Komatsuna — *Brassica rapa* var. *perviridis* ⬜ *(id à attribuer)*

### Raifort — *Armoracia rusticana* ⬜ *(id à attribuer)*
- ⬜ Commun / de Malines

### Chou marin (crambé) — *Crambe maritima* ⬜ *(id à attribuer)*

### Wasabi — *Eutrema japonicum* ⬜ *(id à attribuer)*

---

## Apiaceae — Apiacées (ombellifères)

### Carotte — *Daucus carota* ✅ `LEG-004` 🔡
Créées : ✅ `V001` Nantaise Améliorée · ✅ `V002` de Colmar à cœur rouge ·
✅ `V003` Touchon · ✅ `V004` Chantenay à cœur rouge · ✅ `V005` Jaune du Doubs ·
✅ `V006` Blanche des Vosges · ✅ `V007` Purple Haze · ✅ `V008` Marché de Paris
- ⬜ de Meaux
- ⬜ Rouge Sang
- ⬜ Berlicum
- ⬜ Danvers
- ⬜ Amsterdam Forcing (primeur)
- ⬜ Küttiger (suisse)
- ⬜ Gniff (bicolore)
- ⬜ Cosmic Purple
- ⬜ Atomic Red
- ⬜ Solar Yellow
- ⬜ Longue Rouge Sang améliorée
- ⬜ Chantenay Rouge Cœur 2 (si distincte)

### Céleri-rave — *Apium graveolens* var. *rapaceum* ✅ `LEG-005`
Créées : ✅ `V001` Brilliant · ✅ `V002` Géant de Prague · ✅ `V003` Monarch
- ⬜ Ibis
- ⬜ Prinz
- ⬜ Alabaster

### Céleri branche — *Apium graveolens* var. *dulce* ✅ `LEG-034`
Créées : ✅ `V001` Vert d'Elne · ✅ `V002` Plein Blanc Pascal · ✅ `V003` Doré Chemin
- ⬜ Tall Utah
- ⬜ Géant Doré Amélioré
- ⬜ Rose de Soissons

### Céleri à couper — *Apium graveolens* var. *secalinum* ⬜ *(id à attribuer)*
- ⬜ Fin Vert de Palluau
- ⬜ Céleri chinois Kintsai

### Panais — *Pastinaca sativa* ✅ `LEG-033`
Créées : ✅ `V001` Demi-Long de Guernesey · ✅ `V002` Tender and True
- ⬜ Half Long White
- ⬜ Hollow Crown
- ⬜ Gladiator (F1)
- ⬜ Rond hâtif

### Fenouil (bulbe) — *Foeniculum vulgare* var. *azoricum* ✅ `LEG-024`
Créées : ✅ `V001` Doux de Florence · ✅ `V002` Zefa Fino · ✅ `V003` Romanesco
- ⬜ Mantovano
- ⬜ Rondo (F1)
- ⬜ Géant de Naples

### Persil-racine — *Petroselinum crispum* var. *tuberosum* ⬜ *(id à attribuer)*
- ⬜ Demi-long
- ⬜ Berlin
> (Le persil aromatique est en `ARO-002`.)

### Chervis — *Sium sisarum* ⬜ *(id à attribuer)*

### Maceron — *Smyrnium olusatrum* ⬜ *(id à attribuer)*

---

## Fabaceae — Fabacées (légumineuses)

### Haricot — *Phaseolus vulgaris* ✅ `LEG-013` 🔡
Créées : ✅ `V001` vert Fin de Bagnols · ✅ `V002` Contender ·
✅ `V003` Beurre de Rocquencourt · ✅ `V004` Blue Lake à rames ·
✅ `V005` Tarbais · ✅ `V006` Coco de Paimpol · ✅ `V007` Flageolet Chevrier ·
✅ `V008` Borlotto Lingot de Rome

**À créer — nains mangetout**
- ⬜ Delinel
- ⬜ Triomphe de Farcy
- ⬜ Purple Teepee (violet)
- ⬜ Rocquencourt beurre nain (si distinct)
- ⬜ Castandet
- ⬜ Processor

**À créer — à rames**
- ⬜ Mangetout à rames Or du Rhin
- ⬜ Roi des Belges
- ⬜ Neckarkönigin
- ⬜ Phénomène à rames
- ⬜ Cobra (F1)

**À créer — à écosser / secs**
- ⬜ Soissons (gros grain blanc)
- ⬜ Coco Blanc Précoce
- ⬜ Lingot du Nord
- ⬜ Michelet à longue cosse
- ⬜ Haricot de Vendée / Mogette
- ⬜ Coco Rose de Prague
- ⬜ Haricot d'Espagne blanc (→ voir mère dédiée)

### Haricot d'Espagne — *Phaseolus coccineus* ⬜ *(id à attribuer)*
- ⬜ à fleurs rouges
- ⬜ Blanc géant / White Emergo
- ⬜ Painted Lady (bicolore)

### Haricot de Lima — *Phaseolus lunatus* ⬜ *(id à attribuer)*

### Haricot kilomètre (dolique asperge) — *Vigna unguiculata* subsp. *sesquipedalis* ⬜ *(id à attribuer)*

### Dolique / Cornille — *Vigna unguiculata* ⬜ *(id à attribuer)*

### Pois — *Pisum sativum* ✅ `LEG-018` 🔡
Créées : ✅ `V001` Mange-tout Carouby de Maussane · ✅ `V002` Petit Provençal ·
✅ `V003` Merveille de Kelvedon · ✅ `V004` Douce Provence ·
✅ `V005` Serpette Guilloteau · ✅ `V006` Corne de Bélier
- ⬜ Roi des Conserves
- ⬜ Nain Très Hâtif d'Annonay
- ⬜ Plein le Panier
- ⬜ Norli (mangetout nain)
- ⬜ Sugar Snap (croquant)
- ⬜ Delikett
- ⬜ Petit Pois Rond Hâtif
- ⬜ Pois à rames Alderman / Téléphone
- ⬜ Pois Capucijner (à fleurs violettes)

### Fève — *Vicia faba* ✅ `LEG-026`
Créées : ✅ `V001` Aguadulce à très longue cosse · ✅ `V002` de Séville ·
✅ `V003` The Sutton
- ⬜ Superaguadulce
- ⬜ Express
- ⬜ Karmazyn (grain rose)
- ⬜ Crimson Flowered (fleur rouge)
- ⬜ Windsor à longue cosse
> (La féverole engrais vert — *V. faba* var. *minor* — reste ⬜, § Engrais verts.)

### Lentille — *Lens culinaris* ⬜ *(id à attribuer)*
- ⬜ Verte du Puy
- ⬜ Blonde de Saint-Flour
- ⬜ Corail (rose)
- ⬜ Beluga (noire)
- ⬜ Lentillon de Champagne

### Pois chiche — *Cicer arietinum* ⬜ *(id à attribuer)*
- ⬜ Kabuli / gros blanc
- ⬜ Desi / brun
- ⬜ Principe

### Soja / edamame — *Glycine max* ⬜ *(id à attribuer)*
- ⬜ Edamame Envy
- ⬜ Chiba Green

### Arachide — *Arachis hypogaea* ⬜ *(id à attribuer)*

---

## Asteraceae — Astéracées (composées)

### Laitue — *Lactuca sativa* ✅ `LEG-014` 🔡
Créées : ✅ `V001` Batavia Rouge Grenobloise · ✅ `V002` Reine de Mai ·
✅ `V003` Grosse Blonde Paresseuse · ✅ `V004` Merveille des Quatre Saisons ·
✅ `V005` Feuille de Chêne · ✅ `V006` Lollo Rossa · ✅ `V007` Sucrine ·
✅ `V008` Romaine Blonde Maraîchère · ✅ `V009` Batavia Blonde de Paris

**À créer — pommées de printemps/été**
- ⬜ Rougette de Montpellier
- ⬜ Gotte Jaune d'Or
- ⬜ Appia
- ⬜ Kagraner Sommer
- ⬜ Attraction

**À créer — pommées d'hiver**
- ⬜ Merveille d'Hiver
- ⬜ Val d'Orge
- ⬜ Passion Blonde d'Hiver
- ⬜ Brune d'Hiver

**À créer — romaines**
- ⬜ Romaine Ballon
- ⬜ Romaine Verte Maraîchère
- ⬜ Craquerelle du Midi
- ⬜ Little Gem

**À créer — à couper / feuille de chêne**
- ⬜ à couper Gloire du Dauphiné
- ⬜ Feuille de Chêne Rouge (Red Salad Bowl)
- ⬜ Lollo Bionda
- ⬜ Cressonnette Marocaine
- ⬜ Radichetta / Catalogna feuille

**À créer — batavias**
- ⬜ Batavia Dorée de Printemps
- ⬜ Batavia Reine des Glaces
- ⬜ Iceberg / Great Lakes

### Scarole & chicorée frisée — *Cichorium endivia* ✅ `LEG-043`
Créées : ✅ `V001` Scarole Cornet d'Anjou · ✅ `V002` Chicorée Frisée de Ruffec ·
✅ `V003` Scarole Géante Maraîchère
- ⬜ Frisée Wallonne
- ⬜ Frisée de Meaux
- ⬜ Frisée Très Fine Maraîchère
- ⬜ Scarole Blonde à Cœur Plein
- ⬜ Scarole Grosse Bouclée

### Chicorée witloof / sauvage — *Cichorium intybus* ✅ `LEG-042`
Créées : ✅ `V001` Pain de Sucre · ✅ `V002` Rouge de Vérone (Trévise) ·
✅ `V003` Chioggia
- ⬜ Witloof (endive / chicon à forcer)
- ⬜ Barbe de Capucin
- ⬜ Sauvage améliorée / à café
- ⬜ Catalogne à couper (Puntarelle)
- ⬜ Trévise Tardive
- ⬜ Castelfranco

### Artichaut — *Cynara cardunculus* var. *scolymus* ✅ `LEG-023`
Créées : ✅ `V001` Vert de Laon · ✅ `V002` Violet de Provence ·
✅ `V003` Camus de Bretagne · ✅ `V004` Blanc Hyérois
- ⬜ Gros Vert de Laon (si distinct)
- ⬜ Violet de Toscane
- ⬜ Romanesco
- ⬜ Imperial Star

### Cardon — *Cynara cardunculus* ⬜ *(id à attribuer)*
- ⬜ de Tours épineux
- ⬜ Plein Blanc Inerme
- ⬜ Argenté de Plainpalais

### Salsifis — *Tragopogon porrifolius* ⬜ *(id à attribuer)*
- ⬜ Blanc géant / Mammouth

### Scorsonère — *Scorzonera hispanica* ⬜ *(id à attribuer)*
- ⬜ Géante Noire de Russie
- ⬜ Duplex

### Topinambour — *Helianthus tuberosus* ✅ `LEG-044`
Créées : ✅ `V001` Fuseau · ✅ `V002` Rouge du Limousin · ✅ `V003` Patate
- ⬜ Violet de Rennes
- ⬜ Blanc commun

### Crosne du Japon — *Stachys affinis* (Lamiaceae) ⬜ *(id à attribuer)*

### Yacon — *Smallanthus sonchifolius* ⬜ *(id à attribuer)*

### Chrysanthème comestible (shungiku) — *Glebionis coronaria* ⬜ *(id à attribuer)*

---

## Amaranthaceae — Amaranthacées (ex-Chénopodiacées)

### Betterave — *Beta vulgaris* ✅ `LEG-003`
Créées : ✅ `V001` Chioggia · ✅ `V002` de Détroit · ✅ `V003` Crapaudine ·
✅ `V004` Burpee's Golden · ✅ `V005` Cylindra · ✅ `V006` Blanche Albina
- ⬜ Plate d'Égypte
- ⬜ Noire d'Égypte
- ⬜ Rouge Globe
- ⬜ Bull's Blood (feuillage pourpre)
- ⬜ Betterave fourragère Géante Blanche

### Bette / Blette (poirée) — *Beta vulgaris* var. *cicla* ✅ `LEG-029`
Créées : ✅ `V001` Verte à cardes blanches · ✅ `V002` Bright Lights ·
✅ `V003` à cardes rouges · ✅ `V004` Blonde à couper
- ⬜ Verte à carde blanche 3 (Lucullus)
- ⬜ Poirée de Nice
- ⬜ Rhubarb Chard
- ⬜ Poirée à couper verte

### Épinard — *Spinacia oleracea* ✅ `LEG-012`
Créées : ✅ `V001` Géant d'Hiver · ✅ `V002` Monstrueux de Viroflay ·
✅ `V003` Matador · ✅ `V004` America
- ⬜ Butterflay
- ⬜ Winter Giant
- ⬜ Symphony (F1)
- ⬜ Palco (F1)
- ⬜ Épinard de Nouvelle-Zélande → mère distincte (voir ci-dessous)

### Arroche — *Atriplex hortensis* ⬜ *(id à attribuer)*
- ⬜ Rouge
- ⬜ Blonde
- ⬜ Verte

### Épinard-fraise — *Chenopodium foliosum* ⬜ *(id à attribuer)*

### Chénopode Bon-Henri — *Blitum bonus-henricus* ⬜ *(id à attribuer)*

### Quinoa → ✅ `CER-003` · Amarante → ✅ `CER-004`
> **Arbitrage tranché** : rattachés à la catégorie *céréales*, pas *légumes*.

---

## Amaryllidaceae — Amaryllidacées (ex-Alliacées)

### Oignon — *Allium cepa* ✅ `LEG-016` 🔡
Créées : ✅ `V001` Rouge de Florence · ✅ `V002` Jaune Paille des Vertus ·
✅ `V003` Blanc de Paris · ✅ `V004` Rouge de Brunswick ·
✅ `V005` doux des Cévennes · ✅ `V006` Rosé de Roscoff · ✅ `V007` Sturon
- ⬜ de Mulhouse (de garde)
- ⬜ Jaune de Stuttgart
- ⬜ Blanc Hâtif de Paris
- ⬜ Rouge Pâle de Niort
- ⬜ Doux de Lézignan
- ⬜ Oignon de Rebouillon
- ⬜ Borettana / Cipollini
- ⬜ Oignon patate (multiplicateur)
- ⬜ Oignon rocambole / d'Égypte (*A. × proliferum*, mère possible)

### Échalote — *Allium cepa* var. *aggregatum* ✅ `LEG-027`
Créées : ✅ `V001` Grise · ✅ `V002` Longue de Jersey · ✅ `V003` Cuisse de Poulet
- ⬜ Jermor
- ⬜ Golden Gourmet
- ⬜ Échalote de Sainte-Anne
- ⬜ Échalion / banane

### Ail — *Allium sativum* ✅ `LEG-025`
Créées : ✅ `V001` Blanc de la Drôme · ✅ `V002` Rose de Lautrec ·
✅ `V003` Violet de Cadours · ✅ `V004` Fructidor
- ⬜ Rouge d'automne
- ⬜ Messidrôme
- ⬜ Thermidrome
- ⬜ Germidour
- ⬜ Printanor
- ⬜ Ail à gros bulbe / Éléphant (*A. ampeloprasum*)
- ⬜ Ail des ours (*A. ursinum*, mère distincte — sauvage/aromatique)

### Poireau — *Allium ampeloprasum* var. *porrum* ✅ `LEG-017`
Créées : ✅ `V001` Bleu de Solaise · ✅ `V002` de Carentan ·
✅ `V003` Monstrueux d'Elbeuf · ✅ `V004` Gros Long d'Été · ✅ `V005` Géant d'Hiver
- ⬜ Malabare
- ⬜ Jaune Gros du Poitou
- ⬜ Électra
- ⬜ Bleu de Solaise Hiver (si distinct)
- ⬜ Poireau perpétuel (*A. ampeloprasum*, mère possible)

### Ciboule / Cive — *Allium fistulosum* ⬜ *(id à attribuer)*
- ⬜ Rouge
- ⬜ Blanche hâtive
- ⬜ Ciboule de Barletta
> (La ciboulette aromatique est en `ARO-003`.)

### Oignon rocambole / d'Égypte — *Allium × proliferum* ⬜ *(id à attribuer)*

---

## Convolvulaceae — Convolvulacées

### Patate douce — *Ipomoea batatas* ✅ `LEG-048`
- ⬜ Beauregard (chair orange)
- ⬜ Évangéline
- ⬜ O'Henry (chair blanche)
- ⬜ Murasaki (peau violette)
- ⬜ Georgia Jet
- ⬜ Bonita

---

## Polygonaceae — Polygonacées

### Oseille — *Rumex acetosa* ✅ `LEG-046`
- ⬜ Large de Belleville
- ⬜ Sanguine (veinée de rouge)
- ⬜ Blonde de Lyon
- ⬜ Petite oseille / des prés (*R. acetosella*, mère possible)
- ⬜ Oseille-épinard (*R. patientia*, mère possible)

### Rhubarbe — *Rheum rhabarbarum* ✅ `LEG-045`
- ⬜ Victoria
- ⬜ Framboozen Rood
- ⬜ Mira / Goliath
- ⬜ Canada Red
- ⬜ Timperley Early

---

## Malvaceae — Malvacées

### Gombo (okra) — *Abelmoschus esculentus* ⬜ *(id à attribuer)*
- ⬜ Clemson Spineless
- ⬜ Rouge de Bourgogne
- ⬜ Emerald

---

## Autres familles — légumes divers

### Mâche — *Valerianella locusta* (Caprifoliaceae) ✅ `LEG-028`
- ⬜ Verte de Cambrai
- ⬜ Coquille de Louviers
- ⬜ Ronde maraîchère
- ⬜ à grosse graine
- ⬜ Verte d'Étampes
- ⬜ Vit / Gala

### Asperge — *Asparagus officinalis* (Asparagaceae) ✅ `LEG-047`
- ⬜ d'Argenteuil hâtive
- ⬜ Violette d'Albenga
- ⬜ Verte Précoce d'Argenteuil
- ⬜ Mary Washington
- ⬜ Gijnlim
- ⬜ Purple Passion

### Pourpier potager — *Portulaca oleracea* (Portulacaceae) ⬜ *(id à attribuer)*
- ⬜ Doré à large feuille
- ⬜ Vert

### Tétragone (épinard de Nouvelle-Zélande) — *Tetragonia tetragonioides* ⬜ *(id à attribuer)*

### Claytone de Cuba (pourpier d'hiver) — *Claytonia perfoliata* ⬜ *(id à attribuer)*

### Ficoïde glaciale — *Mesembryanthemum crystallinum* ⬜ *(id à attribuer)*

### Cresson de Para / brède mafane — *Acmella oleracea* ⬜ *(id à attribuer)*

### Maïs doux → ✅ `CER-001`
> **Arbitrage tranché** : rattaché à la catégorie *céréales*.

### Igname — *Dioscorea* spp. ⬜ *(id à attribuer)*

### Manioc — *Manihot esculenta* ⬜ *(id à attribuer)*

### Taro / Songe — *Colocasia esculenta* ⬜ *(id à attribuer)*

### Capucine tubéreuse — *Tropaeolum tuberosum* ⬜ *(id à attribuer)*

### Oca du Pérou — *Oxalis tuberosa* ⬜ *(id à attribuer)*

### Poire de terre → voir Yacon (§ Astéracées)

---

# 🌿 AROMATIQUES & CONDIMENTAIRES (`ARO`)

> ✅ **Lot 12 livré (2026-08-16)** : la catégorie passe de 7 à **19 mères** et
> de 9 à **35 variétés**. Les basiques manquants (romarin, sauge, origan,
> marjolaine, mélisse, sarriette ×2, hysope, estragon, laurier-sauce, cerfeuil,
> livèche) sont désormais fichés, et le basilic a enfin ses variétés.
> Restent surtout des aromatiques de second rang et les exotiques.

## Lamiaceae — Lamiacées

### Basilic — *Ocimum basilicum* ✅ `ARO-001` 🔡
Créées (lot 12) : ✅ `V001` Grand Vert · ✅ `V002` Genovese ·
✅ `V003` Fin Vert Compact (basilic grec en boule) · ✅ `V004` Pourpre (Dark Opal) ·
✅ `V005` Citron (*O. × africanum*) · ✅ `V006` Cannelle ·
✅ `V007` Thaï (var. *thyrsiflora*) · ✅ `V008` Marseillais (feuille de laitue)
- ⬜ Red Rubin (si distingué du Dark Opal)
- ⬜ Sacré / Tulsi (*O. tenuiflorum*, mère possible)
- ⬜ Basilic perpétuel / Africain (*O.* × hybride)
- ⬜ Basilic Napolitain
- ⬜ Basilic Réglisse

### Menthe — *Mentha* spp. ✅ `ARO-005` (menthe poivrée *M. × piperita*) 🔡
Créées : ✅ `V001` Menthe Verte (*M. spicata*) · ✅ `V002` Marocaine (lot 12) ·
✅ `V003` Bergamote (lot 12) · ✅ `V004` Pomme (*M. suaveolens*, lot 12) ·
✅ `V005` Chocolat (lot 12)
- ⬜ Menthe Gingembre
- ⬜ Menthe Ananas (panachée)
- ⬜ Menthe Fraise
- ⬜ Menthe aquatique (*M. aquatica*)
- ⬜ Menthe Pouliot (*M. pulegium*)
- ⬜ Menthe des champs (*M. arvensis*)

### Thym — *Thymus vulgaris* ✅ `ARO-004`
Créées : ✅ `V001` Thym Citron (*T. × citriodorus*) ·
✅ `V002` Serpolet (*T. serpyllum*, lot 12) · ✅ `V003` Doré (Aureus, lot 12)
- ⬜ Thym commun compact
- ⬜ Thym d'hiver / Faustini
- ⬜ Thym Orange
- ⬜ Thym laineux

### Romarin — *Salvia rosmarinus* ✅ `ARO-008`
Créées (lot 12) : ✅ `V001` Rampant (Prostratus) · ✅ `V002` Miss Jessopp's Upright
- ⬜ Tuscan Blue
- ⬜ Corse / à fleurs blanches
- ⬜ Officinal dressé commun (si distingué de Miss Jessopp's)

### Sauge officinale — *Salvia officinalis* ✅ `ARO-009`
Créées (lot 12) : ✅ `V001` Pourpre (Purpurascens) · ✅ `V002` Tricolore ·
✅ `V003` Dorée (Icterina)
- ⬜ Berggarten (à larges feuilles)
- ⬜ Albiflora (à fleurs blanches)

### Sauge ananas — *Salvia elegans* ⬜ *(id à attribuer)*

### Sauge sclarée — *Salvia sclarea* ⬜ *(id à attribuer)*

### Origan — *Origanum vulgare* ✅ `ARO-010`
Créées (lot 12) : ✅ `V001` Doré (Aureum) · ✅ `V002` Grec (subsp. *hirtum*)
- ⬜ Compact / nain
- ⬜ Origan de Crète (*O. dictamnus*, mère possible)

### Marjolaine — *Origanum majorana* ✅ `ARO-011`
- ⬜ à coquilles (si distinguée du type)

### Mélisse — *Melissa officinalis* ✅ `ARO-012`
Créée (lot 12) : ✅ `V001` Panachée (Aurea)
- ⬜ Quedlinburger (à haute teneur en huile essentielle)

### Sarriette des jardins — *Satureja hortensis* ✅ `ARO-013`

### Sarriette vivace (des montagnes) — *Satureja montana* ✅ `ARO-014`
- ⬜ Naine / compacte

### Hysope — *Hyssopus officinalis* ✅ `ARO-015`
- ⬜ à fleurs roses
- ⬜ à fleurs blanches (Albus)

### Lavande → voir § Fleurs (`FLE`)

### Népéta / herbe à chat — *Nepeta cataria* ⬜ *(id à attribuer)*

### Monarde (thé d'Oswego) — *Monarda didyma* ⬜ *(id à attribuer)*

### Perilla / Shiso — *Perilla frutescens* ⬜ *(id à attribuer)*
- ⬜ Shiso vert
- ⬜ Shiso pourpre

### Agastache anisée — *Agastache foeniculum* ⬜ *(id à attribuer)*

## Apiaceae — Apiacées aromatiques

### Persil — *Petroselinum crispum* ✅ `ARO-002`
Créées : ✅ `V001` Frisé · ✅ `V002` Géant d'Italie · ✅ `V003` Frisé Vert Foncé
- ⬜ Commun 2 (plat)
- ⬜ Mousse Frisée Foncée
- ⬜ Persil à couper Titan

### Coriandre — *Coriandrum sativum* ✅ `ARO-006`
Créées : ✅ `V001` Santos (montaison lente) · ✅ `V002` Commune
- ⬜ Marocaine (à graines)
- ⬜ Calypso
- ⬜ Coriandre vietnamienne (*Persicaria odorata*, mère distincte)

### Aneth — *Anethum graveolens* ✅ `ARO-007`
Créées (lot 12) : ✅ `V001` Bouquet · ✅ `V002` Mammouth
- ⬜ Vierling / Tetra
- ⬜ Dukat

### Cerfeuil — *Anthriscus cerefolium* ✅ `ARO-018`
Créée (lot 12) : ✅ `V001` Frisé (Vertissimo)
- ⬜ Commun à feuille plate (si distingué du type)

### Cerfeuil tubéreux — *Chaerophyllum bulbosum* ⬜ *(id à attribuer)*

### Cumin — *Cuminum cyminum* ⬜ *(id à attribuer)*

### Carvi — *Carum carvi* ⬜ *(id à attribuer)*

### Livèche (ache des montagnes) — *Levisticum officinale* ✅ `ARO-019`

### Anis vert — *Pimpinella anisum* ⬜ *(id à attribuer)*

### Fenouil aromatique — *Foeniculum vulgare* (feuillage) ⬜ *(id à attribuer)*
- ⬜ Bronze (feuillage pourpre)
> (Le fenouil bulbe est en `LEG-024`.)

### Angélique — *Angelica archangelica* ⬜ *(id à attribuer)*

## Autres familles aromatiques

### Ciboulette — *Allium schoenoprasum* ✅ `ARO-003`
Créées : ✅ `V001` Ciboulette ail (*Allium tuberosum*) · ✅ `V002` Commune
- ⬜ Ciboulette à grosses touffes (Staro)
- ⬜ Ciboulette fine de Nice

### Estragon — *Artemisia dracunculus* (Asteraceae) ✅ `ARO-016`
> La mère décrit l'estragon **français** (stérile, bouturé) — le seul
> intéressant en cuisine.
Créée (lot 12) : ✅ `V001` de Russie (subsp. *dracunculoides*, semis)

### Absinthe / Armoise — *Artemisia absinthium* ⬜ *(id à attribuer)*

### Laurier-sauce — *Laurus nobilis* (Lauraceae) ✅ `ARO-017`
- ⬜ Angustifolia (à feuilles étroites)
- ⬜ Aurea (feuillage doré)

### Verveine citronnelle — *Aloysia citrodora* (Verbenaceae) ⬜ *(id à attribuer)*

### Citronnelle — *Cymbopogon citratus* (Poaceae) ⬜ *(id à attribuer)*

### Gingembre — *Zingiber officinale* (Zingiberaceae) ⬜ *(id à attribuer)*

### Curcuma — *Curcuma longa* (Zingiberaceae) ⬜ *(id à attribuer)*

### Stévia — *Stevia rebaudiana* (Asteraceae) ⬜ *(id à attribuer)*

### Camomille romaine — *Chamaemelum nobile* ⬜ *(id à attribuer)*

### Camomille matricaire — *Matricaria chamomilla* ⬜ *(id à attribuer)*

### Aspérule odorante — *Galium odoratum* ⬜ *(id à attribuer)*

### Raifort — ⬜ voir § Légumes / Brassicaceae

---

# 🍎 FRUITS — arbres fruitiers (`FRU`)

> Section issue de l'effort de contenu mené sur `main` (« 4 lots »), intégrée à
> la fusion du 2026-07-18. Chaque espèce n'a **qu'une** variété : la catégorie
> est la plus déséquilibrée de la base au regard du nombre réel de cultivars.

### Pommier — *Malus domestica* (Rosaceae) ✅ `FRU-001` 🔡
Créée : ✅ `V001` Reine des Reinettes
- ⬜ Golden Delicious
- ⬜ Belle de Boskoop
- ⬜ Reinette grise du Canada
- ⬜ Reinette Clochard
- ⬜ Cox's Orange Pippin
- ⬜ Granny Smith
- ⬜ Calville Blanc d'Hiver
- ⬜ Chantecler
- ⬜ Elstar
- ⬜ Gala
- ⬜ Jonagold
- ⬜ Melrose
- ⬜ Patte de Loup
- ⬜ Api étoilé
- ⬜ Court-Pendu Gris
- ⬜ Transparente de Croncels
- ⬜ Pomme à cidre Binet Rouge
- ⬜ Pomme à cidre Douce Moën

### Poirier — *Pyrus communis* (Rosaceae) ✅ `FRU-002` 🔡
Créée : ✅ `V001` Conférence
- ⬜ Williams
- ⬜ Doyenné du Comice
- ⬜ Beurré Hardy
- ⬜ Louise Bonne d'Avranches
- ⬜ Guyot
- ⬜ Passe-Crassane
- ⬜ Curé / Belle Angevine
- ⬜ Général Leclerc
- ⬜ Beurré Giffard
- ⬜ Poire à poiré Plant de Blanc

### Cerisier — *Prunus avium* (Rosaceae) ✅ `FRU-003`
Créée : ✅ `V001` Bigarreau Burlat
- ⬜ Napoléon
- ⬜ Reverchon
- ⬜ Summit
- ⬜ Van
- ⬜ Hedelfingen
- ⬜ Cœur de Pigeon
- ⬜ Bigarreau Noir de Meched

### Griottier — *Prunus cerasus* ⬜ *(mère distincte à créer)*
- ⬜ Montmorency
- ⬜ Griotte du Nord
- ⬜ Morello / Anglaise Hâtive

### Prunier — *Prunus domestica* (Rosaceae) ✅ `FRU-004` 🔡
Créée : ✅ `V001` Reine-Claude dorée
- ⬜ Mirabelle de Nancy
- ⬜ Mirabelle de Metz
- ⬜ Quetsche d'Alsace
- ⬜ Président
- ⬜ Reine-Claude d'Oullins
- ⬜ Reine-Claude de Bavay
- ⬜ Sainte-Catherine
- ⬜ Prune d'Ente (pruneau d'Agen)
- ⬜ Stanley

### Pêcher — *Prunus persica* (Rosaceae) ✅ `FRU-005`
Créée : ✅ `V001` Reine des vergers
- ⬜ Sanguine de Savoie
- ⬜ Pêcher de vigne
- ⬜ Amsden
- ⬜ Redhaven
- ⬜ Nectarine Fantasia (var. *nucipersica*)
- ⬜ Nectarine Nectarose
- ⬜ Pêche plate / Donut

### Abricotier — *Prunus armeniaca* ⬜ *(id à attribuer)*
- ⬜ Bergeron
- ⬜ Polonais / Orangé de Provence
- ⬜ Rouge du Roussillon
- ⬜ Luizet
- ⬜ Bergarouge

### Figuier — *Ficus carica* (Moraceae) ✅ `FRU-006`
Créée : ✅ `V001` Violette de Bordeaux
- ⬜ Goutte d'Or
- ⬜ Madeleine des Deux Saisons
- ⬜ Ronde de Bordeaux
- ⬜ Dalmatie
- ⬜ Col de Dame
- ⬜ Brown Turkey
- ⬜ Noire de Caromb

### Noisetier — *Corylus avellana* (Betulaceae) ✅ `FRU-007`
Créée : ✅ `V001` Fertile de Coutard
- ⬜ Merveille de Bollwiller
- ⬜ Longue d'Espagne
- ⬜ Butler
- ⬜ Ennis
- ⬜ Noisetier pourpre (Purpurea)

### Vigne (raisin de table) — *Vitis vinifera* (Vitaceae) ✅ `FRU-008` 🔡
> **Arbitrage tranché** : le raisin de table est un *fruit*, pas un petit-fruit.
Créée : ✅ `V001` Chasselas doré
- ⬜ Muscat de Hambourg
- ⬜ Cardinal
- ⬜ Italia
- ⬜ Danlas
- ⬜ Alphonse Lavallée
- ⬜ Perlette (sans pépins)
- ⬜ Centennial Seedless
- ⬜ Isabelle (raisin de treille)

### Cognassier — *Cydonia oblonga* ⬜ *(id à attribuer)*
- ⬜ Champion
- ⬜ Vranja
- ⬜ du Portugal

### Néflier commun — *Mespilus germanica* ⬜ *(id à attribuer)*
- ⬜ à gros fruits de Nottingham

### Néflier du Japon (bibassier) — *Eriobotrya japonica* ⬜ *(id à attribuer)*

### Kaki / plaqueminier — *Diospyros kaki* (Ebenaceae) ⬜ *(famille déjà présente)*
- ⬜ Fuyu
- ⬜ Muscat / Kaki-pomme
- ⬜ Rojo Brillante

### Noyer — *Juglans regia* (Juglandaceae) ⬜ *(famille déjà présente)*
- ⬜ Franquette
- ⬜ Marbot
- ⬜ Lara
- ⬜ Parisienne
- ⬜ Corne du Périgord

### Châtaignier — *Castanea sativa* (Fagaceae) ⬜ *(famille déjà présente)*
- ⬜ Marigoule
- ⬜ Bouche de Bétizac
- ⬜ Belle Épine

### Amandier — *Prunus dulcis* ⬜ *(id à attribuer)*
- ⬜ Ferragnès
- ⬜ Princesse (à coque tendre)

### Kiwi / actinidia — *Actinidia deliciosa* (Actinidiaceae) ⬜ *(famille déjà présente)*
- ⬜ Hayward (femelle)
- ⬜ Tomuri (mâle pollinisateur)
- ⬜ Jenny (autofertile)

### Kiwaï — *Actinidia arguta* ⬜ *(id à attribuer)*
- ⬜ Issai (autofertile)
- ⬜ Weiki

### Sureau noir — *Sambucus nigra* (Adoxaceae) ⬜ *(famille déjà présente)*
- ⬜ Haschberg
- ⬜ Sampo

### Mûrier (à fruits) — *Morus nigra* / *M. alba* (Moraceae) ⬜ *(id à attribuer)*

### Grenadier — *Punica granatum* (Lythraceae) ⬜ *(famille déjà présente)*
- ⬜ Provence / Fina Tendral
- ⬜ Wonderful

### Olivier — *Olea europaea* (Oleaceae) ⬜ *(famille déjà présente)*
- ⬜ Picholine
- ⬜ Aglandau
- ⬜ Tanche (Nyons)
- ⬜ Lucques

### Citronnier — *Citrus limon* (Rutaceae) ⬜ *(famille déjà présente)*
- ⬜ Quatre Saisons
- ⬜ Meyer

### Oranger / Mandarinier / Kumquat — *Citrus* spp. ⬜ *(mères à créer)*
- ⬜ Oranger doux (*C. sinensis*)
- ⬜ Mandarinier / Clémentinier (*C. reticulata*)
- ⬜ Kumquat (*C. japonica*)
- ⬜ Calamondin

### Asiminier (paw-paw) — *Asimina triloba* ⬜ *(id à attribuer)*

### Arbousier — *Arbutus unedo* (Ericaceae) ⬜ *(famille déjà présente)*

---

# 🍓 PETITS FRUITS (`PFR`)

> Chaque espèce n'a **qu'une** variété — catégorie à étoffer en priorité après
> les aromatiques.

### Fraisier — *Fragaria × ananassa* ✅ `PFR-001` 🔡
Créée : ✅ `V001` Gariguette

**À créer — non remontantes**
- ⬜ Ciflorette
- ⬜ Charlotte
- ⬜ Cireine
- ⬜ Darselect
- ⬜ Sengana
- ⬜ Manille
- ⬜ Elsanta

**À créer — remontantes**
- ⬜ Mara des Bois
- ⬜ Maestro
- ⬜ Charlotte remontante (si distincte)
- ⬜ Cijosée
- ⬜ Anabelle

**À créer — fraisiers des bois (*Fragaria vesca*, mère possible distincte)**
- ⬜ Fraisier des bois commun
- ⬜ Reine des Vallées
- ⬜ Alexandria
- ⬜ Fraisier des bois blanc (Blanche Améliorée)

### Framboisier — *Rubus idaeus* ✅ `PFR-002` 🔡
Créée : ✅ `V001` Heritage (remontant)
- ⬜ Meeker (non remontant)
- ⬜ Malling Promise
- ⬜ Zeva
- ⬜ Willamette
- ⬜ Fall Gold (jaune)
- ⬜ Sumo 2
- ⬜ Blissy
- ⬜ Tulameen
- ⬜ Versailles

### Groseillier rouge / blanc — *Ribes rubrum* ✅ `PFR-003`
Créée : ✅ `V001` Jonkheer Van Tets (rouge)
- ⬜ Versaillaise Rouge
- ⬜ Blanche de Versailles / Blanka
- ⬜ Rovada
- ⬜ Junifer
- ⬜ Rolan
- ⬜ Gloire des Sablons (rose)

### Cassis — *Ribes nigrum* ✅ `PFR-004`
Créée : ✅ `V001` Noir de Bourgogne
- ⬜ Andega
- ⬜ Ben Sarek
- ⬜ Titania
- ⬜ Blackdown
- ⬜ Géant de Boskoop

### Myrtille — *Vaccinium corymbosum* ✅ `PFR-005`
Créée : ✅ `V001` Bluecrop
- ⬜ Duke
- ⬜ Bluetta
- ⬜ Patriot
- ⬜ Chandler
- ⬜ Elliott
- ⬜ Berkeley
- ⬜ Myrtille sauvage / airelle (*V. myrtillus*, mère possible)
- ⬜ Airelle rouge (*V. vitis-idaea*, mère possible)
- ⬜ Canneberge (*V. macrocarpon*, mère possible)

### Groseillier à maquereau — *Ribes uva-crispa* ⬜ *(id à attribuer)*
- ⬜ Invicta
- ⬜ Captivator (sans épines)
- ⬜ Hinnonmäki Rouge
- ⬜ Hinnonmäki Jaune
- ⬜ Whinham's Industry

### Casseille (cassis × groseille) — *Ribes × nidigrolaria* ⬜ *(id à attribuer)*
- ⬜ Josta

### Mûrier ronce — *Rubus fruticosus* ⬜ *(id à attribuer)*
- ⬜ Thornless Evergreen (sans épines)
- ⬜ Chester
- ⬜ Loch Ness
- ⬜ Navaho
- ⬜ Triple Crown

### Mûre-framboise — *Rubus* hybrides ⬜ *(id à attribuer)*
- ⬜ Tayberry
- ⬜ Loganberry
- ⬜ Boysenberry

### Baie de mai (camérisier) — *Lonicera caerulea* (Caprifoliaceae) ⬜ *(famille déjà présente)*
- ⬜ Wojtek
- ⬜ Duet / Kalinka

### Argousier — *Hippophae rhamnoides* (Elaeagnaceae) ⬜ *(famille déjà présente)*
- ⬜ Leikora (femelle)
- ⬜ Pollmix (mâle)

### Goji — *Lycium barbarum* (Solanaceae) ⬜ *(id à attribuer)*
- ⬜ Big Lifeberry
- ⬜ Sweet Lifeberry

### Amélanchier — *Amelanchier* spp. (Rosaceae) ⬜ *(id à attribuer)*
- ⬜ *A. alnifolia* Smoky
- ⬜ *A. lamarckii*

### Aronia — *Aronia melanocarpa* (Rosaceae) ⬜ *(id à attribuer)*
- ⬜ Viking
- ⬜ Nero

### Cornouiller mâle — *Cornus mas* ⬜ *(id à attribuer)*

### Physalis → voir § Légumes / Solanacées

---

# 🌸 FLEURS COMESTIBLES / COMPAGNES (`FLE`)

> Utiles au potager (compagnonnage, pollinisateurs, plantes-pièges).
> Toutes les fleurs citées en associations ont désormais leur fiche mère.

### Capucine — *Tropaeolum majus* (Tropaeolaceae) ✅ `FLE-001`
- ⬜ Grande naine (Tom Pouce)
- ⬜ Grimpante
- ⬜ Alaska (feuillage panaché)
- ⬜ Empress of India
- ⬜ Capucine tubéreuse (*T. tuberosum*) → voir § Légumes

### Souci — *Calendula officinalis* (Asteraceae) ✅ `FLE-002`
- ⬜ Orange King
- ⬜ Nain double
- ⬜ Pacific Beauty
- ⬜ Indian Prince

### Œillet d'Inde — *Tagetes patula* (Asteraceae) ✅ `FLE-003`
Créée : ✅ `V001` Petite Orange
- ⬜ Nain Double Rouge
- ⬜ Naughty Marietta
- ⬜ Petite Yellow

### Rose d'Inde — *Tagetes erecta* ⬜ *(mère distincte à créer)*
- ⬜ Géante Jaune d'Or
- ⬜ Crackerjack

### Tagète minute (anti-nématodes) — *Tagetes minuta* ⬜ *(id à attribuer)*

### Bourrache — *Borago officinalis* (Boraginaceae) ✅ `FLE-004`
Créée : ✅ `V001` Bourrache blanche 'Alba'
- ⬜ Bourrache bleue commune (si distinguée de la mère)

### Cosmos — *Cosmos bipinnatus* (Asteraceae) ⬜ *(id à attribuer)*
- ⬜ Sensation
- ⬜ Purity (blanc)
- ⬜ Cosmos sulphureus (mère possible)

### Tournesol — *Helianthus annuus* (Asteraceae) ⬜ *(id à attribuer)*
- ⬜ Géant de Russie
- ⬜ Velvet Queen
- ⬜ Nain à petites fleurs

### Zinnia — *Zinnia elegans* (Asteraceae) ⬜ *(id à attribuer)*
- ⬜ Géant à fleurs de dahlia
- ⬜ Lilliput

### Lavande — *Lavandula angustifolia* (Lamiaceae) ⬜ *(id à attribuer)*
- ⬜ Hidcote
- ⬜ Munstead
- ⬜ Lavandin Grosso (*L. × intermedia*, mère possible)
- ⬜ Lavande papillon (*L. stoechas*, mère possible)

### Souci des champs / Nigelle — ⬜ *(mères à créer)*
- ⬜ Nigelle de Damas (*Nigella damascena*, Ranunculaceae)
- ⬜ Nigelle cultivée (*N. sativa*, graines condimentaires)

### Bleuet — *Centaurea cyanus* (Asteraceae) ⬜ *(id à attribuer)*

### Coquelicot / Pavot — *Papaver rhoeas* (Papaveraceae) ⬜ *(famille déjà présente)*
- ⬜ Pavot somnifère (*P. somniferum*, graines de pavot)

### Pensée / Violette — *Viola* spp. (Violaceae) ⬜ *(famille déjà présente)*
- ⬜ Pensée sauvage (*V. tricolor*)
- ⬜ Violette odorante (*V. odorata*)

### Œillet mignardise — *Dianthus* spp. (Caryophyllaceae) ⬜ *(famille déjà présente)*

### Rose trémière — *Alcea rosea* (Malvaceae) ⬜ *(id à attribuer)*

### Mauve — *Malva sylvestris* (Malvaceae) ⬜ *(id à attribuer)*

### Géranium vivace / Pélargonium odorant — (Geraniaceae) ⬜ *(famille déjà présente)*
- ⬜ Pélargonium odorant citronnelle
- ⬜ Pélargonium rosat

### Lin à fleurs — *Linum* spp. (Linaceae) ⬜ *(famille déjà présente)*

### Glaïeul / Safran — (Iridaceae) ⬜ *(famille déjà présente)*
- ⬜ Safran (*Crocus sativus*) — épice, forte valeur potagère

### Amour-en-cage — *Physalis alkekengi* (Solanaceae) ⬜ *(ornemental)*

### Phacélie → ✅ `ENG-002`
> **Arbitrage tranché** : rattachée aux engrais verts (elle reste mellifère).

---

# 🌾 CÉRÉALES (`CER`)

### Maïs doux — *Zea mays* var. *saccharata* (Poaceae) ✅ `CER-001`
Créée : ✅ `V001` Golden Bantam
- ⬜ Country Gentleman
- ⬜ Double Standard (bicolore)
- ⬜ Damaun (population)
- ⬜ Pop-corn / maïs à éclater (mère ou variété — à trancher)
- ⬜ Maïs à polenta / Grand Roux Basque

### Blé tendre — *Triticum aestivum* (Poaceae) ✅ `CER-002`
Créée : ✅ `V001` Rouge de Bordeaux
- ⬜ Barbu du Roussillon
- ⬜ Poulard d'Auvergne
- ⬜ Blé de Redon

### Quinoa — *Chenopodium quinoa* (Amaranthaceae) ✅ `CER-003`
Créée : ✅ `V001` Titicaca
- ⬜ Rainbow / multicolore
- ⬜ Faro

### Amarante — *Amaranthus* spp. (Amaranthaceae) ✅ `CER-004`
Créée : ✅ `V001` Viridis
- ⬜ Amarante queue-de-renard (*A. caudatus*)
- ⬜ Amarante à grains Golden Giant

### Orge — *Hordeum vulgare* ⬜ *(id à attribuer)*
### Épeautre — *Triticum spelta* ⬜ *(id à attribuer)*
### Petit épeautre / Engrain — *Triticum monococcum* ⬜ *(id à attribuer)*
### Millet commun — *Panicum miliaceum* ⬜ *(id à attribuer)*
### Sorgho — *Sorghum bicolor* ⬜ *(id à attribuer)*
### Riz — *Oryza sativa* ⬜ *(id à attribuer)*
### Avoine / Seigle / Sarrasin → ✅ `ENG-008` / `ENG-007` / `ENG-006`
> **Arbitrage tranché** : ces trois espèces sont fichées comme *engrais verts*.
> Si un usage « céréale de consommation » est voulu, créer une fiche `CER`
> distincte plutôt que déplacer l'existante (IDs immuables).

---

# 🌱 ENGRAIS VERTS (`ENG`)

### Moutarde blanche — *Sinapis alba* (Brassicaceae) ✅ `ENG-001`
> ⚠ Brassicacée : partage maladies/ravageurs avec les choux (défavorable en
> rotation/voisinage).
Créée : ✅ `V001` Ludic
- ⬜ Abraham
- ⬜ Sirola (anti-nématodes)

### Phacélie — *Phacelia tanacetifolia* (Boraginaceae) ✅ `ENG-002`
Créée : ✅ `V001` Angelia
- ⬜ Balo
- ⬜ Stala

### Trèfle incarnat — *Trifolium incarnatum* (Fabaceae) ✅ `ENG-003`
Créée : ✅ `V001` Contea
- ⬜ Kardinal

### Luzerne — *Medicago sativa* (Fabaceae) ✅ `ENG-004`
Créée : ✅ `V001` Europe
- ⬜ Luzelle

### Vesce commune — *Vicia sativa* (Fabaceae) ✅ `ENG-005`
Créée : ✅ `V001` Topaze
- ⬜ Vesce velue / d'hiver (*V. villosa*, mère possible)

### Sarrasin — *Fagopyrum esculentum* (Polygonaceae) ✅ `ENG-006`
Créée : ✅ `V001` La Harpe
- ⬜ Billy

### Seigle fourrager — *Secale cereale* (Poaceae) ✅ `ENG-007`
Créée : ✅ `V001` Dukato
- ⬜ Protector

### Avoine — *Avena sativa* (Poaceae) ✅ `ENG-008`
Créée : ✅ `V001` Canyon (avoine de printemps)
- ⬜ Avoine rude / brésilienne (*A. strigosa*, mère possible)
- ⬜ Avoine d'hiver

### Trèfle blanc — *Trifolium repens* ⬜ *(id à attribuer)*
- ⬜ Nain (couvre-sol permanent)
- ⬜ Huia

### Trèfle violet — *Trifolium pratense* ⬜ *(id à attribuer)*

### Féverole — *Vicia faba* var. *minor* ⬜ *(id à attribuer)*
- ⬜ Féverole d'hiver
- ⬜ Féverole de printemps

### Lupin — *Lupinus* spp. (Fabaceae) ⬜ *(id à attribuer)*
- ⬜ Lupin blanc (*L. albus*)
- ⬜ Lupin bleu (*L. angustifolius*)

### Radis fourrager — *Raphanus sativus* var. *oleiformis* ⬜ *(id à attribuer)*
- ⬜ Anti-nématodes (Structurator)

### Ray-grass — *Lolium* spp. (Poaceae) ⬜ *(id à attribuer)*

### Nyger — *Guizotia abyssinica* (Asteraceae) ⬜ *(id à attribuer)*

### Colza fourrager — *Brassica napus* ⬜ *(id à attribuer)*

### Sainfoin — *Onobrychis viciifolia* (Fabaceae) ⬜ *(id à attribuer)*

### Mélilot — *Melilotus officinalis* (Fabaceae) ⬜ *(id à attribuer)*

### Consoude officinale / de Russie — *Symphytum officinale* / *S.* × *uplandicum* (Boraginaceae) ⬜ *(id à attribuer)*
> Fertilisante (purin), pas un couvert à proprement parler — à ficher malgré
> tout, très utilisée en permaculture.
- ⬜ Consoude Bocking 14 (stérile)

---

## Notes pour les batchs de création

1. **Vérifier la famille** dans `_familles/*.yaml` avant chaque espèce ; créer la
   fiche famille manquante d'abord (schéma `_schema/famille_schema.yaml`).
   45 fiches famille existent, dont plusieurs **en avance** sur les fiches
   plantes (actinidiaceae, ebenaceae, juglandaceae, adoxaceae, elaeagnaceae,
   lythraceae, oleaceae, rutaceae, iridaceae, geraniaceae, linaceae…) : elles
   attendent leurs espèces, signalées ci-dessus par *(famille déjà présente)*.
2. **Attribuer les IDs** en continuité stricte du `_schema/id_registry.yaml` —
   **prochains numéros libres : `LEG-053`, `ARO-020`, `FRU-009`, `PFR-006`,
   `FLE-005`, `CER-005`, `ENG-009`**. Ne jamais réutiliser un numéro.
3. **Héritage sparse** (ADR-0005) : une fiche variété ne déclare que ce qui
   diffère de la mère. C'est ce qui rend soutenable l'objectif « toutes variétés
   comprises » : une fille tient souvent en 25–35 lignes.
4. **Arbitrages** :
   - ✅ tranchés à la fusion : quinoa/amarante → `CER` · maïs doux → `CER-001` ·
     phacélie → `ENG-002` · raisin de table → `FRU-008` · avoine/seigle/sarrasin
     → `ENG`.
   - ✅ tranché le 2026-08-16 et **appliqué (lot 13)** : **piment** → **une mère
     par espèce botanique** (`LEG-049` *annuum*, `LEG-050` *chinense*,
     `LEG-051` *frutescens*, `LEG-052` *baccatum*), le poivron doux `LEG-019`
     restant à part. La 5e espèce cultivée, le rocoto (*C. pubescens*), suivra
     la même règle.
   - ⬜ encore ouverts : **potiron vs potimarron** (`LEG-021-V001` est un potiron
     sous une mère « Potimarron ») · **cornichon** (recommandation : mère
     distincte) · **pop-corn** (variété de `CER-001` ou mère) · **fraisier des
     bois** (*F. vesca* : mère distincte ou filles de `PFR-001`).
5. Les listes marquées 🔡 sont **ouvertes par construction** : y ajouter une
   ligne dès qu'une variété notable est identifiée, sans attendre un batch.
6. **Ordre de bataille proposé** (du plus gros manque au plus fin) :
   1. ~~**Aromatiques — mères** (romarin, sauge, origan, marjolaine, mélisse,
      estragon, laurier-sauce, sarriette ×2, hysope, cerfeuil, livèche)~~
      ✅ **fait — lot 12 (2026-08-16)**. Restent : camomille (×2), verveine,
      monarde, perilla, agastache, népéta, angélique, cerfeuil tubéreux, anis,
      carvi, cumin, sauge ananas/sclarée, citronnelle, gingembre, curcuma,
      stévia → ~18 mères de second rang.
   2. ~~**Aromatiques — filles** (basilic, menthe, thym, aneth)~~ ✅ **fait —
      lot 12** (26 variétés). Restent : persil (3), coriandre (3), ciboulette
      (2), + les filles des mères de second rang.
   3. ~~**Piment** (arbitrage ✅ tranché : une mère par espèce botanique)~~
      ✅ **fait — lot 13 (2026-08-16)** : 4 mères + 21 filles. Reste la 5e
      espèce cultivée, le **rocoto** (*C. pubescens*), et ~22 variétés
      supplémentaires sur les quatre mères existantes.
   4. **Fruits — filles** : pommier (18), poirier (10), prunier (9), vigne (8),
      figuier (7), pêcher (7), cerisier (7) → ~66 filles sur des mères existantes.
   5. **Fruits — mères** : abricotier, cognassier, néflier (×2), kaki, noyer,
      châtaignier, amandier, kiwi, kiwaï, sureau, mûrier, grenadier, olivier,
      agrumes (×4), asiminier, arbousier → ~20 mères.
   6. **Petits fruits** : groseillier à maquereau, casseille, mûre, mûre-framboise,
      camérisier, argousier, goji, amélanchier, aronia, cornouiller (10 mères) +
      ~45 filles sur les 5 mères existantes.
   7. **Légumes — mères manquantes** : cornichon, potiron, spaghetti, pé-tsaï,
      mizuna, moutarde brune, raifort, cresson de fontaine, roquette sauvage,
      chicorée witloof à forcer, cardon, salsifis, scorsonère, lentille, pois
      chiche, soja, haricot d'Espagne, haricot kilomètre, physalis, tomatillo,
      arroche, tétragone, claytone, pourpier, ciboule, gombo, chayotte, gourde,
      persil-racine, céleri à couper, crosne, yacon, oca, igname, taro →
      ~35 mères.
   8. **Légumes — filles** : compléter les 🔡 (tomate ~45, pomme de terre ~25,
      laitue ~20, carotte ~12, haricot ~15, radis ~10, chou cabus ~10, oignon
      ~9, melon ~11, concombre ~9…).
   9. **Fleurs** : ~15 mères (rose d'Inde, tagète minute, cosmos, tournesol,
      zinnia, lavande ×3, nigelle ×2, bleuet, coquelicot, pensée, œillet, rose
      trémière, mauve, pélargonium, safran) + filles.
   10. **Céréales & engrais verts** : ~14 mères restantes + filles.

> **Ordre de grandeur de la cible.** Le document décrit **239 espèces mères** et
> **1 048 variétés**, créées + à créer, soit **1 287 fiches**. À 375 fiches
> livrées, la base est **à ~29 %** de la feuille de route. Les listes 🔡 étant
> ouvertes par construction, la cible réelle est un plancher, pas un plafond.
>
> **Rythme observé** : les lots 1→11 ont produit 269 fiches, le lot 12 en a
> ajouté 38 et le lot 13 en a ajouté 25. À ce rythme, la feuille de route
> complète représente une vingtaine de lots supplémentaires.
