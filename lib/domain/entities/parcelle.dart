import '../enums/besoin_eau.dart';
import '../enums/niveau_soleil.dart';
import '../enums/ph_sol.dart';
import '../enums/source_type_sol.dart';
import '../enums/statut_plantation.dart';
import '../enums/teinte_zone.dart';
import '../enums/technique_sol.dart';
import '../enums/texture_sol.dart';
import '../enums/type_parcelle.dart';
import '../exceptions/invariant_domaine_exception.dart';
import '../exceptions/surface_insuffisante_exception.dart';
import '../value_objects/couleur_zone.dart';
import '../value_objects/dimensions_zone.dart';
import '../value_objects/surface.dart';
import 'equipement.dart';
import 'plantation.dart';

/// A homogeneous cultivation zone (bed, planter, pot, greenhouse, mound…).
///
/// Its [surface] is entered by the user (source of truth), or equals the
/// optional [dimensions] when they are known. Soil management
/// techniques are multi-valued and orthogonal to the [type] (structure). The
/// soil [texture] is nullable (unknown by default); its origin is traced by
/// [textureSource].
///
/// `Parcelle` is an **entity** (identity by [id]); the [id] is a UUID generated
/// app-side and injected. Domain names are kept in French; the code is
/// documented in English.
///
/// Note: `pasDeConflit(FichePlante)` is deferred (needs `FichePlante`); the plan
/// `position` (`PositionParcelle`) is not modelled.
class Parcelle {
  final String _id;
  String _nom;
  final String _potagerId;
  final TypeParcelle _type;
  final Surface _surface;
  final DimensionsZone? _dimensions;
  NiveauSoleil _exposition;
  final BesoinEau? _besoinEau;
  TextureSol? _texture;
  SourceTypeSol _textureSource;
  PhSol? _ph;
  final Set<TechniqueSol> _techniquesSol;
  bool _cultureVerticale;
  final int _ordre;
  final CouleurZone _couleur;
  String? _notes;
  final List<Plantation> _plantations;
  final List<Equipement> _equipements;

  Parcelle._(
    this._id,
    this._nom,
    this._potagerId,
    this._type,
    this._surface,
    this._dimensions,
    this._exposition,
    this._besoinEau,
    this._texture,
    this._textureSource,
    this._ph,
    this._techniquesSol,
    this._cultureVerticale,
    this._ordre,
    this._couleur,
    this._notes,
    this._plantations,
    this._equipements,
  ) {
    InvariantDomaineException.verifier(_id.isNotEmpty, 'id must not be empty');
    InvariantDomaineException.verifier(
        _nom.isNotEmpty, 'nom must not be empty');
    InvariantDomaineException.verifier(
        _potagerId.isNotEmpty, 'potagerId must not be empty');
    InvariantDomaineException.verifier(
        _surface.enMetresCarres > 0, 'surface must be > 0');
    InvariantDomaineException.verifier(
        _dimensions?.surface.egaleA(_surface) ?? true,
        'surface must equal the dimensions');
  }

  /// Creates a parcelle. Soil texture, [dimensions] and [besoinEau] are
  /// unknown by default; techniques and contents start empty.
  factory Parcelle({
    required String id,
    required String nom,
    required String potagerId,
    required TypeParcelle type,
    required Surface surface,
    required NiveauSoleil exposition,
    DimensionsZone? dimensions,
    BesoinEau? besoinEau,
    int ordre = 0,
    CouleurZone couleur = const CouleurZone.teinte(TeinteZone.vertProfond),
    TextureSol? texture,
    SourceTypeSol textureSource = SourceTypeSol.manuelle,
    PhSol? ph,
    Set<TechniqueSol>? techniquesSol,
    bool cultureVerticale = false,
    String? notes,
    List<Plantation>? plantations,
    List<Equipement>? equipements,
  }) =>
      Parcelle._(
        id,
        nom,
        potagerId,
        type,
        surface,
        dimensions,
        exposition,
        besoinEau,
        texture,
        textureSource,
        ph,
        Set<TechniqueSol>.of(techniquesSol ?? const <TechniqueSol>{}),
        cultureVerticale,
        ordre,
        couleur,
        notes,
        List<Plantation>.of(plantations ?? const <Plantation>[]),
        List<Equipement>.of(equipements ?? const <Equipement>[]),
      );

  String get id => _id;
  String get nom => _nom;
  String get potagerId => _potagerId;
  TypeParcelle get type => _type;
  Surface get surface => _surface;
  DimensionsZone? get dimensions => _dimensions;
  NiveauSoleil get exposition => _exposition;

  /// Water need of the zone itself (soil, exposure), when known.
  BesoinEau? get besoinEau => _besoinEau;
  TextureSol? get texture => _texture;
  SourceTypeSol get textureSource => _textureSource;
  PhSol? get ph => _ph;
  Set<TechniqueSol> get techniquesSol => Set.unmodifiable(_techniquesSol);
  bool get cultureVerticale => _cultureVerticale;
  int get ordre => _ordre;
  CouleurZone get couleur => _couleur;
  String? get notes => _notes;
  List<Plantation> get plantations => List.unmodifiable(_plantations);
  List<Equipement> get equipements => List.unmodifiable(_equipements);

