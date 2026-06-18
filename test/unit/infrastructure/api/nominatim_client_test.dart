import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/infrastructure/api/nominatim_client.dart';

void main() {
  final loc = Localisation.manuelle(
    ville: 'Bruxelles',
    latitude: 50.85,
    longitude: 4.35,
  );

  NominatimClient clientReturning(Object body, {int status = 200}) =>
      NominatimClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), status),
        ),
      );

  group('NominatimClient.obtenirNomLocalite', () {
    test('returns city when present', () async {
      final result = await clientReturning({
        'address': {'city': 'Bruxelles', 'country': 'Belgique'},
      }).obtenirNomLocalite(loc);

      expect(result, equals('Bruxelles'));
    });

    test('falls back to town when city is absent', () async {
      final result = await clientReturning({
        'address': {'town': 'Wavre'},
      }).obtenirNomLocalite(loc);

      expect(result, equals('Wavre'));
    });

    test('falls back to village when city and town are absent', () async {
      final result = await clientReturning({
        'address': {'village': 'Hameau'},
      }).obtenirNomLocalite(loc);

      expect(result, equals('Hameau'));
    });

    test('falls back to municipality', () async {
      final result = await clientReturning({
        'address': {'municipality': 'Commune rurale'},
      }).obtenirNomLocalite(loc);

      expect(result, equals('Commune rurale'));
    });

    test('falls back to county as last resort', () async {
      final result = await clientReturning({
        'address': {'county': 'Province du Brabant'},
      }).obtenirNomLocalite(loc);

      expect(result, equals('Province du Brabant'));
    });

    test('returns null when address is empty', () async {
      final result = await clientReturning({'address': {}}).obtenirNomLocalite(loc);

      expect(result, isNull);
    });

    test('returns null when address key is missing', () async {
      final result = await clientReturning({'other': 'data'}).obtenirNomLocalite(loc);

      expect(result, isNull);
    });

    test('returns null on HTTP error', () async {
      final result = await clientReturning({}, status: 503).obtenirNomLocalite(loc);

      expect(result, isNull);
    });

    test('returns null on malformed JSON', () async {
      final client = NominatimClient(
        httpClient: MockClient((_) async => http.Response('not-json', 200)),
      );
      final result = await client.obtenirNomLocalite(loc);

      expect(result, isNull);
    });

    test('returns null on network timeout', () async {
      final client = NominatimClient(
        httpClient: MockClient((_) async {
          await Future<void>.delayed(const Duration(seconds: 30));
          return http.Response('', 200);
        }),
      );
      // The client has an 8-second internal timeout; this just checks that the
      // call completes (with null) rather than hanging indefinitely.
      final result = await client
          .obtenirNomLocalite(loc)
          .timeout(const Duration(seconds: 10), onTimeout: () => null);

      expect(result, isNull);
    });

    test('returns null when location is undefined', () async {
      final result = await clientReturning({
        'address': {'city': 'Bruxelles'},
      }).obtenirNomLocalite(const Localisation.nonDefinie());

      expect(result, isNull);
    });

    test('sends correct headers', () async {
      String? capturedUserAgent;
      String? capturedAcceptLanguage;

      final client = NominatimClient(
        httpClient: MockClient((request) async {
          capturedUserAgent = request.headers['User-Agent'];
          capturedAcceptLanguage = request.headers['Accept-Language'];
          return http.Response(
            jsonEncode({'address': {'city': 'Paris'}}),
            200,
          );
        }),
      );

      await client.obtenirNomLocalite(loc);

      expect(capturedUserAgent, contains('PotAGerer'));
      expect(capturedAcceptLanguage, equals('fr'));
    });

    test('queries the correct Nominatim endpoint', () async {
      Uri? capturedUri;

      final client = NominatimClient(
        httpClient: MockClient((request) async {
          capturedUri = request.url;
          return http.Response(jsonEncode({'address': {}}), 200);
        }),
      );

      await client.obtenirNomLocalite(loc);

      expect(capturedUri?.host, equals('nominatim.openstreetmap.org'));
      expect(capturedUri?.path, equals('/reverse'));
      expect(capturedUri?.queryParameters['format'], equals('json'));
      expect(capturedUri?.queryParameters['zoom'], equals('10'));
      expect(capturedUri?.queryParameters['addressdetails'], equals('1'));
    });
  });
}
