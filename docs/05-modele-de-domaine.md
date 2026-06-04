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
                                          └──▶ (N) NoteObservation (V1.1)

Plantation ──referencé par planteId──▶ FichePlante   (catalogue YAML, jamais en SQL, immuable)

Tache ◀──depuisRappel()── Rappel
Equipement ──rattaché à──▶ Parcelle (ou transverse au Potager)
```

**Agrégat racine** : `Potager`. La `Localisation` et la `ZoneClimatique` sont
portées au niveau du `Potager` (toutes ses parcelles partagent le même climat).

## 3. Entités principales

### 3.1 `Potager` (agrégat racine)

Représente un potager complet. L'app supporte **plusieurs potagers** dès le MVP.

```dart
class Potager {
  final String _id;
  String _nom;
  Localisation _localisation;
  ZoneClimatique _zoneClimatique;
  final DateTime _dateCreation;
  String? _notes;
  final List<Parcelle> _parcelles;

  String get id => _id;
  String get nom => _nom;
  Localisation get localisation => _localisation;
  ZoneClimatique get zoneClimatique => _zoneClimatique;
  List<Parcelle> get parcelles => List.unmodifiable(_parcelles);

  // Setters contrôlés
  void renommer(String nouveauNom);
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

Zone homogène délimitée (planche, bac, pot, serre, butte…). `typeSol` non
nullable (défaut traçable via `SourceTypeSol`). Maintient ses plantations et
équipements ; sa `surface` est **calculée** depuis sa `PositionParcelle`
(source de vérité unique).

Champs clés : `nom`, `type` (`TypeParcelle`), `exposition` (`NiveauSoleil`),
`typeSol` + `typeSolSource`, `position` (`PositionParcelle`), `ordre`, `notes`.
Méthodes : `surfaceOccupee()`, `surfaceLibre()`, `pasDeConflit(FichePlante)`,
`plantesActuelles()`, + mutations contrôlées (`renommer`, `modifierExposition`,
`definirTypeSol`, `deplacer`, `redimensionner`, `pivoter`, `ajouterPlantation`,
`retirerPlantation`, `ajouterEquipement`…).

### 3.3 `PositionParcelle`

Position & dimensions sur le plan du potager. Repère 2D en mètres, origine
(0,0) = coin haut-gauche.

```dart
class PositionParcelle {
  final double _x, _y, _largeur, _hauteur, _rotation; // mètres / degrés [0,360[
  Surface surfaceCalculee();        // largeur × hauteur
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
  StatutPlantation _statut;          // enCours, recoltee, echouee, arrachee
  final List<Recolte> _recoltes;
  final List<NoteObservation> _notes;

  Duration ageDepuisPlantation();
  DateTime? dateRecolteEstimee(FichePlante fiche, ZoneClimatique zone);
  void enregistrerRecolte(Recolte r);
  void ajouterNote(NoteObservation n);
  void changerStatut(StatutPlantation nouveau);
  bool estActive();
  Quantite quantiteTotaleRecoltee();
}
```

### 3.5 `Recolte`

Événement de récolte (plusieurs récoltes successives possibles par plantation).
Champs : `plantationId`, `date`, `quantite` (`Quantite`), `qualite`
(`QualiteRecolte?`, nullable, ajoutable a posteriori), `notes?`.

### 3.6 `FichePlante` (catalogue, chargée depuis YAML)

Fiche de référence d'une espèce/variété. **Non créée par l'utilisateur**
(chargée depuis YAML), multilingue par conception, associations exprimées par
**IDs**. Conseils/conservation stockés en **clés i18n**.

Champs : `id`, `nomScientifique`, `nomsLocalises` (`Map<String,String>`),
`categorie`, `periodesSemis/Plantation/Recolte` (`List<Periode>`),
`associationsBenefiques/Negatives` (IDs), `besoins` (`BesoinsCulture`),
`zonesCompatibles`, `espaceRequisParPied` (`Surface`), `dureeAvantRecolte`,
`conseilsPermaculture` / `methodesConservation` (clés i18n).
Méthodes : `nomLocalise(locale)`, `estPlantableEn(date, zone)`,
`sAssocieBienAvec(id)`, `entreEnConflitAvec(id)`, `tempsEstimeAvantRecolte()`.

### 3.7 Autres entités

| Entité                    | Rôle                                                                | Notes                                                                                   |
|---------------------------|---------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| `NoteObservation`         | Observation datée (maladie, croissance, floraison…), photos locales | `TypeObservation`, `_photosLocales` (chemins)                                           |
| `Tache`                   | Action concrète (à faire / faite)                                   | Cible : potager / parcelle / plantation / équipement. `factory Tache.depuisRappel(...)` |
| `Rappel`                  | Règle de planification (peut être récurrente)                       | Génère des `Tache` ; `prochaineRecurrence()`                                            |
| `Equipement`              | Installation sur parcelle (oya, voile, tuteur…)                     | Porte un `EffetEquipement` ; jamais supprimé (date de retrait)                          |
| `PreferencesUtilisateur`  | Singleton des préférences/opt-outs                                  | `id == "singleton"`, pattern `copierAvec` immuable                                      |
| `Traitement` *(V1.1)*     | Intervention naturelle (purins, paillage…)                          | Reportée — en V1, consigner via `NoteObservation`/`Tache`                               |

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
Trois modes via constructeurs nommés : `.desactivee()`, `.manuelle(...)`,
`.automatique(...)`. **Coordonnées arrondies à ~1 km** (2 décimales) pour la
vie privée. `enum SourceLocalisation { desactivee, manuelle, gps }`.

```dart
class Localisation {
  final double? _latitude, _longitude;
  final String? _nomVille;
  final bool _geolocalisationActivee;
  final SourceLocalisation _source;
  Localisation.desactivee();
  Localisation.manuelle({required String ville, required double latitude, required double longitude});
  Localisation.automatique({required double latitude, required double longitude});
  bool get estDefinie => _latitude != null && _longitude != null;
  static double _arrondir(double c) => (c * 100).roundToDouble() / 100; // ~1 km
}
```

### 4.4 `BesoinsCulture`
Besoins agronomiques : `eau` (`BesoinEau`), `soleil` (`NiveauSoleil`),
`solPrefere` (`TypeSol`), `phMin`/`phMax` (0–14, `phMin <= phMax`).
Niveaux **qualitatifs** (faible/moyen/élevé), pH numérique.

### 4.5 `Quantite`
Valeur + unité (`UniteQuantite`). Conversions seulement entre unités de même
nature (masse↔masse, volume↔volume), sinon exception métier.

### 4.6 `ZoneClimatique`
Classification climatique simplifiée + zone de rusticité (1–11, échelle USDA
simplifiée). Déduite de la localisation (Open-Meteo) ou saisie. `compatibleAvec`,
`supporteGel`.

### 4.7 `EffetEquipement`
Impact d'un équipement : modificateurs eau/soleil/température, protections
(gel, insectes, oiseaux), support physique, biodiversité, durée d'efficacité.
Fabriques prédéfinies `EffetEquipement.pourType(TypeEquipement)` (ex. oya →
`modificateurBesoinEau: 0.4` ; voile d'hivernage → `+3°C`, `protectionGel`).

## 5. Énumérations principales

```dart
enum TypeParcelle { pleineTerre, bacSureleve, potEnPot, serre, butte, butteLasagne, hugelkultur }
enum TypeSol { argileux, sableux, limoneux, calcaire, humifere, equilibre } // + 'inconnu' côté SQL
enum CategoriePlante { legumeFruit, legumeFeuille, legumeRacine, legumeBulbe, legumineuse, aromatique, fleur, fruitier }
enum MethodeMiseEnPlace { semisDirect, semisInterieur, repiquage, plantAchete, bouture, division }
enum StatutPlantation { enCours, recoltee, echouee, arrachee }
enum NiveauSoleil { ombre, miOmbre, pleinSoleil }       // exposition ET besoin
enum BesoinEau { faible, moyen, eleve }
enum UniteQuantite { grammes, kilogrammes, pieces, litres, bottes }
enum UniteRecolte { kg, g, pieces, bottes, litres }
enum QualiteRecolte { excellente, bonne, moyenne, mediocre }
enum DestinationRecolte { consommationFraiche, conservation, don, semences, compost, autre }
enum TypeEquipement { /* irrigation, protection, structure, biodiversité, mesure */ oya, voileHivernage, tuteur, treillis, hotelInsectes, /* … */ }
enum EtatEquipement { neuf, bon, use, aRemplacer, horsService }
enum TypeTache { arrosage, desherbage, paillage, taille, tuteurage, fertilisation, traitementBio, observation, semis, repiquage, recolte, preparationSol, installationEquipement, entretienEquipement, nettoyage, autre }
enum EtatTache { aFaire, enCours, terminee, annulee }
enum PrioriteTache { basse, normale, haute, urgente }
enum TypeRecurrence { ponctuel, quotidien, hebdomadaire, personnalise, mensuel }
enum EtatRappel { actif, enPause, termine }
enum JourSemaine { lundi, mardi, mercredi, jeudi, vendredi, samedi, dimanche }
enum TypeObservation { maladie, ravageur, carence, meteo, croissance, floraison, fructification, general, autre }
enum GraviteObservation { info, faible, modere, eleve, critique }
enum TypeClimat { /* Köppen simplifié : tropicalHumide, mediterraneen, oceanique, continentalHumide, montagnard, polaire, … */ }
enum SourceTypeSol { manuelle, deduitDeLocalisation, deduitDuClimat }
enum TypeReleveMeteo { observe, prevu }
enum TypeParametre { booleen, entier, decimal, texte, json }
enum SourceFiche { embarquee, telechargee, personnelle }
```

> ⚠️ Cohérence enum ↔ SQL : chaque enum persistée a une contrainte `CHECK`
> correspondante en BDD (cf. [06-modele-de-donnees-sqlite.md](06-modele-de-donnees-sqlite.md)).

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
  Future<void> programmer(Notification notif);
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

## 8. Exceptions métier

```dart
abstract class PotagerException implements Exception {
  final String message;
  const PotagerException(this.message);
}

class AssociationIncompatibleException extends PotagerException { /* plante1Id, plante2Id */ }
class SurfaceInsuffisanteException     extends PotagerException { /* requise, disponible */ }
class PeriodePlantationInvalideException extends PotagerException {}
class ZoneClimatiqueIncompatibleException extends PotagerException {}
class FichePlanteIntrouvableException   extends PotagerException {}
```

## 9. Points d'attention

| Point                         | Raison                                      |
|-------------------------------|---------------------------------------------|
| `FichePlante` ≠ `Plantation`  | Catalogue YAML immuable vs instance plantée |
| Value Objects immuables       | Pas d'identité, égalité par valeur          |
| Attributs privés partout      | Encapsulation stricte                       |
| Interfaces dans le Domain     | Inversion de dépendance (SOLID)             |
| Exceptions typées             | Gestion d'erreur explicite                  |
| IDs en `String` (UUID)        | Sync multi-appareils                        |
| Listes immuables retournées   | `List.unmodifiable()`                       |
