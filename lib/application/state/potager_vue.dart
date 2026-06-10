import '../../domain/enums/niveau_soleil.dart';
import '../../domain/enums/type_parcelle.dart';

/// One active crop of a zone, projected for the UI.
///
/// Carries the [plantationId] (so the zone detail can act on it — pull out,
/// remove) alongside the catalogue-resolved display [nom].
class CulturePotager {
  final String plantationId;
  final String nom;

  const CulturePotager({required this.plantationId, required this.nom});

  @override
  bool operator ==(Object other) =>
      other is CulturePotager &&
      other.plantationId == plantationId &&
      other.nom == nom;

  @override
  int get hashCode => Object.hash(plantationId, nom);
}

/// One zone (parcelle) projected for the **Potager** plan.
///
/// Carries what a plan bed renders: name, [type] (so a greenhouse can span the
/// full width of the grid), surface, sun exposure, the names of the crops
/// currently growing there and whether the zone needs attention. The crop names
/// are resolved from the catalogue by [PotagerNotifier] (the plantation entity
/// only stores a plant id).
class ZonePotager {
  final String _id;
  final String _nom;
  final TypeParcelle _type;
  final double _surfaceM2;
  final NiveauSoleil _exposition;
  final List<CulturePotager> _cultures;
  final bool _aTacheAujourdhui;

  ZonePotager._(
    this._id,
    this._nom,
    this._type,
    this._surfaceM2,
    this._exposition,
    List<CulturePotager> cultures,
    this._aTacheAujourdhui,
  ) : _cultures = List.unmodifiable(cultures);

  /// Creates a zone projection. [cultures] are the active crops (id + name).
  factory ZonePotager({
    required String id,
    required String nom,
    required TypeParcelle type,
    required double surfaceM2,
    required NiveauSoleil exposition,
    required List<CulturePotager> cultures,
    bool aTacheAujourdhui = false,
  }) =>
      ZonePotager._(
        id,
        nom,
        type,
        surfaceM2,
        exposition,
        cultures,
        aTacheAujourdhui,
      );

  /// Zone (parcelle) identifier.
  String get id => _id;

  /// Display name.
  String get nom => _nom;

  /// Physical structure of the zone (drives the full-width greenhouse bed).
  TypeParcelle get type => _type;

  /// Surface in square metres.
  double get surfaceM2 => _surfaceM2;

  /// Sun exposure.
  NiveauSoleil get exposition => _exposition;

  /// Active crops growing in this zone (immutable).
  List<CulturePotager> get cultures => _cultures;

  /// Whether the zone has a task due today (drives the attention marker).
  bool get aTacheAujourdhui => _aTacheAujourdhui;

  /// Number of active crops in this zone.
  int get nombreCultures => _cultures.length;
}

/// Immutable view-model for the **Potager** screen: the active garden's zones.
///
/// Built by [PotagerNotifier]. When [nomPotager] is `null` there is no active
/// garden yet (the screen shows an onboarding-style empty state).
class PotagerVue {
  final String? _potagerId;
  final String? _nomPotager;
  final List<ZonePotager> _zones;

  PotagerVue._(this._potagerId, this._nomPotager, List<ZonePotager> zones)
      : _zones = List.unmodifiable(zones);

  /// Assembles the Potager view-model. Zones are copied as unmodifiable.
  factory PotagerVue({
    required String? potagerId,
    required String? nomPotager,
    required List<ZonePotager> zones,
  }) =>
      PotagerVue._(potagerId, nomPotager, zones);

  /// Id of the active garden, or `null` when none exists yet.
  String? get potagerId => _potagerId;

  /// Name of the active garden, or `null` when none exists yet.
  String? get nomPotager => _nomPotager;

  /// Zones of the active garden (immutable), in display order.
  List<ZonePotager> get zones => _zones;

  /// Number of zones.
  int get nombreZones => _zones.length;

  /// Whether there is no active garden / no zone yet (drives the empty state).
  bool get estVide => _nomPotager == null || _zones.isEmpty;
}
