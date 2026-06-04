import '../enums/source_localisation.dart';

/// Immutable value object describing where a potager is located.
///
/// Privacy is enforced by design: coordinates are **rounded to ~1 km** (2
/// decimals) at construction, and a location can be left undefined (opt-out).
/// The VO carries the data origin ([SourceLocalisation]) but never the user's
/// global geolocation preference (that lives in the preferences).
///
/// Domain names are kept in French; the code is documented in English.
/// See `docs/05-modele-de-domaine.md` §4.3.
class Localisation {
  final double? _latitude;
  final double? _longitude;
  final String? _ville;
  final SourceLocalisation _source;

  const Localisation._(
    this._latitude,
    this._longitude,
    this._ville,
    this._source,
  );

  /// No location set — the privacy default (opt-out).
  const Localisation.nonDefinie()
      : _latitude = null,
        _longitude = null,
        _ville = null,
        _source = SourceLocalisation.nonDefinie;

  /// Location entered manually by the user (a city name and coordinates).
  /// Coordinates are rounded to ~1 km for privacy.
  factory Localisation.manuelle({
    required String ville,
    required double latitude,
    required double longitude,
  }) {
    _validerCoordonnees(latitude, longitude);
    return Localisation._(
      _arrondir(latitude),
      _arrondir(longitude),
      ville,
      SourceLocalisation.manuelle,
    );
  }

  /// Location obtained from the device GPS. Coordinates are rounded to ~1 km for
  /// privacy; no city name is attached.
  factory Localisation.gps({
    required double latitude,
    required double longitude,
  }) {
    _validerCoordonnees(latitude, longitude);
    return Localisation._(
      _arrondir(latitude),
      _arrondir(longitude),
      null,
      SourceLocalisation.gps,
    );
  }

  /// Rounded latitude (~1 km precision), or `null` when undefined.
  double? get latitude => _latitude;

  /// Rounded longitude (~1 km precision), or `null` when undefined.
  double? get longitude => _longitude;

  /// City name, when known (manual entry), otherwise `null`.
  String? get ville => _ville;

  /// Origin of this location's data.
  SourceLocalisation get source => _source;

  /// Whether usable coordinates are available.
  bool get estDefinie => _latitude != null && _longitude != null;

  /// Rounds a coordinate to ~1 km precision (2 decimals) for privacy.
  static double _arrondir(double coord) => (coord * 100).roundToDouble() / 100;

  static void _validerCoordonnees(double latitude, double longitude) {
    assert(
      latitude >= -90 && latitude <= 90,
      'latitude must be in [-90, 90]',
    );
    assert(
      longitude >= -180 && longitude <= 180,
      'longitude must be in [-180, 180]',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Localisation &&
      other._latitude == _latitude &&
      other._longitude == _longitude &&
      other._ville == _ville &&
      other._source == _source;

  @override
  int get hashCode => Object.hash(_latitude, _longitude, _ville, _source);

  @override
  String toString() => _source == SourceLocalisation.nonDefinie
      ? 'Localisation.nonDefinie()'
      : 'Localisation($_latitude, $_longitude, '
          'ville: $_ville, source: ${_source.name})';
}
