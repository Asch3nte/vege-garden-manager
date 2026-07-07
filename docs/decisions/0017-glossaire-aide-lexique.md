# ADR-0017 — Glossaire « Aide & lexique » : la référence du jardinier (chapitres, pages par terme, liens, illustrations)

- **Statut** : Accepté (2026-07-06 ; révisé le même jour après retour dev :
  couverture exhaustive « bible du jardinier », chapitres, liens hypertexte,
  illustrations ; 2ᵉ retour dev : chapitre Associations — page générale « comment
  l'app calcule » + provenance calculé/documenté par mécanisme) — **Lots 1–5 livrés**
  (reste : relecture éditoriale par chapitres, peuplement incrémental des images)
- **Contexte amont** : [docs/15 §8 C4 (#4) et #4bis](../15-elements-differes.md),
  [ADR-0006](0006-fiches-famille-botanique.md) (contenu familles/bioagresseurs),
  [ADR-0009](0009-paliers-experience-divulgation-progressive.md) (modèle
  mini-tuto pourquoi/comment), [docs/10 §aide contextuelle](../10-parcours-utilisateur.md).

---

## Contexte

L'app affiche un vocabulaire riche — familles botaniques, maladies/ravageurs,
mécanismes d'association, rusticité, climats, stades, sols, outils… — mais
**aucun endroit ne l'explique de façon centralisée et navigable**. Les
explications existantes sont éparpillées et non réutilisables : descriptions
famille de la fiche plante (`_SectionFamille`), descriptifs d'enums des
formulaires (`ChampDeroulantDecrit`), mini-tutos du guide des niveaux,
explications d'associations (ADR-0014).

**Exigence produit (dev, 2026-07-06)** : le glossaire doit être la **« bible du
jardinier en herbe »** — la référence ultime où l'utilisateur novice trouve
*tout* ce qu'il faut pour comprendre chaque terme de l'app :

- couverture **exhaustive** : toute énumération métier visible mérite son
  explication (types de cultures, outils, types de sol, gestes…) ;
- au-delà de la définition : **conseils d'utilisation et astuces** ;
- **interactif** : liens hypertexte entre pages, avec **retour = page
  précédente dans l'ordre d'ouverture** (comportement déjà généralisé dans
  l'app : historique global partagé, docs/15 §8 D#6) ;
- **illustrations** : images/dessins des éléments expliqués ;
- prise en main très facile : détaillé *et* accessible.

### Contraintes

- **Rien d'inventé** : les pages famille/bioagresseur dérivent des référentiels
  YAML ; une donnée absente s'affiche absente. Une notion sans illustration
  n'affiche pas de bloc image.
- **Cœur jamais bloqué** (garde-fou ADR-0009) : glossaire pédagogique →
  **accessible à tous les paliers**, sans gating.
- i18n dès V1 : tout contenu nouveau passe par l'ARB. Images 100 % locales,
  licences libres, provenance consignée.
- Aucune dépendance nouvelle.

---

## Décision 1 — Modèle : chapitres, types, contenu riche

Types Presentation (l10n-dépendants, comme `libelles_enums.dart`) :

```
TermeGlossaire
  id           : String              // slug stable, unique
  chapitre     : ChapitreGlossaire   // organisation « livre » (onglets)
  type         : TypeTermeGlossaire  // famille | maladie | ravageur | outil | notion
  titre        : String              // nom affiché (localisé)
  definition   : String              // paragraphe principal (peut porter des [[liens]])
  conseils     : List<String>        // conseils d'utilisation (peuvent porter des [[liens]])
  astuce       : String?             // « 💡 » one-liner pratique
  illustration : String?             // asset assets/images/glossaire/<id>.webp
  complements  : List<ComplementTerme> // blocs typés dérivés (voir D3)
```

`ChapitreGlossaire` — les **chapitres du livre**, chacun avec icône + intitulé :

| Chapitre | Contenu (extraits) |
|---|---|
| **Cultures & plantes** | catégories de plantes, sous-types de légumes, usages, stades de croissance, méthodes de mise en place, statuts |
| **Familles botaniques** | 1 page par `FamilleBotanique` (dérivé YAML) + la notion « famille botanique » et « rotation des cultures » |
| **Santé du jardin** | 1 page par `Bioagresseur` (dérivé YAML) + notions maladie/ravageur/prévention |
| **Sol & terre** | textures, pH, qualité, techniques de sol, enracinement |
| **Eau & arrosage** | besoins en eau, urgence d'arrosage, ET₀/évapotranspiration, tolérance sécheresse, oya & co (renvois outils) |
| **Outils & équipements** | **1 page par `TypeEquipement`** (oya, goutte-à-goutte, tuteur, treillis, tunnel, châssis, cloche, voile d'hivernage, filet anti-insecte, hôtel à insectes, composteur, récupérateur d'eau…) |
| **Climat & saisons** | climats, zones de rusticité, hémisphères, gel/canicule, alertes météo, périodes |
| **Associations & compagnonnage** | **page générale « comment l'app calcule les associations »** (retour dev 2026-07-06 : rappeler que le compagnonnage **n'est pas une science exacte** — résultats dépendants des facteurs propres à chaque potager — tout en expliquant le calcul interne : mécanismes, critères avec valeurs réelles, confiance, pondération — ADR-0010→0014) ; **1 page par mécanisme** (bénéfices/conflits) portant sa **provenance** : *calculé par le moteur* (règles de dérivation) vs *documenté par la communauté permaculture* (paires curatées des fiches YAML, reprises telles quelles) ; familles d'effets, sens, confiance, critères |
| **Gestes & organisation** | types de tâches, priorités, récoltes (destinations, qualités), observations, zones/parcelles, emplacements, paliers d'expérience |

`TypeTermeGlossaire` (`famille`, `maladie`, `ravageur`, `outil`, `notion`)
pilote la **couleur** des liens et badges (D5) ; le chapitre pilote le
rangement. **Granularité** : une page par *valeur* quand l'objet est concret
(un outil, une texture de sol, une technique) ; une page par *concept* quand
c'est l'échelle qui a du sens (le pH, listant ses niveaux).

Un **registre** (`glossaireProvider`) construit le tout :

| Source | Entrées |
|---|---|
| `famillesProvider` (YAML) | 1 terme / famille — description, pourquoi-rotation, ennemis, note associations, délai de retour |
| `bioagresseursProvider` (YAML) | 1 terme / bioagresseur — type, description, code EPPO |
| Catalogue statique de **notions & outils** | contenu ARB (clés `glossaire*`), inventaire en annexe A |

**Écarté** : contenu en Markdown (`assets/docs_aide/` + `flutter_markdown`,
présents mais inutilisés). Deux pipelines de contenu coexisteraient ; l'ARB +
liens wiki (D2) couvre le besoin en restant testable et i18n-natif.
`flutter_markdown` : à retirer si aucun manuel long n'arrive d'ici la V1.

## Décision 2 — Liens hypertexte : mini-syntaxe wiki dans l'ARB

Les textes du glossaire (définitions, conseils) peuvent embarquer des liens
**`[[id]]`** ou **`[[id|texte affiché]]`** vers d'autres termes. Un parseur
**pur** (`analyserLiensGlossaire(String) → List<SegmentTexte>`) découpe le
texte en segments (brut / lien) ; le rendu transforme chaque lien en span
cliquable **coloré par le type du terme cible** (D5) → navigation vers sa page.

- Parseur pur = testable unitairement (syntaxe, id inconnu, imbrication).
- Un `[[id]]` qui ne résout pas s'affiche en texte brut (jamais de lien mort) ;
  le **test d'intégrité** (D6) le signale.
- La même syntaxe sert dans *tout* contenu futur (bulles contextuelles,
  mini-tutos).

## Décision 3 — Panneau « bible » et pages par terme

**Panneau** `/plus/aide` (`PanneauAide`), pensé comme la couverture du livre :

- **recherche omniprésente** en tête (normalisation casse/accents, cherche dans
  titres **et** définitions) ;
- **grille/liste des chapitres** (icône + intitulé + nombre d'entrées) →
  chaque chapitre s'ouvre sur sa liste de termes (`/plus/aide/chapitre/:id`) ;
- entrée mise en avant « Par où commencer ? » pour les novices (page notion
  d'introduction au potager, liée aux termes clés).

**Page de terme** `/plus/aide/terme/:id` (`PageTerme`) — une vraie page
navigable de partout :

- en-tête : titre + badge type coloré + chapitre ;
- **illustration** si présente (D4) ;
- définition (avec liens wiki rendus) ;
- « 💡 Astuce » si présente ; « Conseils » en liste si présents ;
- **compléments dérivés** selon le type :
  - *famille* : nom scientifique, catégories, pourquoi-rotation (+ délai de
    retour), chips maladies/ravageurs **cliquables**, note associations —
    même source que `_SectionFamille`, jamais copié ;
  - *maladie/ravageur* : type, code EPPO, **familles concernées** (dérivé
    inverse, cliquables) ;
  - *notion adossée à un enum* : liste des valeurs avec leurs descriptifs
    (réutilise `LibellesEnums.*Description`) ;
- « Voir aussi » : termes liés (mêmes chapitre/renvois explicites).

**Historique** : les pages sont des routes go_router → elles héritent de
l'**historique global partagé** (`PileNavigation`, docs/15 §8 D#6) : le retour
rejoue les pages **dans l'ordre d'ouverture de l'utilisateur**, y compris les
enchaînements terme → terme → terme et les entrées depuis n'importe quel écran.
Un test widget dédié couvre l'enchaînement croisé + retours successifs.

## Décision 4 — Illustrations : pipeline d'assets local & sourcé

- Dossier **`assets/images/glossaire/`** ; fichier = `<id du terme>.webp`
  (léger, dimensions plafonnées) ; champ `illustration` du terme.
- **Sources libres uniquement** (domaine public / CC0 / CC-BY — dessins au
  trait type planches botaniques anciennes, Wikimedia Commons, USDA…),
  provenance et licence consignées dans `assets/images/glossaire/SOURCES.txt`
  (même discipline que `carte_monde.SOURCE.txt` ; attribution affichée dans
  À propos si CC-BY).
- Peuplement **incrémental** : un terme sans image n'affiche pas de bloc.
  Un lint (extension de `verifier_referentiels`) signale les images orphelines
  (fichier sans terme) et vérifie la présence dans `SOURCES.txt`.

## Décision 5 — Termes cliquables partout & charte de couleurs

Widget partagé **`TermeCliquable`** (texte teinté par type + soulignement
discret, `onTap → /plus/aide/terme/<id>`) et **charte de couleurs par
`TypeTermeGlossaire`** dans le design system (extension de thème, documentée
dans [docs/08](../08-design-system.md) ; déclinaison dark à la revalidation du
dark mode). C'est le **même rendu** que les liens wiki internes (D2) — une
seule grammaire visuelle.

Premier branchement : **`_SectionFamille`** de la fiche plante (nom de famille
+ chips maladies/ravageurs). Les autres surfaces (vue Associations, formulaires,
détail de zone, calendrier…) suivent au fil de l'eau, consignées dans docs/15.

## Décision 6 — Couverture exhaustive, gardée par test

Le catalogue de notions vise **tout enum métier visible par l'utilisateur**
(annexe A : ~30 enums retenus, dont chaque `TypeEquipement` en page dédiée).
Les enums **purement techniques** (mécanique UI/appareil : `SensSwipe`,
`ThemeApp`, `Langue`, `SystemeUnites`, `ModeImport`, `EtatRappel`,
`JourSemaine`, `TypeReleveMeteo`, `PermissionLocalisation`,
`SourceLocalisation`, `CibleTache`, `CibleObservation`…) sont **exclus
explicitement** dans une liste d'exclusions commentée.

**Test d'intégrité du glossaire** (même esprit que `verifier_referentiels`) :

- chaque terme a une définition non vide ; ids uniques ;
- chaque enum métier est **couvert ou explicitement exclu** (la liste
  d'exclusion est le seul échappatoire — ajouter un enum sans le classer casse
  le test) ;
- chaque lien wiki `[[id]]` du contenu résout ; chaque `illustration` pointe
  un asset existant ;
- chaque slug utilisé par un `TermeCliquable` de l'app résout.

**Hors périmètre (consigné docs/15)** : bulles contextuelles au bon moment
(réutiliseront `astuce`/liens), branchement des termes cliquables sur les
surfaces restantes, illustrations complètes (éditorial incrémental).

---

## Découpage en lots livrables

Chaque lot laisse l'app verte (`flutter analyze` + suite). Tests en parallèle.

| Lot | Périmètre | Dépendance |
|---|---|---|
| **1 — Modèle, registre & liens** ✅ | `ChapitreGlossaire`, `TypeTermeGlossaire`, `TermeGlossaire`, `ComplementTerme` (`lib/presentation/glossaire/`) ; parseur pur `analyserLiensGlossaire` (+ `extraireIdsLiens`) ; registre `construireGlossaire` + `indexerParId` (familles + bioagresseurs dérivés, triés ; 3 notions seed liées entre elles) ; `glossaireDonneesProvider` ; recherche normalisée pure (`rechercherTermes`, titres avant définitions). Clés ARB `glossaire*` (chapitres, types, repli, notions). 30 tests (parseur, recherche, dérivation/unicité/repli/inverse/intégrité des liens seed). | — |
| **2 — Panneau, chapitres & pages** ✅ | routes `/plus/aide`, `…/chapitre/:nom`, `…/terme/:id` (sous-routes de `plus` via `_RetourGlobal` → historique global) ; `PanneauAide` (recherche omniprésente + carte « Par où commencer ? » + 9 chapitres avec compteurs), `EcranChapitreGlossaire`, `PageTermeGlossaire` (badge type + chapitre, illustration si présente, définition & conseils avec **liens wiki rendus** via `TexteAvecLiens` — lien insoluble = texte brut, lien nu = titre de la cible —, astuce 💡, blocs dérivés : famille avec chips maladies/ravageurs cliquables, bioagresseur avec familles inverses cliquables, valeurs d'enum, voir-aussi) ; `LigneTermeGlossaire`/`BadgeTypeTerme` partagés ; ligne « Aide & lexique » dans `EcranPlus` ; notion seed « Par où commencer ? ». 8 tests widget (`glossaire_test.dart`) dont **retour système ×N rejouant l'ordre d'ouverture** sur l'app complète. | Lot 1 |
| **3 — Termes cliquables & charte** ✅ | extension de thème `CouleursTermes` (5 types → tokens §2/§3 existants, enregistrée light+dark, **docs/08 §3.1**) ; `terme_cliquable.dart` : `ouvrirTermeGlossaire` (ferme les feuilles modales/dialogs avant de naviguer), `TermeCliquable` (inline souligné coloré) + `PuceTermeGlossaire` (chip bordée colorée, tooltip) ; liens wiki (`TexteAvecLiens`), `BadgeTypeTerme` et chips des pages recolorés par type de cible ; **branchement `_SectionFamille`** : nom de famille cliquable (titre scindé, clé `ficheFamilleTitrePrefixe`) + chips maladies/ravageurs → pages glossaire. Tests : charte (thèmes), navigation fiche→glossaire avec fermeture de feuille (5 nouveaux). | Lot 2 |
| **4 — Contenu exhaustif** ✅ | catalogue par chapitre (`lib/presentation/glossaire/catalogue/`) : ~100 pages — 1 page/outil (`TypeEquipement`, charge du tuteur sur la page tuteur), 1 page/texture, 1 page/technique de sol, 1 page/mécanisme d'association avec **bloc provenance** (`ComplementProvenanceMecanisme`) dérivé de l'inventaire du moteur (`beneficesDerivables`/`conflitsDerivables`, gardé par un test de scan de la source du moteur), page générale « comment l'app calcule les associations », 1 page-concept par enum restant (valeurs via `LibellesEnums` réutilisés ou clés `glossaireVal*`) ; ~450 clés ARB `glossaire*` ; astuces rendues avec liens wiki (même grammaire D2) ; **carte de couverture** (`couverture_glossaire.dart` : couvert **ou** exclu, liste d'exclusions commentée) ; **test d'intégrité** complet (D6 : scan des enums, ids de couverture, unicité/défs, liens wiki def+conseils+astuce, illustrations, slugs littéraux de `lib/`). Éditorial = première passe, relecture par chapitres puis affinage au fil de l'eau. | Lot 1 |
| **5 — Illustrations** ✅ | pipeline complet : registre pur `illustrations_glossaire.dart` (`idsIllustres` + `illustrationDe`), rattachement automatique dans `construireGlossaire` (`TermeGlossaire.avecIllustration` — les pages dérivées YAML seront servies dès que leur image arrive), dossier `assets/images/glossaire/` déclaré dans pubspec (non récursif) + `SOURCES.txt` (provenance/licence par fichier) ; **lint** section 4 de `verifier_referentiels` (image orpheline, image non sourcée, entrée sans fichier = erreurs ; mention SOURCES périmée = avertissement) + volet illustrations du test d'intégrité. **Premier jeu : 6 images 100 % domaine public/CC0** (oya, cloche — gravure MET recadrée —, châssis — photo LOC ~1900 —, récupérateur d'eau, hôtel à insectes, sol argileux), WebP ≤ 800 px, ~590 Ko. Peuplement incrémental ensuite (rien en CC-BY tant que l'attribution « À propos » n'est pas câblée). | Lot 2 |

---

## Annexe A — Inventaire de couverture (notions & outils)

Enums métier retenus (~30) : `CategoriePlante`, `SousTypeLegume`,
`UsagePlante`, `StadeCroissance`, `MethodeMiseEnPlace`, `StatutPlantation`,
`TextureSol`, `PhSol`, `QualiteSol`, `TechniqueSol`, `SourceTypeSol`,
`EnracinementPlante`, `BesoinEau`, `NiveauBesoin`, `UrgenceArrosage`,
`ToleranceSecheresse`, `TypeEquipement` (**1 page/valeur**), `EtatEquipement`,
`TypeClimat`, `ZoneRusticite`, `Hemisphere`, `TypeAlerteMeteo`, `EtatCielJour`,
`TypeBeneficeAssociation`, `TypeConflitAssociation`, `FamilleEffetAssociation`,
`FamilleEffetConflit`, `SensAssociation`, `NiveauConfiance`, `PoidsAssociation`,
`CritereAssociation`, `TypeTache`, `PrioriteTache`, `TypeRecurrence`,
`DestinationRecolte`, `QualiteRecolte`, `UniteQuantite`, `TypeObservation`,
`GraviteObservation`, `TypeParcelle`, `TypeEmplacement`, `NiveauExperience`,
`NiveauSoleil`, `ChargeTuteur`, `TypeBioagresseur`, `RaisonReco`.
+ notions transverses sans enum : rotation des cultures, compagnonnage,
**calcul des associations dans l'app** (page générale : pas une science exacte,
facteurs propres à chaque potager, fonctionnement du moteur), évapotranspiration
(ET₀), paillage, permaculture, semis direct vs godet, hémisphère & saisons
inversées, « par où commencer ? ».

Provenance des mécanismes d'association (**1 page par mécanisme**) : le marqueur
*calculé par le moteur* vs *documenté par la communauté* est **dérivé de la liste
des règles du moteur** (`MoteurDerivationAssociations`) — jamais recopié à la
main ; un test garde la cohérence (un mécanisme dérivable non marqué, ou
l'inverse, casse la suite).

---

## Conséquences

### Positives
- Tout terme affiché devient explicable, illustré et navigable ; pédagogie
  centralisée, source unique (rien de dupliqué depuis les référentiels).
- La couverture est **prouvée** par le test d'intégrité (un enum ajouté sans
  entrée de glossaire ni exclusion consciente casse la CI).
- Liens wiki + historique global = exploration libre « de fil en aiguille »,
  socle direct des bulles contextuelles.
- Charte de couleurs par type de terme : repérage visuel homogène (docs/08).

### Négatives / dettes
- Volume éditorial important (annexe A) — assumé incrémental, mais le Lot 4
  demande une passe complète de premières définitions.
- Poids des images embarquées : à surveiller (webp, dimensions plafonnées,
  jeu initial restreint).
- Charte de couleurs et illustrations à revalider au maquettage du dark mode.
- `flutter_markdown` reste inutilisé → à retirer si aucun manuel long n'arrive.
