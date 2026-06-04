import '../enums/methode_mise_en_place.dart';
import '../enums/statut_plantation.dart';
import '../value_objects/quantite.dart';
import '../value_objects/surface.dart';
import 'recolte.dart';

/// A dated, located, quantified instance of a plant grown in a parcelle — to be
/// distinguished from `FichePlante` (the theoretical catalogue).
///
/// Kept indefinitely (even after harvest/failure) for stats, rotation and
/// learning. The estimated harvest date is computed dynamically and never
/// stored. `Plantation` is an **entity** (identity by [id]); the [id] is a UUID
/// generated app-side and injected.
///
/// Domain names are kept in French; the code is documented in English.
/// See `docs/05-modele-de-domaine.md` §3.4.
///
/// Note: `dateRecolteEstimee(FichePlante, ZoneClimatique)` is deferred — it needs
/// `FichePlante` (catalogue, not built yet) and belongs with the engine logic.
class Plantation {
  final String _id;
  final String _planteId;
  final String _parcelleId;
  final DateTime _dateMiseEnPlace;
  final MethodeMiseEnPlace _methode;
  final Surface _surfaceOccupee;
  final int _nombrePieds;
  StatutPlantation _statut;
  DateTime? _dateFinReelle;
  String? _raisonFin;
  final List<Recolte> _recoltes;

  Plantation._(
    this._id,
    this._planteId,
    this._parcelleId,
    this._dateMiseEnPlace,
    this._methode,
    this._surfaceOccupee,
    this._nombrePieds,
    this._statut,
    this._dateFinReelle,
    this._raisonFin,
    this._recoltes,
  )   : assert(_id.isNotEmpty, 'id must not be empty'),
        assert(_nombrePieds > 0, 'nombrePieds must be > 0'),
        assert(_surfaceOccupee.enMetresCarres > 0, 'surface must be > 0'),
        assert(
          (_statut == StatutPlantation.enCours) == (_dateFinReelle == null),
          'an end date exists iff the status is terminal',
        );

  /// Creates a plantation. Defaults to an active (`enCours`) status with no
  /// harvests. When reconstructing from storage, a terminal [statut] must come
  /// with a [dateFinReelle].
  factory Plantation({
    required String id,
    required String planteId,
    required String parcelleId,
    required DateTime dateMiseEnPlace,
    required MethodeMiseEnPlace methode,
    required Surface surfaceOccupee,
    required int nombrePieds,
    StatutPlantation statut = StatutPlantation.enCours,
    DateTime? dateFinReelle,
    String? raisonFin,
    List<Recolte>? recoltes,
  }) =>
      Plantation._(
        id,
        planteId,
        parcelleId,
        dateMiseEnPlace,
        methode,
        surfaceOccupee,
        nombrePieds,
        statut,
        dateFinReelle,
        raisonFin,
        List<Recolte>.from(recoltes ?? const <Recolte>[]),
      );

  String get id => _id;
  String get planteId => _planteId;
  String get parcelleId => _parcelleId;
  DateTime get dateMiseEnPlace => _dateMiseEnPlace;
  MethodeMiseEnPlace get methode => _methode;
  Surface get surfaceOccupee => _surfaceOccupee;
  int get nombrePieds => _nombrePieds;
  StatutPlantation get statut => _statut;
  DateTime? get dateFinReelle => _dateFinReelle;
  String? get raisonFin => _raisonFin;

  /// The recorded harvests, as an unmodifiable list.
  List<Recolte> get recoltes => List.unmodifiable(_recoltes);

  /// Whether the plantation is still growing.
  bool estActive() => _statut == StatutPlantation.enCours;

  /// Time elapsed between planting and [reference].
  ///
  /// Takes an explicit reference instant (rather than reading the clock) so the
  /// domain stays pure and the behaviour is deterministic in tests.
  Duration ageDepuis(DateTime reference) =>
      reference.difference(_dateMiseEnPlace);

  /// Records a [recolte] for this plantation.
  void enregistrerRecolte(Recolte recolte) {
    assert(
      recolte.plantationId == _id,
      'the harvest must reference this plantation',
    );
    _recoltes.add(recolte);
  }

  /// Total harvested quantity, or `null` when nothing has been harvested.
  ///
  /// Throws [ConversionUniteIncompatibleException] (via `Quantite +`) if the
  /// recorded harvests mix incompatible unit natures.
  Quantite? quantiteTotaleRecoltee() {
    if (_recoltes.isEmpty) return null;
    return _recoltes
        .map((r) => r.quantite)
        .reduce((total, q) => total + q);
  }

  /// Changes the lifecycle status. Moving to a terminal status requires a
  /// [dateFin] (not before the planting date); moving back to `enCours` clears
  /// the end date and reason.
  void changerStatut(
    StatutPlantation nouveau, {
    DateTime? dateFin,
    String? raison,
  }) {
    if (nouveau == StatutPlantation.enCours) {
      _statut = nouveau;
      _dateFinReelle = null;
      _raisonFin = null;
      return;
    }
    assert(dateFin != null, 'a terminal status requires an end date');
    assert(
      dateFin == null || !dateFin.isBefore(_dateMiseEnPlace),
      'the end date cannot precede the planting date',
    );
    _statut = nouveau;
    _dateFinReelle = dateFin;
    _raisonFin = raison;
  }

  @override
  bool operator ==(Object other) => other is Plantation && other._id == _id;

  @override
  int get hashCode => _id.hashCode;

  @override
  String toString() =>
      'Plantation($_id, plante: $_planteId, parcelle: $_parcelleId, $_statut)';
}
