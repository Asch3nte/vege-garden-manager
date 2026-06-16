# 05 — Modèle de domaine

> Source : CAHIER §3.2. Modélise **tout le Domain** : entités, Value Objects,
> enums, interfaces, exceptions. Les noms du métier sont en français (héritage
> de la spec) ; le code applicatif reste documenté en anglais.

## 1. Conventions

- Tous les **IDs sont des UUID v4** générés côté application (`const Uuid().v4()`),
  jamais par la BDD → sync WiFi sans conflit.
- **Attributs privés** (`_field`) + getters explicites (encapsulation stricte).
- **Listes retournées immuables** : `List.unmodifiable(...)`.
- **Value Objects immuables**, égalité par valeur (`operator ==`).
- **Exceptions métier typées**, jamais `throw Exception('...')`.

## 2. Vue d'ensemble des entités

```
Potager (1) ──▶ (N) Parcelle (1) ──▶ (N) Plantation (1) ──▶ (N) Recolte
                         │
                         ├──▶ (N) TechniqueSol (multi, sur la Parcelle)
                         └──▶ (N) Equipement

Plantation ──referencé par planteId──▶ FichePlante (catalogue YAML, jamais en SQL, immuable)

Observation ──cible polymorphe──▶ Potager | Parcelle | Plantation (V1, accès par requête)
Tache ◀──depuisRappel()── Rappel
Equipement ──rattaché à──▶ Parcelle (ou transverse au Potager)
```

**Agrégat racine** : `Potager`. La `Localisation`, la `ZoneClimatique` (type +
rusticité) et l'`emplacement` sont portés au niveau du `Potager` (toutes ses
parcelles partagent le même climat). Les `Observation` ne sont **pas embarquées**
dans l'agrégat `Plantation` : elles ont une cible polymorphe et se récupèrent par
requête (`AbstractObservationRepository`) — agrégats légers.

## 3. Entités principales

### 3.1 `Potager` (agrégat racine)

Représente un potager complet. L'app supporte **plusieurs potagers** dès le MVP.

```dart
class Potager {
  final String _id;
  String _nom;
  TypeEmplacement _emplacement; // jardin, balcon, terrasse, toit…
  Localisation _localisation;
  ZoneClimatique _zoneClimatique; // porte TypeClimat + ZoneRusticite
  final DateTime _dateCreation;
  String? _notes;
  final List<Parcelle> _parcelles;

  String get id => _id;
  String get nom => _nom;
  TypeEmplacement get emplacement => _emplacement;
  Localisation get localisation => _localisation;
  ZoneClimatique get zoneClimatique => _zoneClimatique;
  List<Parcelle> get parcelles => List.unmodifiable(_parcelles);

  // Setters contrôlés
  void renommer(String nouveauNom);
  void modifierEmplacement(TypeEmplacement nouvel);
  void mettreAJourLocalisation(Localisation nouvelle);
  void mettreAJourZoneClimatique(ZoneClimatique nouvelle);
  void modifierNotes(String? nouvellesNotes);

  // Méthodes métier
  Surface surfaceTotale();
  Surface surfaceDisponible();
  void ajouterParcelle(Parcelle parcelle);
  void supprimerParcelle(String parcelleId);
  bool peutAccueillir(FichePlante plante);
  List<Plantation> plantationsActives();
}
```

### 3.2 `Parcelle` (zone physique de culture)

Zone homogène délimitée (planche, bac, pot, serre, butte…). `texture` du sol
**nullable** (= inconnue, création sans friction ; origine tracée via
`SourceTypeSol`). Maintient ses plantations et équipements ; sa `surface` est
**saisie** par l'utilisateur (source de vérité).

Champs clés : `nom`, `type` (`TypeParcelle` — structure seule), `surface`
(`Surface`, saisie), `exposition` (`NiveauSoleil`), `texture` (`TextureSol?`) +
`textureSource` (`SourceTypeSol`) + `ph` (`PhSol?`), `techniquesSol`
(`Set<TechniqueSol>`, multi, optionnel), `cultureVerticale` (`bool`),
`position` (`PositionParcelle?`, **optionnelle — vue plan V2**), `ordre`, `notes`.
Méthodes : `surfaceOccupee()`, `surfaceLibre()`, `pasDeConflit(FichePlante)`,
`plantesActuelles()`, + mutations contrôlées (`renommer`, `modifierExposition`,
`definirTexture`, `ajouterTechnique`, `retirerTechnique`, `basculerCultureVerticale`,
`ajouterPlantation`, `retirerPlantation`, `ajouterEquipement`…).

