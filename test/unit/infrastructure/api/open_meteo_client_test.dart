import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pot_a_gerer/domain/exceptions/meteo_indisponible_exception.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/infrastructure/api/open_meteo_client.dart';

void main() {
  final loc = Localisation.manuelle(ville: 'Lyon', latitude: 45.75, longitude: 4.85);

  Map<String, dynamic> dailyPayload() => {
        'daily': {
          'time': ['2026-06-05', '2026-06-06', '2026-06-07'],
          'temperature_2m_max': [22.0, 35.5, 10.0],
          'temperature_2m_min': [12.0, 20.0, -1.0],
          'precipitation_sum': [0.0, 5.0, 2.0],
          'precipitation_probability_max': [10, 80, 50],
          'wind_speed_10m_max': [15.0, 20.0, 30.0],
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

    test('rejects a non-positive horizon', () async {
      final client = clientReturning(dailyPayload());
      expect(
        () => client.obtenirPrevisions(loc, 0),
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
}

class _Boom implements Exception {
  const _Boom();
}
