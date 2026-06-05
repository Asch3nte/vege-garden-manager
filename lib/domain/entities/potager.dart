import '../enums/type_emplacement.dart';
import '../value_objects/localisation.dart';
import '../value_objects/surface.dart';
import '../value_objects/zone_climatique.dart';
import 'parcelle.dart';
import 'plantation.dart';

/// Aggregate root: a complete vegetable garden. The app supports several
/// potagers from the start.
///
/// The [localisation], the [zoneClimatique] (type + rusticity) and the
/// [emplacement] live at this level — all of a potager's parcelles share the
/// same climate. [localisation] defaults to undefined (privacy opt-out).
///
/// `Potager` is an **entity** (identity by [id]); the [id] is a UUID generated
/// app-side and injected. Domain names are kept in French; the code is
/// documented in English. See `docs/05-modele-de-domaine.md` §3.1.
///
/// Note: `peutAccueillir(FichePlante)` is deferred (needs `FichePlante`).
class Potager {
  final String _id;
  String _nom;
  TypeEmplacement _emplacement;
  Localisation _localisation;
  ZoneClimatique _zoneClimatique;
  final DateTime _dateCreation;
  String? _notes;
  final List<Parcelle> _parcelles;

  Potager._(
    this._id,
    this._nom,
    this._emplacement,
    this._localisation,
    this._zoneClimatique,
    this._dateCreation,
    this._notes,
    this._parcelles,
  )   : assert(_id.isNotEmpty, 'id must not be empty'),
        assert(_nom.isNotEmpty, 'nom must not be empty');

  /// Creates a potager. [localisation] defaults to undefined (opt-out).
  factory Potager({
    required String id,
    required String nom,
    required ZoneClimatique zoneClimatique,
    required DateTime dateCreation,
    TypeEmplacement emplacement = TypeEmplacement.jardin,
    Localisation localisation = const Localisation.nonDefinie(),
    String? notes,
    List<Parcelle>? parcelles,
  }) =>
      Potager._(
        id,
        nom,
        emplacement,
        localisation,
        zoneClimatique,
        dateCreation,
        notes,
        List<Parcelle>.of(parcelles ?? const <Parcelle>[]),
      );

  String get id => _id;
  String get nom => _nom;
  TypeEmplacement get emplacement => _emplacement;
  Localisation get localisation => _localisation;
  ZoneClimatique get zoneClimatique => _zoneClimatique;
  DateTime get dateCreation => _dateCreation;
  String? get notes => _notes;

  /// The parcelles of this potager, as an unmodifiable list.
  List<Parcelle> get parcelles => List.unmodifiable(_parcelles);

  /// Sum of every parcelle's total surface.
  Surface surfaceTotale() =>
      _parcelles.map((p) => p.surface).fold(Surface.zero, (t, s) => t + s);

  /// Sum of every parcelle's free surface.
  Surface surfaceDisponible() => _parcelles
      .map((p) => p.surfaceLibre())
      .fold(Surface.zero, (t, s) => t + s);

  /// All active plantations across the potager's parcelles.
  List<Plantation> plantationsActives() => List.unmodifiable(
        _parcelles.expand((p) => p.plantesActuelles()),
      );

  /// Attaches a [parcelle] to this potager.
  void ajouterParcelle(Parcelle parcelle) {
    assert(
      parcelle.potagerId == _id,
      'the parcelle must reference this potager',
    );
    _parcelles.add(parcelle);
  }

  /// Removes a parcelle by its [parcelleId] (no-op if absent).
  void supprimerParcelle(String parcelleId) =>
      _parcelles.removeWhere((p) => p.id == parcelleId);

  void renommer(String nouveauNom) {
    assert(nouveauNom.isNotEmpty, 'nom must not be empty');
    _nom = nouveauNom;
  }

  void modifierEmplacement(TypeEmplacement emplacement) =>
      _emplacement = emplacement;

  void mettreAJourLocalisation(Localisation localisation) =>
      _localisation = localisation;

  void mettreAJourZoneClimatique(ZoneClimatique zoneClimatique) =>
      _zoneClimatique = zoneClimatique;

  void modifierNotes(String? notes) => _notes = notes;

  @override
  bool operator ==(Object other) => other is Potager && other._id == _id;

  @override
  int get hashCode => _id.hashCode;

  @override
  String toString() => 'Potager($_id, $_nom, ${_emplacement.name})';
}
