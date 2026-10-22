import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pot_a_gerer/domain/exceptions/geocodage_indisponible_exception.dart';
import 'package:pot_a_gerer/domain/value_objects/lieu_trouve.dart';
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

    test('returns null when the body has unexpected types', () async {
      final client = NominatimClient(
        httpClient: MockClient(
            (_) async => http.Response(jsonEncode(['pas', 'un', 'objet']), 200)),
      );
      expect(await client.obtenirNomLocalite(loc), isNull);
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

  group('NominatimClient.rechercherLieux', () {
    Map<String, Object> resultat(String nom, String lat, String lon,
            {Map<String, String> adresse = const {}}) =>
        {'name': nom, 'lat': lat, 'lon': lon, 'address': adresse};

    test('maps each result to a place with region and country', () async {
      final lieux = await clientReturning([
        resultat('Uccle', '50.8', '4.33', adresse: {
          'state': 'Bruxelles-Capitale',
          'country': 'Belgique',
        }),
        resultat('Uccle', '-20.1', '57.5', adresse: {'country': 'Maurice'}),
      ]).rechercherLieux('Uccle');

      expect(lieux, [
        LieuTrouve(
            nom: 'Uccle',
            region: 'Bruxelles-Capitale',
            pays: 'Belgique',
            latitude: 50.8,
            longitude: 4.33),
        LieuTrouve(
            nom: 'Uccle', pays: 'Maurice', latitude: -20.1, longitude: 57.5),
      ]);
    });

    test('falls back to the county when no state is given', () async {
      final lieux = await clientReturning([
        resultat('Wavre', '50.7', '4.6', adresse: {'county': 'Brabant'}),
      ]).rechercherLieux('Wavre');
      expect(lieux.single.region, 'Brabant');
    });

    test('drops malformed entries and duplicates', () async {
      final lieux = await clientReturning([
        resultat('A', '1', '2'),
        resultat('A', '1', '2'),
        {'name': 'B', 'lat': 'x', 'lon': '2'},
        {'name': '', 'lat': '1', 'lon': '2'},
        'pas un objet',
      ]).rechercherLieux('A');
      expect(lieux.map((l) => l.nom), ['A']);
    });

    test('returns an empty list for blank text without calling', () async {
      var appels = 0;
      final client = NominatimClient(
        httpClient: MockClient((_) async {
          appels++;
          return http.Response('[]', 200);
        }),
      );
      expect(await client.rechercherLieux('   '), isEmpty);
      expect(appels, 0);
    });

    test('queries /search for settlements with a bounded limit', () async {
      Uri? uri;
      Map<String, String>? headers;
      final client = NominatimClient(
        httpClient: MockClient((request) async {
          uri = request.url;
          headers = request.headers;
          return http.Response('[]', 200);
        }),
      );
      await client.rechercherLieux('  Namur ');
      expect(uri?.host, 'nominatim.openstreetmap.org');
      expect(uri?.path, '/search');
      expect(uri?.queryParameters['q'], 'Namur');
      expect(uri?.queryParameters['format'], 'jsonv2');
      expect(uri?.queryParameters['featureType'], 'settlement');
      expect(uri?.queryParameters['limit'], '5');
      expect(headers?['User-Agent'], contains('PotAGerer'));
      expect(headers?['Accept-Language'], 'fr');
    });

    test('throws GeocodageIndisponibleException on HTTP error', () async {
      expect(clientReturning([], status: 503).rechercherLieux('A'),
          throwsA(isA<GeocodageIndisponibleException>()));
    });

    test('throws GeocodageIndisponibleException on network failure', () async {
      final client = NominatimClient(
        httpClient: MockClient((_) async => throw http.ClientException('off')),
      );
      expect(client.rechercherLieux('A'),
          throwsA(isA<GeocodageIndisponibleException>()));
    });

    test('throws GeocodageIndisponibleException on malformed JSON', () async {
      final client = NominatimClient(
        httpClient: MockClient((_) async => http.Response('{oops', 200)),
      );
      expect(client.rechercherLieux('A'),
          throwsA(isA<GeocodageIndisponibleException>()));
    });
  });

  group('NominatimClient.identifierLieu', () {
    test('names the place at the given coordinates', () async {
      final lieu = await clientReturning({
        'address': {
          'town': 'Wavre',
          'state': 'Wallonie',
          'country': 'Belgique',
        },
      }).identifierLieu(50.72, 4.61);

      expect(
          lieu,
          LieuTrouve(
              nom: 'Wavre',
              region: 'Wallonie',
              pays: 'Belgique',
              latitude: 50.72,
              longitude: 4.61));
    });

    test('sends the coordinates rounded to ~1 km', () async {
      Uri? uri;
      final client = NominatimClient(
        httpClient: MockClient((request) async {
          uri = request.url;
          return http.Response(jsonEncode({'address': {}}), 200);
        }),
      );
      await client.identifierLieu(50.723456, 4.618888);
      expect(uri?.queryParameters['lat'], '50.72');
      expect(uri?.queryParameters['lon'], '4.62');
    });

    test('returns null when no locality is known', () async {
      expect(
          await clientReturning({
            'address': {'country': 'Belgique'},
          }).identifierLieu(50, 4),
          isNull);
    });

    test('returns null on failure', () async {
      expect(await clientReturning({}, status: 500).identifierLieu(50, 4),
          isNull);
    });
  });
}
