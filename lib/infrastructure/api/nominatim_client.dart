import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../../domain/exceptions/geocodage_indisponible_exception.dart';
import '../../domain/value_objects/lieu_trouve.dart';
import '../../domain/value_objects/localisation.dart';

/// Thin HTTP client for the **Nominatim / OpenStreetMap** geocoding API:
/// reverse lookup (`/reverse`) and place search (`/search`).
///
/// **OSM usage-policy compliance**:
/// - A meaningful `User-Agent` header is sent on every request.
/// - Requests are user-initiated only: one search per submitted query (never
///   as-you-type), one reverse lookup per chosen point.
/// - Results are never bulk-queried or redistributed.
class NominatimClient {
  static const String _baseUrl = 'nominatim.openstreetmap.org';
  static const String _userAgent = 'PotAGerer/1.0 (open-source potager app)';
  static const Duration _timeout = Duration(seconds: 8);
  static const int _limiteRecherche = 5;

  /// Locality-name fallback order mirroring OSM address levels (coarsest
  /// that reliably yields a useful name at zoom 10).
  static const List<String> _adresseFallback = [
    'city',
    'town',
    'village',
    'municipality',
    'county',
  ];

  static const List<String> _regionFallback = ['state', 'region', 'county'];

  final http.Client _httpClient;

  NominatimClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Returns the nearest locality name for [loc], or `null` on any failure.
  ///
  /// Uses `Accept-Language: fr` to prefer French place names. Falls back
  /// through `city → town → village → municipality → county`; returns `null`
  /// when none is present.
  Future<String?> obtenirNomLocalite(Localisation loc) async {
    if (!loc.estDefinie) return null;
    final address = await _adresseInverse(loc.latitude!, loc.longitude!);
    return address == null ? null : _premier(address, _adresseFallback);
  }

  /// Names the locality at ([latitude], [longitude]), or `null` on failure or
  /// when no locality is known there. The returned place keeps the given
  /// coordinates; only rounded ones (~1 km) are sent.
  Future<LieuTrouve?> identifierLieu(double latitude, double longitude) async {
    final address =
        await _adresseInverse(_arrondir(latitude), _arrondir(longitude));
    if (address == null) return null;
    final nom = _premier(address, _adresseFallback);
    if (nom == null) return null;
    return LieuTrouve(
      nom: nom,
      region: _premier(address, _regionFallback),
      pays: _texte(address['country']),
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Searches settlements matching [texte] (at most five, duplicates and
  /// malformed entries dropped). Blank text returns an empty list without a
  /// request.
  ///
  /// Throws [GeocodageIndisponibleException] when the service is unreachable
  /// or its response is unreadable.
  Future<List<LieuTrouve>> rechercherLieux(String texte) async {
    final q = texte.trim();
    if (q.isEmpty) return const [];
    final body = await _getJson(Uri.https(_baseUrl, '/search', {
      'q': q,
      'format': 'jsonv2',
      'addressdetails': '1',
      'featureType': 'settlement',
      'limit': '$_limiteRecherche',
    }));
    if (body is! List) {
      throw GeocodageIndisponibleException('Unexpected search response shape');
    }
    final lieux = <LieuTrouve>{};
    for (final item in body) {
      final lieu = _lieuDepuisRecherche(item);
      if (lieu != null) lieux.add(lieu);
    }
    return List.unmodifiable(lieux);
  }

  /// Releases the underlying [http.Client] when it is owned by this instance.
  void close() => _httpClient.close();

  Future<Map<dynamic, dynamic>?> _adresseInverse(
      double latitude, double longitude) async {
    final Object? body;
    try {
      body = await _getJson(Uri.https(_baseUrl, '/reverse', {
        'lat': '$latitude',
        'lon': '$longitude',
        'format': 'json',
        'zoom': '10', // city-level precision
        'addressdetails': '1',
      }));
    } on GeocodageIndisponibleException catch (e) {
      developer.log('Reverse geocoding failed', name: 'nominatim', error: e);
      return null;
    }
    final address = body is Map ? body['address'] : null;
    return address is Map ? address : null;
  }

  Future<Object?> _getJson(Uri uri) async {
    final http.Response response;
    try {
      response = await _httpClient.get(uri, headers: {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
        'Accept-Language': 'fr',
      }).timeout(_timeout);
    } on Exception catch (e) {
      throw GeocodageIndisponibleException('Nominatim unreachable', cause: e);
    }
    if (response.statusCode != 200) {
      throw GeocodageIndisponibleException(
          'Nominatim answered ${response.statusCode}');
    }
    try {
      return jsonDecode(response.body);
    } on FormatException catch (e) {
      throw GeocodageIndisponibleException('Unreadable Nominatim response',
          cause: e);
    }
  }

  static LieuTrouve? _lieuDepuisRecherche(Object? item) {
    if (item is! Map) return null;
    final address = item['address'];
    final adresse = address is Map ? address : const {};
    final nom = _texte(item['name']) ?? _premier(adresse, _adresseFallback);
    final lat = double.tryParse('${item['lat']}');
    final lon = double.tryParse('${item['lon']}');
    if (nom == null || lat == null || lon == null) return null;
    if (lat.abs() > 90 || lon.abs() > 180) return null;
    return LieuTrouve(
      nom: nom,
      region: _premier(adresse, _regionFallback),
      pays: _texte(adresse['country']),
      latitude: lat,
      longitude: lon,
    );
  }

  static String? _premier(Map<dynamic, dynamic> address, List<String> cles) {
    for (final cle in cles) {
      final valeur = _texte(address[cle]);
      if (valeur != null) return valeur;
    }
    return null;
  }

  static String? _texte(Object? valeur) =>
      valeur is String && valeur.trim().isNotEmpty ? valeur.trim() : null;

  static double _arrondir(double coord) => (coord * 100).roundToDouble() / 100;
}
