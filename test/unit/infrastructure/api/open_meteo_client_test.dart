import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pot_a_gerer/domain/enums/type_releve_meteo.dart';
import 'package:pot_a_gerer/domain/exceptions/meteo_indisponible_exception.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/infrastructure/api/open_meteo_client.dart';

void main() {
  final loc = Localisation.manuelle(ville: 'Lyon', latitude: 45.75, longitude: 4.85);

  Map<String, dynamic> dailyPayload() => {
        'elevation': 200.0,
        'daily': {
          'time': ['2026-06-05', '2026-06-06', '2026-06-07'],
          'temperature_2m_max': [22.0, 35.5, 10.0],
          'temperature_2m_min': [12.0, 20.0, -1.0],
          'precipitation_sum': [0.0, 5.0, 2.0],
          'precipitation_probability_max': [10, 80, 50],
          'wind_speed_10m_max': [15.0, 20.0, 30.0],
          'weather_code': [1, 61, 3],
        },
      };

  Map<String, dynamic> hourlyPayload() => {
        'elevation': 65.0,
        'hourly': {
          'time': ['2026-06-05T00:00', '2026-06-05T01:00', '2026-06-05T02:00'],
          'temperature_2m': [18.0, 17.5, 17.0],
          'precipitation': [0.0, 0.2, 1.5],
          'precipitation_probability': [0, 20, 80],
          'weather_code': [0, 51, 61],
          'wind_speed_10m': [5.0, 8.0, 15.0],
        },
      };

  OpenMeteoClient clientReturning(Map<String, dynamic> payload,
      {int status = 200}) {
    return OpenMeteoClient(
      httpClient:
          MockClient((_) async => http.Response(jsonEncode(payload), status)),
    );
  }

  group('obtenirMeteoActuelle', () {
    test('maps day 0 and computes mean temperature', () async {
      final meteo = await clientReturning(dailyPayload()).obtenirMeteoActuelle(loc);

      expect(meteo.date, DateTime.parse('2026-06-05'));
      expect(meteo.tempMin, 12.0);
      expect(meteo.tempMax, 22.0);
      expect(meteo.tempMoyenne, 17.0);
      expect(meteo.precipitationsMm, 0.0);
      expect(meteo.ventVitesseMax, 15.0);
      expect(meteo.risqueGel, isFalse);
      expect(meteo.risqueCanicule, isFalse);
    });

    test('flags frost when tempMin <= 0', () async {
      final payload = dailyPayload();
      (payload['daily'] as Map)['temperature_2m_min'] = [-0.5];
      (payload['daily'] as Map)['temperature_2m_max'] = [5.0];
      (payload['daily'] as Map)['time'] = ['2026-01-10'];

      final meteo = await clientReturning(payload).obtenirMeteoActuelle(loc);
      expect(meteo.risqueGel, isTrue);
      expect(meteo.risqueCanicule, isFalse);
    });

    test('flags heatwave when tempMax >= 35', () async {
      final payload = dailyPayload();
      (payload['daily'] as Map)['temperature_2m_min'] = [20.0];
      (payload['daily'] as Map)['temperature_2m_max'] = [36.0];
      (payload['daily'] as Map)['time'] = ['2026-07-15'];

      final meteo = await clientReturning(payload).obtenirMeteoActuelle(loc);
      expect(meteo.risqueCanicule, isTrue);
      expect(meteo.risqueGel, isFalse);
    });

    test('throws when location is undefined', () async {
      final client = clientReturning(dailyPayload());
      expect(
        () => client.obtenirMeteoActuelle(const Localisation.nonDefinie()),
        throwsA(isA<MeteoIndisponibleException>()),
      );
    });

    test('throws on non-200 status', () async {
      final client = clientReturning(const {}, status: 500);
      expect(
        () => client.obtenirMeteoActuelle(loc),
        throwsA(isA<MeteoIndisponibleException>()),
      );
    });

    test('throws on unparseable body', () async {
      final client = OpenMeteoClient(
        httpClient: MockClient((_) async => http.Response('not json', 200)),
      );
      expect(
        () => client.obtenirMeteoActuelle(loc),
        throwsA(isA<MeteoIndisponibleException>()),
      );
    });

    test('wraps transport errors as MeteoIndisponibleException', () async {
      final client = OpenMeteoClient(
        httpClient: MockClient((_) async => throw const _Boom()),
      );
      await expectLater(
        client.obtenirMeteoActuelle(loc),
        throwsA(
          isA<MeteoIndisponibleException>()
              .having((e) => e.cause, 'cause', isA<_Boom>()),
        ),
      );
    });
  });

  group('obtenirPrevisions', () {
    test('maps all days and converts rain probability to 0..1', () async {
      final previsions =
          await clientReturning(dailyPayload()).obtenirPrevisions(loc, 3);

      expect(previsions, hasLength(3));
      expect(previsions[1].date, DateTime.parse('2026-06-06'));
      expect(previsions[1].tempMin, 20.0);
      expect(previsions[1].tempMax, 35.5);
      expect(previsions[1].precipitationsMm, 5.0);
      expect(previsions[1].probabilitePluie, closeTo(0.8, 1e-9));
    });

    test('maps weathercode per day', () async {
      final previsions =
          await clientReturning(dailyPayload()).obtenirPrevisions(loc, 3);

      expect(previsions[0].weathercode, 1);  // mainly clear
      expect(previsions[1].weathercode, 61); // rain
      expect(previsions[2].weathercode, 3);  // overcast
    });

    test('rejects a non-positive horizon', () async {
      final client = clientReturning(dailyPayload());
      expect(
        () => client.obtenirPrevisions(loc, 0),
        throwsA(isA<MeteoIndisponibleException>()),
      );
    });

    test('with joursPasses, requests past_days and tags observe/prevu by index',
        () async {
      late Uri requested;
      final client = OpenMeteoClient(
        httpClient: MockClient((req) async {
          requested = req.url;
          return http.Response(jsonEncode(dailyPayload()), 200);
        }),
      );

      // payload has 3 days: with joursPasses=1, day 0 = observe, 1..2 = prevu.
      final fenetre = await client.obtenirPrevisions(loc, 2, joursPasses: 1);

      expect(requested.queryParameters['past_days'], '1');
      expect(requested.queryParameters['forecast_days'], '2');
      expect(fenetre[0].type, TypeReleveMeteo.observe);
      expect(fenetre[1].type, TypeReleveMeteo.prevu);
      expect(fenetre[2].type, TypeReleveMeteo.prevu);
    });

    test('rejects a negative past-day count', () async {
      final client = clientReturning(dailyPayload());
      expect(
        () => client.obtenirPrevisions(loc, 3, joursPasses: -1),
        throwsA(isA<MeteoIndisponibleException>()),
      );
    });

    test('throws when location is undefined', () async {
      final client = clientReturning(dailyPayload());
      expect(
        () => client.obtenirPrevisions(const Localisation.nonDefinie(), 3),
        throwsA(isA<MeteoIndisponibleException>()),
      );
    });
  });

  group('obtenirPrevisionsHoraires', () {
    test('maps temperature, precipitation and probability', () async {
      final heures =
          await clientReturning(hourlyPayload()).obtenirPrevisionsHoraires(loc);

      expect(heures, hasLength(3));
      expect(heures[0].temperature, 18.0);
      expect(heures[0].precipitationsMm, 0.0);
      expect(heures[0].probabilitePluie, 0.0);
    });

    test('maps weathercode per hour', () async {
      final heures =
          await clientReturning(hourlyPayload()).obtenirPrevisionsHoraires(loc);

      expect(heures[0].weathercode, 0);  // clear sky
      expect(heures[1].weathercode, 51); // drizzle
      expect(heures[2].weathercode, 61); // rain
    });

    test('maps wind speed per hour', () async {
      final heures =
          await clientReturning(hourlyPayload()).obtenirPrevisionsHoraires(loc);

      expect(heures[0].ventKmh, 5.0);
      expect(heures[1].ventKmh, 8.0);
      expect(heures[2].ventKmh, 15.0);
    });

    test('converts rain probability from 0..100 to 0..1', () async {
      final heures =
          await clientReturning(hourlyPayload()).obtenirPrevisionsHoraires(loc);

      expect(heures[1].probabilitePluie, closeTo(0.2, 1e-9));
      expect(heures[2].probabilitePluie, closeTo(0.8, 1e-9));
    });

    test('rejects a non-positive horizon', () async {
      expect(
        () => clientReturning(hourlyPayload()).obtenirPrevisionsHoraires(loc, nbJours: 0),
        throwsA(isA<MeteoIndisponibleException>()),
      );
    });

    test('throws when location is undefined', () async {
      expect(
        () => clientReturning(hourlyPayload())
            .obtenirPrevisionsHoraires(const Localisation.nonDefinie()),
        throwsA(isA<MeteoIndisponibleException>()),
      );
    });
  });

  group('obtenirElevation', () {
    test('returns elevation from response metadata', () async {
      final elevation =
          await clientReturning(hourlyPayload()).obtenirElevation(loc);

      expect(elevation, 65.0);
    });

    test('returns null when elevation key is missing', () async {
      final payload = Map<String, dynamic>.from(hourlyPayload())
        ..remove('elevation');
      final elevation = await clientReturning(payload).obtenirElevation(loc);

      expect(elevation, isNull);
    });

    test('returns null when location is undefined', () async {
      final elevation = await clientReturning(hourlyPayload())
          .obtenirElevation(const Localisation.nonDefinie());

      expect(elevation, isNull);
    });

    test('returns null on HTTP error (never throws)', () async {
      final elevation =
          await clientReturning({}, status: 500).obtenirElevation(loc);

      expect(elevation, isNull);
    });

    test('returns null on network failure (never throws)', () async {
      final client = OpenMeteoClient(
        httpClient: MockClient((_) async => throw const _Boom()),
      );
      final elevation = await client.obtenirElevation(loc);

      expect(elevation, isNull);
    });
  });
}

class _Boom implements Exception {
  const _Boom();
}

