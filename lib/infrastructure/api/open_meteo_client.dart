import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/constantes_moteur.dart';
import '../../domain/exceptions/meteo_indisponible_exception.dart';
import '../../domain/value_objects/donnees_meteo.dart';
import '../../domain/value_objects/localisation.dart';
import '../../domain/value_objects/prevision_meteo.dart';

/// Thin HTTP client for the **Open-Meteo** forecast API
/// (`https://api.open-meteo.com/v1/forecast`).
///
/// This is the only network dependency of the app (privacy by design: no key,
/// no account, coordinates rounded to ~1 km by [Localisation]). It performs a
/// pure request → DTO translation and holds **no** cache; caching and the
/// degraded offline fallback live in `MeteoServiceImpl`.
///
/// The [http.Client] is injected so it can be mocked in tests. Any transport,
/// non-200 status, or parse failure is surfaced as a typed
/// [MeteoIndisponibleException].
class OpenMeteoClient {
  /// Open-Meteo daily variables requested for every call.
  static const _dailyVariables =
      'temperature_2m_max,temperature_2m_min,precipitation_sum,'
      'precipitation_probability_max,wind_speed_10m_max';

  /// V1 frost threshold (°C) flagging [DonneesMeteo.risqueGel]; mirrors the
  /// engine's single source of truth ([SeuilsMeteo.gelC]).
  static const double seuilGelC = SeuilsMeteo.gelC;

  /// V1 heatwave threshold (°C) flagging [DonneesMeteo.risqueCanicule]; mirrors
  /// [SeuilsMeteo.caniculeC].
  static const double seuilCaniculeC = SeuilsMeteo.caniculeC;

  /// Maximum time to wait for the remote service before giving up.
  static const Duration _timeout = Duration(seconds: 10);

  final http.Client _httpClient;

  OpenMeteoClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Today's observed-style weather at [loc] (single day, day 0).
  ///
  /// `tempMoyenne` is approximated as the midpoint of the daily min/max.
  ///
  /// Throws [MeteoIndisponibleException] if [loc] has no coordinates, or on any
  /// network/parse error.
  Future<DonneesMeteo> obtenirMeteoActuelle(Localisation loc) async {
    final daily = await _fetchDaily(loc, nbJours: 1);
    return _donneesMeteoDuJour(daily, 0);
  }

  /// Forecast for the next [nbJours] days at [loc].
  ///
  /// Throws [MeteoIndisponibleException] if [loc] has no coordinates,
  /// if [nbJours] is not strictly positive, or on any network/parse error.
  Future<List<PrevisionMeteo>> obtenirPrevisions(
    Localisation loc,
    int nbJours,
  ) async {
    if (nbJours <= 0) {
      throw MeteoIndisponibleException(
        'Forecast horizon must be strictly positive (got $nbJours).',
      );
    }
    final daily = await _fetchDaily(loc, nbJours: nbJours);
    final dates = (daily['time'] as List);
    return List<PrevisionMeteo>.generate(
      dates.length,
      (i) => _previsionDuJour(daily, i),
    );
  }

  /// Performs the HTTP GET and returns the decoded `daily` object.
  Future<Map<String, dynamic>> _fetchDaily(
    Localisation loc, {
    required int nbJours,
  }) async {
    if (!loc.estDefinie) {
      throw MeteoIndisponibleException(
        'Cannot fetch weather: location is undefined (geolocation opt-out).',
      );
    }
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '${loc.latitude}',
      'longitude': '${loc.longitude}',
      'daily': _dailyVariables,
      'timezone': 'auto',
      'forecast_days': '$nbJours',
    });

    final http.Response response;
    try {
      response = await _httpClient.get(uri).timeout(_timeout);
    } catch (e) {
      throw MeteoIndisponibleException(
        'Open-Meteo request failed: $uri',
        cause: e,
      );
    }
    if (response.statusCode != 200) {
      throw MeteoIndisponibleException(
        'Open-Meteo returned HTTP ${response.statusCode} for $uri.',
      );
    }
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final daily = body['daily'] as Map<String, dynamic>;
      if (daily['time'] is! List) {
        throw const FormatException('missing "daily.time" array');
      }
      return daily;
    } catch (e) {
      throw MeteoIndisponibleException(
        'Could not parse Open-Meteo response from $uri.',
        cause: e,
      );
    }
  }

  DonneesMeteo _donneesMeteoDuJour(Map<String, dynamic> daily, int i) {
    final tempMin = _at(daily, 'temperature_2m_min', i);
    final tempMax = _at(daily, 'temperature_2m_max', i);
    return DonneesMeteo(
      date: DateTime.parse((daily['time'] as List)[i] as String),
      tempMin: tempMin,
      tempMax: tempMax,
      tempMoyenne: (tempMin + tempMax) / 2,
      precipitationsMm: _at(daily, 'precipitation_sum', i),
      ventVitesseMax: _at(daily, 'wind_speed_10m_max', i),
      risqueGel: tempMin <= seuilGelC,
      risqueCanicule: tempMax >= seuilCaniculeC,
    );
  }

  PrevisionMeteo _previsionDuJour(Map<String, dynamic> daily, int i) {
    return PrevisionMeteo(
      date: DateTime.parse((daily['time'] as List)[i] as String),
      tempMin: _at(daily, 'temperature_2m_min', i),
      tempMax: _at(daily, 'temperature_2m_max', i),
      precipitationsMm: _at(daily, 'precipitation_sum', i),
      // Open-Meteo reports probability as a 0..100 percentage; the DTO is 0..1.
      probabilitePluie: _at(daily, 'precipitation_probability_max', i) / 100,
    );
  }

  /// Reads index [i] of daily variable [key] as a double; absent/null → 0.
  double _at(Map<String, dynamic> daily, String key, int i) {
    final values = daily[key];
    if (values is! List || i >= values.length) return 0;
    final v = values[i];
    return v is num ? v.toDouble() : 0;
  }

  /// Releases the underlying [http.Client]. Call when the client is no longer
  /// needed (not when an external client was injected and is owned elsewhere).
  void close() => _httpClient.close();
}