> Les techniques de gestion du sol (`butteLasagne`, `hugelkultur`, `noDig`,
> `paillage`…) sont **orthogonales** au `TypeParcelle` (structure) : un `bacSureleve`
> peut combiner plusieurs techniques (cf. `TechniqueSol`, §5).

### 3.3 `PositionParcelle` *(vue « plan du potager » — V2)*

Position & dimensions sur le plan du potager. Repère 2D en mètres, origine
(0,0) = coin haut-gauche. **Optionnelle** : non collectée en V1 (la surface est
saisie directement) ; réservée à la future vue « plan » (roadmap V2).

```dart
class PositionParcelle {
  final double _x, _y, _largeur, _hauteur, _rotation; // mètres / degrés [0,360[
  Surface surfaceCalculee(); // largeur × hauteur (vue plan uniquement)
  bool chevauche(PositionParcelle autre);
  bool contient(double x, double y);
}
```

### 3.4 `Plantation` (instance de culture)

Instance **datée, localisée, quantifiée** d'une plante dans une parcelle. À
distinguer de `FichePlante` (catalogue théorique). Conservée **indéfiniment**
(même après récolte/échec) pour stats, rotation, apprentissage. La date de
récolte estimée est **calculée dynamiquement**, jamais stockée.

```dart
class Plantation {
  final String _id, _planteId, _parcelleId;
  final DateTime _dateMiseEnPlace;
  final MethodeMiseEnPlace _methode;
  final Surface _surfaceOccupee;
  final int _nombrePieds;
  StatutPlantation _statut; // enCours, recoltee, echouee, arrachee
  final List<Recolte> _recoltes;

  Duration ageDepuisPlantation();
  DateTime? dateRecolteEstimee(FichePlante fiche, ZoneClimatique zone);
  void enregistrerRecolte(Recolte r);
  void changerStatut(StatutPlantation nouveau);
  bool estActive();
  Quantite quantiteTotaleRecoltee();
}
```

> Les **observations** d'une plantation ne sont pas embarquées dans l'agrégat :
> elles ont une cible polymorphe et se récupèrent via
> `AbstractObservationRepository.obtenirParCible(...)`.

### 3.5 `Recolte`

Événement de récolte (plusieurs récoltes successives possibles par plantation).
Champs : `plantationId`, `date`, `quantite` (`Quantite`), `destination`
(`DestinationRecolte`, requise, défaut `consommationFraiche`), `qualite`
(`QualiteRecolte?`, nullable = non encore évaluée, ajoutable a posteriori),
`notes?`.

### 3.6 `FichePlante` (catalogue, chargée depuis YAML)

Fiche de référence d'une espèce/variété. **Non créée par l'utilisateur**
(chargée depuis YAML), multilingue par conception, associations exprimées par
**IDs**. Textes (description, conseils, conservation) **localisés inline** dans
le YAML — pas de clés ARB.

Champs : `id`, `nomScientifique`, `familleBotanique`, `categorie`
(`CategoriePlante`), `sousType` (`SousTypeLegume?`), `usages` (`Set<UsagePlante>`),
`nomsLocalises` (`Map<String,String>`), `textesLocalises`
(`Map<String, TexteFiche>` par locale : description, conseils…),
`periodes` (`Map<Hemisphere, Map<TypeClimat, PeriodesCulture>>`),
`associationsBenefiques` (`List<AssociationBenefique>`) /
`associationsNegatives` (`List<AssociationConflit>`) — associations **typées**
(cible + mécanisme + raison localisée, ADR-0010, cf. §4.8),
`besoins` (`BesoinsCulture`), `espacementCm` (int), `dureeAvantRecolteJours`
(intervalle min/max), `conservation`, `rotation`.
Défense ciblée (ADR-0010 Lot 2) : `repulsifContre` / `piegeA`
(`Set<String>` de slugs `Bioagresseur` repoussés / piégés), `chargeTuteur`
(`ChargeTuteur?` — poids de la grimpante sur son support) et `hauteurAdulteCmMin`
/ `hauteurAdulteCmMax` (`int?`, §F — alimentent les règles d'étagement /
tuteurage / concurrence lumière du moteur de dérivation).
Méthodes : `nomLocalise(locale)`, `estPlantableEn(date, hemisphere, climat)`,
`sAssocieBienAvec(id)`, `entreEnConflitAvec(id)`,
`associationBenefiqueAvec(id)` / `associationConflitAvec(id)` (renvoient le VO
typé pour exposer mécanisme + raison), `repousse(slug)` / `piege(slug)`,
`aUsage(UsagePlante)`.

