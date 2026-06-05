import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/domain/exceptions/meteo_indisponible_exception.dart';
import 'package:pot_a_gerer/domain/enums/type_releve_meteo.dart';
import 'package:pot_a_gerer/domain/value_objects/donnees_meteo.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/domain/value_objects/prevision_meteo.dart';
import 'package:pot_a_gerer/infrastructure/api/open_meteo_client.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/repositories/meteo_service_impl.dart';

class MockOpenMeteoClient extends Mock implements OpenMeteoClient {}

void main() {
  final loc =
      Localisation.manuelle(ville: 'Lyon', latitude: 45.75, longitude: 4.85);
  final now = DateTime.utc(2026, 6, 5, 12);

  late AppDatabase db;
  late MockOpenMeteoClient client;
  late MeteoServiceImpl service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    client = MockOpenMeteoClient();
    service = MeteoServiceImpl(db, client, clock: () => now);
  });
  tearDown(() => db.close());

  DonneesMeteo meteoActuelle() => DonneesMeteo(
        date: DateTime.utc(2026, 6, 5),
        tempMin: 12,
        tempMax: 22,
        tempMoyenne: 17,
        precipitationsMm: 0,
        ventVitesseMax: 10,
      );

  Future<void> insererObserve({
    required double tempMin,
    required double tempMax,
    required String date,
    required String dateRecuperation,
  }) {
    return db.into(db.meteoCache).insert(MeteoCacheCompanion.insert(
          id: 'obs-$date',
          latitude: 45.75,
          longitude: 4.85,
          date: date,
          type: 'observe',
          dateRecuperation: dateRecuperation,
          tempMin: Value(tempMin),
          tempMax: Value(tempMax),
          tempMoyenne: Value((tempMin + tempMax) / 2),
        ));
  }

  Future<void> insererPrevu({
    required String date,
    required String dateRecuperation,
    double probabilitePluie = 0.4,
  }) {
    return db.into(db.meteoCache).insert(MeteoCacheCompanion.insert(
          id: 'prev-$date',
          latitude: 45.75,
          longitude: 4.85,
          date: date,
          type: 'prevu',
          dateRecuperation: dateRecuperation,
          tempMin: const Value(10),
          tempMax: const Value(18),
          probabilitePluie: Value(probabilitePluie),
        ));
  }

  group('obtenirMeteoActuelle', () {
    test('serves fresh cache without hitting the network', () async {
      await insererObserve(
        tempMin: 8,
        tempMax: 14,
        date: '2026-06-05',
        dateRecuperation: now.subtract(const Duration(minutes: 30)).toIso8601String(),
      );

      final result = await service.obtenirMeteoActuelle(loc);

      expect(result.tempMin, 8);
      expect(result.tempMax, 14);
      verifyNever(() => client.obtenirMeteoActuelle(loc));
    });

    test('fetches from the network on cache miss and caches the result',
        () async {
      when(() => client.obtenirMeteoActuelle(loc))
          .thenAnswer((_) async => meteoActuelle());

      final result = await service.obtenirMeteoActuelle(loc);

      expect(result.tempMin, 12);
      verify(() => client.obtenirMeteoActuelle(loc)).called(1);
      final rows = await db.select(db.meteoCache).get();
      expect(rows.where((r) => r.type == 'observe'), hasLength(1));
    });

    test('refetches when the cached row is stale', () async {
      await insererObserve(
        tempMin: 8,
        tempMax: 14,
        date: '2026-06-05',
        dateRecuperation: now.subtract(const Duration(hours: 5)).toIso8601String(),
      );
      when(() => client.obtenirMeteoActuelle(loc))
          .thenAnswer((_) async => meteoActuelle());

      final result = await service.obtenirMeteoActuelle(loc);

      expect(result.tempMin, 12);
      verify(() => client.obtenirMeteoActuelle(loc)).called(1);
    });

    test('falls back to stale cache when the network fails', () async {
      await insererObserve(
        tempMin: 8,
        tempMax: 14,
        date: '2026-06-05',
        dateRecuperation: now.subtract(const Duration(hours: 5)).toIso8601String(),
      );
      when(() => client.obtenirMeteoActuelle(loc))
          .thenThrow(MeteoIndisponibleException('offline'));

      final result = await service.obtenirMeteoActuelle(loc);

      expect(result.tempMin, 8);
      expect(result.tempMax, 14);
    });

    test('throws when network fails and nothing is cached', () async {
      when(() => client.obtenirMeteoActuelle(loc))
          .thenThrow(MeteoIndisponibleException('offline'));

      expect(
        () => service.obtenirMeteoActuelle(loc),
        throwsA(isA<MeteoIndisponibleException>()),
      );
    });

    test('throws for an undefined location without calling the network',
        () async {
      await expectLater(
        service.obtenirMeteoActuelle(const Localisation.nonDefinie()),
        throwsA(isA<MeteoIndisponibleException>()),
      );
      verifyNever(() => client.obtenirMeteoActuelle(loc));
    });
  });

  group('obtenirPrevisions', () {
    List<PrevisionMeteo> previsions() => [
          PrevisionMeteo(date: DateTime.utc(2026, 6, 5), tempMin: 12, tempMax: 22, precipitationsMm: 0),
          PrevisionMeteo(date: DateTime.utc(2026, 6, 6), tempMin: 13, tempMax: 24, precipitationsMm: 1),
          PrevisionMeteo(date: DateTime.utc(2026, 6, 7), tempMin: 11, tempMax: 20, precipitationsMm: 5),
        ];

    test('serves fresh cache without hitting the network', () async {
      for (final d in ['2026-06-05', '2026-06-06', '2026-06-07']) {
        await insererPrevu(
          date: d,
          dateRecuperation: now.subtract(const Duration(hours: 1)).toIso8601String(),
        );
      }

      final result = await service.obtenirPrevisions(loc, 3);

      expect(result, hasLength(3));
      verifyNever(() => client.obtenirPrevisions(loc, 3));
    });

    test('fetches, caches, and purges outdated forecasts', () async {
      // A forecast older than the 7-day retention window.
      await insererPrevu(date: '2026-05-01', dateRecuperation: '2026-05-01T08:00:00.000Z');
      when(() => client.obtenirPrevisions(loc, 3))
          .thenAnswer((_) async => previsions());

      final result = await service.obtenirPrevisions(loc, 3);

      expect(result, hasLength(3));
      final prevus =
          (await db.select(db.meteoCache).get()).where((r) => r.type == 'prevu');
      expect(prevus, hasLength(3));
      expect(prevus.any((r) => r.date == '2026-05-01'), isFalse);
    });

    test('refetches when the cache has fewer days than requested', () async {
      await insererPrevu(
        date: '2026-06-05',
        dateRecuperation: now.subtract(const Duration(hours: 1)).toIso8601String(),
      );
      when(() => client.obtenirPrevisions(loc, 3))
          .thenAnswer((_) async => previsions());

      final result = await service.obtenirPrevisions(loc, 3);

      expect(result, hasLength(3));
      verify(() => client.obtenirPrevisions(loc, 3)).called(1);
    });

    test('falls back to stale cache (with rain probability) when offline',
        () async {
      await insererPrevu(
        date: '2026-06-05',
        dateRecuperation: now.subtract(const Duration(days: 2)).toIso8601String(),
        probabilitePluie: 0.7,
      );
      when(() => client.obtenirPrevisions(loc, 3))
          .thenThrow(MeteoIndisponibleException('offline'));

      final result = await service.obtenirPrevisions(loc, 3);

      expect(result, isNotEmpty);
      // The watering engine can still reason offline: probability survived.
      expect(result.first.probabilitePluie, closeTo(0.7, 1e-9));
    });

    test('throws when network fails and nothing is cached', () async {
      when(() => client.obtenirPrevisions(loc, 3))
          .thenThrow(MeteoIndisponibleException('offline'));

      expect(
        () => service.obtenirPrevisions(loc, 3),
        throwsA(isA<MeteoIndisponibleException>()),
      );
    });
  });

  group('obtenirPrevisions window mode (joursPasses > 0)', () {
    // 2 past (observe) + 2 forecast (prevu) days around 2026-06-05.
    List<PrevisionMeteo> fenetre() => [
          PrevisionMeteo(date: DateTime.utc(2026, 6, 3), tempMin: 8, tempMax: 16, precipitationsMm: 2, type: TypeReleveMeteo.observe),
          PrevisionMeteo(date: DateTime.utc(2026, 6, 4), tempMin: 9, tempMax: 17, precipitationsMm: 0, type: TypeReleveMeteo.observe),
          PrevisionMeteo(date: DateTime.utc(2026, 6, 5), tempMin: 11, tempMax: 20, precipitationsMm: 0, type: TypeReleveMeteo.prevu),
          PrevisionMeteo(date: DateTime.utc(2026, 6, 6), tempMin: 12, tempMax: 22, precipitationsMm: 15, type: TypeReleveMeteo.prevu),
        ];

    test('fetches the past+forecast window fresh and caches it', () async {
      when(() => client.obtenirPrevisions(loc, 2, joursPasses: 2))
          .thenAnswer((_) async => fenetre());

      final result = await service.obtenirPrevisions(loc, 2, joursPasses: 2);

      expect(result, hasLength(4));
      expect(result.first.type, TypeReleveMeteo.observe);
      expect(result.last.type, TypeReleveMeteo.prevu);
      final rows = await db.select(db.meteoCache).get();
      expect(rows.where((r) => r.type == 'observe'), hasLength(2));
      expect(rows.where((r) => r.type == 'prevu'), hasLength(2));
    });

    test('falls back to the cached window when offline', () async {
      when(() => client.obtenirPrevisions(loc, 2, joursPasses: 2))
          .thenAnswer((_) async => fenetre());
      await service.obtenirPrevisions(loc, 2, joursPasses: 2); // caches

      when(() => client.obtenirPrevisions(loc, 2, joursPasses: 2))
          .thenThrow(MeteoIndisponibleException('offline'));

      final result = await service.obtenirPrevisions(loc, 2, joursPasses: 2);
      expect(result, hasLength(4));
      expect(result.map((p) => p.type),
          containsAll([TypeReleveMeteo.observe, TypeReleveMeteo.prevu]));
    });
  });
}