  /// The currently active plantations (status `enCours`).
  List<Plantation> plantesActuelles() => List.unmodifiable(
        _plantations.where((p) => p.estActive()),
      );

  /// Surface taken up by the active plantations.
  Surface surfaceOccupee() => plantesActuelles()
      .map((p) => p.surfaceOccupee)
      .fold(Surface.zero, (total, s) => total + s);

  /// Surface still free (clamped at zero if over-planted).
  Surface surfaceLibre() => _libreApres(_plantations);

  /// Throws [SurfaceInsuffisanteException] when the active [plantation] does
  /// not fit beside the plantations [enPlace] of this parcelle.
  void verifierPlace(Plantation plantation,
      {required Iterable<Plantation> enPlace}) {
    if (!plantation.estActive()) return;
    final libre = _libreApres(enPlace);
    if (plantation.surfaceOccupee.depasse(libre)) {
      throw SurfaceInsuffisanteException(plantation.surfaceOccupee, libre);
    }
  }

  /// Throws [SurfaceInsuffisanteException] when the active plantations among
  /// [enPlace] need more room than this parcelle's surface.
  void verifierContenance(Iterable<Plantation> enPlace) {
    final occupee = _occupeePar(enPlace);
    if (occupee.depasse(_surface)) {
      throw SurfaceInsuffisanteException(occupee, _surface);
    }
  }

  /// Surface left free by the active plantations among [plantations].
  Surface _libreApres(Iterable<Plantation> plantations) {
    final occupee = _occupeePar(plantations);
    return occupee >= _surface ? Surface.zero : _surface - occupee;
  }

  /// Surface taken up by the active plantations among [plantations].
  static Surface _occupeePar(Iterable<Plantation> plantations) => plantations
      .where((p) => p.estActive())
      .map((p) => p.surfaceOccupee)
      .fold(Surface.zero, (total, s) => total + s);

  /// Adds a [plantation] to this parcelle.
  ///
  /// Throws [SurfaceInsuffisanteException] when an **active** plantation needs
  /// more room than is free. Asserts the plantation references this parcelle.
  void ajouterPlantation(Plantation plantation) {
    assert(
      plantation.parcelleId == _id,
      'the plantation must reference this parcelle',
    );
    verifierPlace(plantation, enPlace: _plantations);
    _plantations.add(plantation);
  }

  /// Moves the plantation [plantationId] back to `enCours`.
  ///
  /// Throws [SurfaceInsuffisanteException] when it no longer fits in the free
  /// surface (no-op if absent or already active).
  void remettreEnCours(String plantationId) {
    final plantation =
        _plantations.where((p) => p.id == plantationId).firstOrNull;
    if (plantation == null || plantation.estActive()) return;
    final libre = surfaceLibre();
    if (plantation.surfaceOccupee > libre) {
      throw SurfaceInsuffisanteException(plantation.surfaceOccupee, libre);
    }
    plantation.changerStatut(StatutPlantation.enCours);
  }

  /// Removes a plantation by its [plantationId] (no-op if absent).
  void retirerPlantation(String plantationId) =>
      _plantations.removeWhere((p) => p.id == plantationId);

  /// Attaches an [equipement] to this parcelle.
  void ajouterEquipement(Equipement equipement) {
    assert(
      equipement.parcelleId == _id,
      'the equipment must reference this parcelle',
    );
    _equipements.add(equipement);
  }

  /// Removes an equipment by its [equipementId] (no-op if absent).
  void retirerEquipement(String equipementId) =>
      _equipements.removeWhere((e) => e.id == equipementId);

  void renommer(String nouveauNom) {
    InvariantDomaineException.verifier(
        nouveauNom.isNotEmpty, 'nom must not be empty');
    _nom = nouveauNom;
  }

  void modifierExposition(NiveauSoleil exposition) => _exposition = exposition;

  /// Sets the soil texture and records where the information came from.
  void definirTexture(
    TextureSol texture, {
    SourceTypeSol source = SourceTypeSol.manuelle,
  }) {
    _texture = texture;
    _textureSource = source;
  }

  void definirPh(PhSol? ph) => _ph = ph;

  void ajouterTechnique(TechniqueSol technique) =>
      _techniquesSol.add(technique);

  void retirerTechnique(TechniqueSol technique) =>
      _techniquesSol.remove(technique);

  void basculerCultureVerticale() =>
      _cultureVerticale = !_cultureVerticale;

  void modifierNotes(String? notes) => _notes = notes;

  @override
  bool operator ==(Object other) => other is Parcelle && other._id == _id;

  @override
  int get hashCode => _id.hashCode;

  @override
  String toString() =>
      'Parcelle($_id, $_nom, ${_type.name}, $_surface)';
}
