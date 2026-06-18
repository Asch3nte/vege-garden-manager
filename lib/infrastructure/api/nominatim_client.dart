import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/value_objects/localisation.dart';

/// Thin HTTP client for the **Nominatim / OpenStreetMap** reverse-geocoding
/// API (`https://nominatim.openstreetmap.org/reverse`).
///
/// Used solely to resolve a [Localisation] (coordinates already rounded to
/// ~1 km by the VO) into a human-readable city/town/village name.
///
/// **OSM usage-policy compliance** (ADR-0016):
/// - A meaningful `User-Agent` header is sent on every request.
/// - At most one request is made per user-initiated screen opening (the result
///   is cached at the Riverpod provider level for the session).
/// - Results are never bulk-queried, stored in the app database, or
///   redistributed.
///
/// Returns `null` — never throws — when the location is undefined, the network
/// call fails, or the response contains no recognisable locality name.
class NominatimClient {
  static const String _baseUrl = 'nominatim.openstreetmap.org';
  static const String _userAgent = 'PotAGerer/1.0 (open-source potager app)';
  static const Duration _timeout = Duration(seconds: 8);

  /// Locality-name fallback order mirroring OSM address levels (coarsest
  /// that reliably yields a useful name at zoom 10).
  static const List<String> _adresseFallback = [
    'city',
    'town',
    'village',
    'municipality',
    'county',
  ];

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

    final uri = Uri.https(_baseUrl, '/reverse', {
      'lat': '${loc.latitude}',
      'lon': '${loc.longitude}',
      'format': 'json',
      'zoom': '10', // city-level precision
      'addressdetails': '1',
    });

    final http.Response response;
    try {
      response = await _httpClient.get(uri, headers: {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
        'Accept-Language': 'fr',
      }).timeout(_timeout);
    } catch (_) {
      return null;
    }

    if (response.statusCode != 200) return null;

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final address = body['address'] as Map<String, dynamic>?;
      if (address == null) return null;

      for (final key in _adresseFallback) {
        final value = address[key];
        if (value is String && value.isNotEmpty) return value;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Releases the underlying [http.Client] when it is owned by this instance.
  void close() => _httpClient.close();
}
