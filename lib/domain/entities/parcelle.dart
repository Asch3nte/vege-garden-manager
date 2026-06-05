import '../enums/niveau_soleil.dart';
import '../enums/ph_sol.dart';
import '../enums/source_type_sol.dart';
import '../enums/technique_sol.dart';
import '../enums/texture_sol.dart';
import '../enums/type_parcelle.dart';
import '../exceptions/surface_insuffisante_exception.dart';
import '../value_objects/surface.dart';
import 'equipement.dart';
import 'plantation.dart';

/// A homogeneous cultivation zone (bed, planter, pot, greenhouse, mound…).
///
/// Its [surface] is entered by the user (source of truth). Soil management
/// techniques are multi-valued and orthogonal to the [type] (structure). The
/// soil [texture] is nullable (unknown by default); its origin is traced by
/// [textureSource].
///
/// `Parcelle` is an **entity** (identity by [id]); the [id] is a UUID generated
/// app-side and injected. Domain names are kept in French; the code is
/// documented in English. See `docs/05-modele-de-domaine.md` §3.2.
///
/// Note: `pasDeConflit(FichePlante)` is deferred (needs `FichePlante`); the plan
/// `position` (`PositionParcelle`) is a V2 concern and is not modelled here.
class Parcelle {
  final String _id;
  String _nom;
  final String _potagerId;
  final TypeParcelle _type;
  final Surface _surface;
  NiveauSoleil _exposition;
  TextureSol? _texture;
  SourceTypeSol _textureSource;
  PhSol? _ph;
  final Set<TechniqueSol> _techniquesSol;
  bool _cultureVerticale;
  final int _ordre;
  String? _notes;
  final List<Plantation> _plantations;
  final List<Equipement> _equipements;

  Parcelle._(
    this._id,
    this._nom,
    this._potagerId,
    this._type,
    this._surface,
    this._exposition,
    this._texture,
    this._textureSource,
    this._ph,
    this._techniquesSol,
    this._cultureVerticale,
    this._ordre,
    this._notes,
    this._plantations,
    this._equipements,
  )   : assert(_id.isNotEmpty, 'id must not be empty'),
        assert(_nom.isNotEmpty, 'nom must not be empty'),
        assert(_potagerId.isNotEmpty, 'potagerId must not be empty'),
        assert(_surface.enMetresCarres > 0, 'surface must be > 0');

  /// Creates a parcelle. Soil texture is unknown by default; techniques and
  /// contents start empty.
  factory Parcelle({
    required String id,
    required String nom,
    required String potagerId,
    required TypeParcelle type,
    required Surface surface,
    required NiveauSoleil exposition,
    int ordre = 0,
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
        exposition,
        texture,
        textureSource,
        ph,
        Set<TechniqueSol>.of(techniquesSol ?? const <TechniqueSol>{}),
        cultureVerticale,
        ordre,
        notes,
        List<Plantation>.of(plantations ?? const <Plantation>[]),
        List<Equipement>.of(equipements ?? const <Equipement>[]),
      );

  String get id => _id;
  String get nom => _nom;
  String get potagerId => _potagerId;
  TypeParcelle get type => _type;
  Surface get surface => _surface;
  NiveauSoleil get exposition => _exposition;
  TextureSol? get texture => _texture;
  SourceTypeSol get textureSource => _textureSource;
  PhSol? get ph => _ph;
  Set<TechniqueSol> get techniquesSol => Set.unmodifiable(_techniquesSol);
  bool get cultureVerticale => _cultureVerticale;
  int get ordre => _ordre;
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
  Surface surfaceLibre() {
    final occupee = surfaceOccupee();
    return occupee >= _surface ? Surface.zero : _surface - occupee;
  }

  /// Adds a [plantation] to this parcelle.
  ///
  /// Throws [SurfaceInsuffisanteException] when an **active** plantation needs
  /// more room than is free. Asserts the plantation references this parcelle.
  void ajouterPlantation(Plantation plantation) {
    assert(
      plantation.parcelleId == _id,
      'the plantation must reference this parcelle',
    );
    if (plantation.estActive()) {
      final libre = surfaceLibre();
      if (plantation.surfaceOccupee > libre) {
        throw SurfaceInsuffisanteException(plantation.surfaceOccupee, libre);
      }
    }
    _plantations.add(plantation);
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
    assert(nouveauNom.isNotEmpty, 'nom must not be empty');
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
