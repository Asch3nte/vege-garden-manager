import '../exceptions/invariant_domaine_exception.dart';

/// Immutable named place returned by a geocoding lookup.
class LieuTrouve {
  final String _nom;
  final String? _region;
  final String? _pays;
  final double _latitude;
  final double _longitude;

  LieuTrouve._(
      this._nom, this._region, this._pays, this._latitude, this._longitude);

  /// Builds a place; blank [region] or [pays] are stored as `null`.
  factory LieuTrouve({
    required String nom,
    String? region,
    String? pays,
    required double latitude,
    required double longitude,
  }) {
    InvariantDomaineException.verifier(
        nom.trim().isNotEmpty, 'place name must not be empty');
    InvariantDomaineException.verifier(
        latitude >= -90 && latitude <= 90, 'latitude must be in [-90, 90]');
    InvariantDomaineException.verifier(longitude >= -180 && longitude <= 180,
        'longitude must be in [-180, 180]');
    return LieuTrouve._(
        nom.trim(), _nonVide(region), _nonVide(pays), latitude, longitude);
  }

  String get nom => _nom;

  /// Administrative region (state, province…), when known.
  String? get region => _region;

  String? get pays => _pays;

  double get latitude => _latitude;

  double get longitude => _longitude;

  static String? _nonVide(String? s) {
    final t = s?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  @override
  bool operator ==(Object other) =>
      other is LieuTrouve &&
      other._nom == _nom &&
      other._region == _region &&
      other._pays == _pays &&
      other._latitude == _latitude &&
      other._longitude == _longitude;

  @override
  int get hashCode => Object.hash(_nom, _region, _pays, _latitude, _longitude);

  @override
  String toString() =>
      'LieuTrouve($_nom, $_region, $_pays, $_latitude, $_longitude)';
}