> `espacementCm` (distance linéaire entre pieds) remplace l'ancien
> `espaceRequisParPied` (aire) — aligné sur le YAML. La surface occupée par une
> plantation est dérivée au besoin par le moteur (espacement × nombre de pieds).

### 3.7 Autres entités

| Entité | Rôle | Notes |
|---------------------------|---------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| `Observation` | Journal de bord daté (maladie, ravageur, croissance, floraison…) | Cible **polymorphe** (potager/parcelle/plantation). `TypeObservation`, `GraviteObservation`, `resolu`. **Photos → V1.1**. Non embarquée dans l'agrégat |
| `Tache` | Action concrète (à faire / faite) | Cible : potager / parcelle / plantation / équipement. `factory Tache.depuisRappel(...)` |
| `Rappel` | Règle de planification (peut être récurrente) | Génère des `Tache` ; `prochaineRecurrence()` |
| `Equipement` | Installation sur parcelle (oya, voile, tuteur…) | Porte un `EffetEquipement` ; jamais supprimé (date de retrait) |
| `PreferencesUtilisateur` | Singleton des préférences/opt-outs | `id == "singleton"`, pattern `copierAvec` immuable |
| `Traitement` *(V1.1)* | Intervention naturelle ponctuelle (purins/extraits fermentés…) | Reportée — accueillera `thePurin`. En V1, consigner via `Observation`/`Tache` |

> **Tache vs Rappel** : un `Rappel` = règle (récurrente) ; une `Tache` =
> occurrence unitaire. Un rappel « arroser tous les 2 jours » produit N tâches
> distinctes, toutes liées via `rappel_origine_id`.

## 4. Value Objects (immuables, sans identité)

### 4.1 `Surface`
Aire physique, stockée en **m²** en interne, jamais négative (`assert`).
Constructeurs `enMetresCarres`, `enCentimetresCarres` ; opérateurs `+`, `-`,
`>=`, `<=`, `==`.

### 4.2 `Periode`
Plage de mois (`1`–`12`), gère le **chevauchement d'année** (ex. nov → fév).
`contient(DateTime)`, `compatibleAvec(ZoneClimatique)`.

### 4.3 `Localisation` (opt-out strict)
Trois constructeurs nommés selon l'**origine** de la donnée : `.nonDefinie()`,
`.manuelle(...)`, `.gps(...)`. **Coordonnées arrondies à ~1 km** (2 décimales)
pour la vie privée. `enum SourceLocalisation { nonDefinie, manuelle, gps }`
Le *mode* géoloc souhaité (désactivé/manuel/gps) est une
**préférence séparée** (`preferences.mode_geolocalisation`), pas porté par le VO.

```dart
class Localisation {
  final double? _latitude, _longitude;
  final String? _ville;
  final SourceLocalisation _source;
  Localisation.nonDefinie(); // source = nonDefinie, sans coords
  Localisation.manuelle({required String ville, required double latitude, required double longitude});
  Localisation.gps({required double latitude, required double longitude});
  bool get estDefinie => _latitude != null && _longitude != null;
  static double _arrondir(double c) => (c * 100).roundToDouble() / 100; // ~1 km
}
```

### 4.4 `BesoinsCulture`
Besoins agronomiques (côté **fiche**, ce que la plante *préfère*) : `eau`
(`BesoinEau` — `faible/modere/eleve`), `soleil` (`NiveauSoleil`), `qualitesSol`
(`Set<QualiteSol>` — multi), `phMin`/`phMax` (0–14, `phMin <= phMax`).
À distinguer de la `TextureSol` *possédée* par une parcelle : le moteur dérive
les qualités d'une texture via une table de correspondance.

### 4.5 `Quantite`
Valeur + unité (`UniteQuantite`). Conversions seulement entre unités de même
nature (masse↔masse, volume↔volume), sinon exception métier.

