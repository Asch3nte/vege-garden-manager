import '../../domain/enums/niveau_soleil.dart';

/// One zone (parcelle) projected for the **Potager** zone list.
///
/// Carries what the list row renders: name, surface, sun exposure, the names of
/// the crops currently growing there and whether the zone needs attention. The
/// crop names are resolved from the catalogue by [PotagerNotifier] (the
/// plantation entity only stores a plant id).
class ZonePotager {
  final String _id;
  final String _nom;
  final double _surfaceM2;
  final NiveauSoleil _exposition;
  final List<String> _cultures;
  final bool _aTacheAujourdhui;

  ZonePotager._(
    this._id,
    this._nom,
    this._surfaceM2,
    this._exposition,
    List<String> cultures,
    this._aTacheAujourdhui,
  ) : _cultures = List.unmodifiable(cultures);

  /// Creates a zone projection. [cultures] are display names, already localized.
  factory ZonePotager({
    required String id,
    required String nom,
    required double surfaceM2,
    required NiveauSoleil exposition,
    required List<String> cultures,
    bool aTacheAujourdhui = false,
  }) =>
      ZonePotager._(id, nom, surfaceM2, exposition, cultures, aTacheAujourdhui);

  /// Zone (parcelle) identifier.
  String get id => _id;

  /// Display name.
  String get nom => _nom;

  /// Surface in square metres.
  double get surfaceM2 => _surfaceM2;

  /// Sun exposure.
  NiveauSoleil get exposition => _exposition;

  /// Localized names of the crops growing in this zone (immutable).
  List<String> get cultures => _cultures;

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