### 4.6 `ZoneClimatique`
Deux dimensions combinées : `type` (`TypeClimat`, Köppen simplifié)
**+** `rusticite` (`ZoneRusticite`, `zone1`–`zone13`, échelle USDA — tolérance au
froid). Déduite de la localisation (Open-Meteo) ou saisie. Méthodes :
`compatibleAvec`, `supporteGel`, `dateDernierGelEstimee()` (depuis la rusticité —
sert de barrière anti-gel au moteur).

### 4.7 `EffetEquipement`
Impact d'un équipement : modificateurs eau/soleil/température, protections
(gel, insectes, oiseaux), support physique, biodiversité, durée d'efficacité.
Fabriques prédéfinies `EffetEquipement.pourType(TypeEquipement)` (ex. oya →
`modificateurBesoinEau: 0.4` ; voile d'hivernage → `+3°C`, `protectionGel`).

### 4.8 `AssociationBenefique` / `AssociationConflit` *(ADR-0010)*
Compagnonnage **typé** : chaque association porte la `cibleId` (id de la plante
associée), un **mécanisme** optionnel (`TypeBeneficeAssociation?` /
`TypeConflitAssociation?`, cf. §5) et une **raison libre localisée**
(`raison(locale)`, repli sur le français). Deux classes distinctes (et non un VO
générique) pour garder les deux enums de mécanismes séparés au typage.

- `mecanisme == null` = paire « brute » (legacy/curatée non qualifiée) : la
  relation compte comme avant, sans mécanisme ni raison.
- Chargées depuis le YAML (`associations.beneficies[]` / `defavorables[]`,
  champs `type` + `raison_i18n`). Égalité de valeur sur (cible, mécanisme, raison).

Le `ResolveurCompagnonnage` (§7) expose le mécanisme/raison d'une paire via
`beneficeEntre(a, b)` / `conflitEntre(a, b)` (bidirectionnels, la déclaration du
centre primant), et `CompagnonsResolus` porte par compagnon un
`CompagnonAvecRaison` (fiche + association typée).

### 4.9 `ProfilPonderationAssociations` *(ADR-0011)*
Profil de pondération des associations : map `FamilleEffetAssociation →
PoidsAssociation`. `defaut()` (tout `normal`, appliqué à tous), `poids(famille)`
(repli `normal`), `multiplicateur(famille)`, `avec(famille, valeur)` (copie pour
le réglage expert), `estDefaut`. Égalité par poids par famille. Consommé par le
calculateur pur `ScoreurAssociations` (`application/engine/`) :
`score(bénéfice) = multiplicateur(familleDe(mécanisme)) × facteurConfiance` ; les
conflits ne sont pas pondérés (ordonnés par confiance). `familleDe(mécanisme)`
(dans `famille_effet_association.dart`) est la source unique du mapping.

## 5. Énumérations principales

```dart
// — Catalogue / fiches —
enum CategoriePlante { legume, aromatique, fruit, petitFruit, fleur, cereale, engraisVert }
enum SousTypeLegume { legumeFruit, legumeFeuille, legumeRacine, legumeBulbe,
                      legumeTige, legumeFleur, legumeTubercule } // si categorie == legume
enum UsagePlante { alimentaire, condimentaire, medicinale, compagnonnage, repulsif,
                   mellifere, pollinisateur, engraisVert, couvreSol, briseVent,
                   tuteurVivant, ornementale, fourrage } // multi-valué (≥ 1)
enum Hemisphere { nord, sud }
// Mécanismes d'association typés (ADR-0010) — qualifient les paires de compagnonnage
enum TypeBeneficeAssociation { tuteurStructurel, etagementLumiere, repulsionRavageur,
                               brouillageOlfactif, attractionPollinisateurs, plantePiege,
                               fixationAzote, couvreSol, briseVent, successionTemporelle }
enum TypeConflitAssociation { memeFamilleRavageurs, competitionLumiere,
                              competitionAzote, allelopathie }
enum ChargeTuteur { legere, moyenne, lourde } // poids d'une grimpante sur son support (ADR-0010 Lot 2)
enum NiveauConfiance { faible, moyen, eleve } // confiance d'une association dérivée (ADR-0010 Lot 3)
// Pondération des associations (ADR-0011) — familles d'effets + poids ajustable (expert)
enum FamilleEffetAssociation { gainDePlace, protectionRavageurs, fertilite,
                               pollinisation, couvertureAbri }
enum PoidsAssociation { ignore, faible, normal, fort } // ×0 / ×0.5 / ×1 / ×1.5

// — Parcelle / sol —
enum TypeParcelle { pleineTerre, bacSureleve, jardiniere, pot, serre, butte, autre } // structure seule
enum TechniqueSol { // multi-valué, orthogonal au TypeParcelle
  butteLasagne, hugelkultur, butteRonde, buttePermanente, // structure de sol
  paillage, brf, mulchVivant, engraisVertCouvert, paillageMineral, carton, // couverture / paillage
  noDig, grelinette, mulchDeFoin, // sans travail / minimal
  compostageSurface, compostEnTrou, mycorhization, bokashi, // amendement / fertilité
  swales, keylineDesign } // gestion eau / structure
enum TypeEmplacement { jardin, balcon, terrasse, toit, cour, interieur, autre } // attribut Potager
enum TextureSol { argileux, sableux, limoneux, calcaire, humifere, tourbeux, caillouteux } // parcelle (nullable = inconnue)
enum QualiteSol { riche, pauvre, bienDraine, malDraine, frais, sec, lourd, leger } // recherchée (fiche)
enum PhSol { acide, neutre, alcalin }
enum SourceTypeSol { manuelle, deduitDeLocalisation, deduitDuClimat }

// — Plantation / récolte —
enum MethodeMiseEnPlace { semisDirect, semisInterieur, repiquage, plantAchete, bouture, division }
enum StatutPlantation { enCours, recoltee, echouee, arrachee }
enum NiveauSoleil { ombre, miOmbre, pleinSoleil } // exposition ET besoin
enum BesoinEau { faible, modere, eleve }
enum UniteQuantite { g, kg, piece, botte, litre, ml } // unique (UniteRecolte supprimé)
enum QualiteRecolte { excellente, bonne, moyenne, mediocre }
enum DestinationRecolte { consommationFraiche, conservation, don, semences, compost, autre }

// — Équipement (réconciliation enum en passe dédiée) —
enum TypeEquipement { /* irrigation, protection, structure, biodiversité, mesure */
  oya, gouttesAGoutte, tuteur, treillis, tunnel, serreSemis, chassis, cloche,
  voileHivernage, filetAntiInsecte, hotelInsectes, composteur, recuperateurEau, autre }
enum EtatEquipement { neuf, bon, use, aRemplacer, horsService }

// — Tâches / rappels —
enum TypeTache { arrosage, desherbage, paillage, taille, tuteurage, fertilisation, traitementBio, observation, semis, repiquage, recolte, preparationSol, installationEquipement, entretienEquipement, nettoyage, autre }
enum EtatTache { aFaire, enCours, terminee, annulee }
enum PrioriteTache { basse, normale, haute, urgente }
enum TypeRecurrence { ponctuel, quotidien, hebdomadaire, mensuel, personnalise }
enum EtatRappel { actif, enPause, termine }
enum JourSemaine { lundi, mardi, mercredi, jeudi, vendredi, samedi, dimanche }

// — Observation —
enum CibleObservation { potager, parcelle, plantation } // cible polymorphe
enum TypeObservation { maladie, ravageur, carence, meteo, croissance, floraison, fructification, general, autre }
enum GraviteObservation { info, faible, modere, eleve, critique }

// — Climat —
enum TypeClimat { tropical, subtropical, aride, semiAride, mediterraneen,
                  oceanique, continental, montagnard, polaire }
enum ZoneRusticite { zone1, zone2, zone3, zone4, zone5, zone6, zone7,
                     zone8, zone9, zone10, zone11, zone12, zone13 } // USDA

// — Technique / divers —
enum TypeReleveMeteo { observe, prevu }
enum TypeParametre { booleen, entier, decimal, texte, json }
enum SourceFiche { embarquee, telechargee, personnelle }
```

> ⚠️ Cohérence enum ↔ SQL : chaque enum persistée a une contrainte `CHECK`
> correspondante en BDD (cf. [06-modele-de-donnees-sqlite.md](06-modele-de-donnees-sqlite.md)).
> Les enums multi-valués (`UsagePlante`, `TechniqueSol`) sont stockés en **tableau JSON**.

## 6. Interfaces de repositories (contrats du Domain)

```dart
abstract class AbstractPotagerRepository {
  Future<Potager?> obtenirPotagerActif();
  Future<List<Potager>> obtenirTous();
  Future<void> sauvegarder(Potager potager);
}
abstract class AbstractParcelleRepository {
  Future<List<Parcelle>> obtenirParPotager(String potagerId);
  Future<Parcelle?> obtenirParId(String id);
  Future<void> sauvegarder(Parcelle parcelle);
  Future<void> supprimer(String id);
}
abstract class AbstractPlantationRepository {
  Future<List<Plantation>> obtenirParParcelle(String parcelleId);
  Future<List<Plantation>> obtenirActives();
  Future<void> sauvegarder(Plantation plantation);
  Future<void> supprimer(String id);
}
abstract class AbstractRecolteRepository {
  Future<List<Recolte>> obtenirParPlantation(String plantationId);
  Future<void> sauvegarder(Recolte recolte);
}
abstract class AbstractFichePlanteRepository {
  Future<List<FichePlante>> obtenirToutes();
  Future<FichePlante?> obtenirParId(String id);
  Future<List<FichePlante>> rechercher(String terme, String locale);
  Future<List<FichePlante>> filtrerParCategorie(CategoriePlante cat);
  Future<List<FichePlante>> filtrerParUsage(UsagePlante usage);
}
abstract class AbstractObservationRepository { // — cible polymorphe
  Future<List<Observation>> obtenirParCible(CibleObservation cible, String cibleId);
  Future<List<Observation>> obtenirNonResolues();
  Future<void> sauvegarder(Observation observation);
  Future<void> supprimer(String id);
}
// + AbstractPreferencesRepository (charger / sauvegarder / reinitialiser)
```

## 7. Interfaces de services (contrats du Domain)

```dart
abstract class AbstractMeteoService {
  Future<DonneesMeteo> obtenirMeteoActuelle(Localisation loc);
  Future<List<PrevisionMeteo>> obtenirPrevisions(Localisation loc, int nbJours);
}
abstract class AbstractNotificationService {
  Future<void> programmer(NotificationLocale notif);
  Future<void> annuler(String id);
  Future<bool> sontAutorisees();
}
abstract class AbstractSyncService {
  Future<void> demarrerDecouverte();
  Future<void> arreter();
  Stream<AppareilDecouvert> get appareilsDecouverts;
  Future<void> synchroniserAvec(AppareilDecouvert appareil);
}
```

**Value Objects / DTO portés par ces contrats** (Domain, immuables — P9) :

| Type | Champs (résumé) |
|---------------------|------------------------------------------------------------------------------------------|
| `DonneesMeteo` | `date`, `tempMin/Max/Moyenne`, `precipitationsMm`, `ventVitesseMax`, `risqueGel/Canicule` |
| `PrevisionMeteo` | `date`, `tempMin/Max`, `precipitationsMm`, `probabilitePluie`, `type` (`TypeReleveMeteo`) |
| `NotificationLocale`| `id`, `titre`, `corps`, `dateProgrammee`, `categorie` (clé), `cibleRoute?` |
| `AppareilDecouvert` | `id`, `nom` (hostname), `adresseIp`, `port`, `derniereVue` |

> `NotificationLocale` (et non `Notification`) pour éviter la collision avec la
> classe Flutter/OS `Notification`.

## 8. Exceptions métier

```dart
abstract class PotagerException implements Exception {
  final String message;
  const PotagerException(this.message);
}

class AssociationIncompatibleException extends PotagerException { /* plante1Id, plante2Id */ }
class SurfaceInsuffisanteException extends PotagerException { /* requise, disponible */ }
class PeriodePlantationInvalideException extends PotagerException {}
class ZoneClimatiqueIncompatibleException extends PotagerException {}
class FichePlanteIntrouvableException extends PotagerException {}
```

## 9. Points d'attention

| Point | Raison |
|-------------------------------|---------------------------------------------|
| `FichePlante` ≠ `Plantation` | Catalogue YAML immuable vs instance plantée |
| Value Objects immuables | Pas d'identité, égalité par valeur |
| Attributs privés partout | Encapsulation stricte |
| Interfaces dans le Domain | Inversion de dépendance (SOLID) |
| Exceptions typées | Gestion d'erreur explicite |
| IDs en `String` (UUID) | Sync multi-appareils |
| Listes immuables retournées | `List.unmodifiable()` |
