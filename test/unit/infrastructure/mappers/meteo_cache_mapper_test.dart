import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/type_releve_meteo.dart';
import 'package:pot_a_gerer/domain/value_objects/donnees_meteo.dart';
import 'package:pot_a_gerer/domain/value_objects/prevision_meteo.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/mappers/meteo_cache_mapper.dart';

void main() {
  const mapper = MeteoCacheMapper();
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('cacheId is deterministic and tagged by type', () {
    final observe =
        mapper.cacheId(45.75, 4.85, '2026-06-05', TypeReleveMeteo.observe);
    expect(observe,
        mapper.cacheId(45.75, 4.85, '2026-06-05', TypeReleveMeteo.observe));
    expect(observe,
        isNot(mapper.cacheId(45.75, 4.85, '2026-06-05', TypeReleveMeteo.prevu)));
  });

  test('observed-weather row round-trips through the database', () async {
    final meteo = DonneesMeteo(
      date: DateTime.utc(2026, 1, 10),
      tempMin: -1,
      tempMax: 5,
      tempMoyenne: 2,
      precipitationsMm: 3.5,
      ventVitesseMax: 22,
      risqueGel: true,
    );

    await db.into(db.meteoCache).insertOnConflictUpdate(
          mapper.versCompanionObserve(
            meteo,
            latitude: 45.75,
            longitude: 4.85,
            date: '2026-01-10',
            dateRecuperation: '2026-01-10T08:00:00.000Z',
          ),
        );

    final rows = await db.select(db.meteoCache).get();
    expect(rows, hasLength(1));
    final dto = mapper.versDonneesMeteo(rows.single);
    expect(dto.date, DateTime.parse('2026-01-10'));
    expect(dto.tempMin, -1);
    expect(dto.tempMax, 5);
    expect(dto.tempMoyenne, 2);
    expect(dto.precipitationsMm, 3.5);
    expect(dto.ventVitesseMax, 22);
    expect(dto.risqueGel, isTrue);
    expect(dto.risqueCanicule, isFalse);
  });

  test('forecast row round-trips including rain probability', () async {
    final prevision = PrevisionMeteo(
      date: DateTime.utc(2026, 6, 6),
      tempMin: 12,
      tempMax: 22,
      precipitationsMm: 4,
      probabilitePluie: 0.8,
    );

    await db.into(db.meteoCache).insertOnConflictUpdate(
          mapper.versCompanionPrevu(
            prevision,
            latitude: 45.75,
            longitude: 4.85,
            date: '2026-06-06',
            dateRecuperation: '2026-06-05T08:00:00.000Z',
          ),
        );

    final dto =
        mapper.versPrevisionMeteo((await db.select(db.meteoCache).get()).single);
    expect(dto.date, DateTime.parse('2026-06-06'));
    expect(dto.tempMin, 12);
    expect(dto.tempMax, 22);
    expect(dto.precipitationsMm, 4);
    expect(dto.probabilitePluie, closeTo(0.8, 1e-9));
  });

  test('re-inserting the same day/location/type upserts in place', () async {
    MeteoCacheCompanion companion() => mapper.versCompanionObserve(
          DonneesMeteo(
            date: DateTime.utc(2026, 1, 10),
            tempMin: 0,
            tempMax: 0,
            tempMoyenne: 0,
            precipitationsMm: 0,
            ventVitesseMax: 0,
          ),
          latitude: 45.75,
          longitude: 4.85,
          date: '2026-01-10',
          dateRecuperation: '2026-01-10T08:00:00.000Z',
        );

    await db.into(db.meteoCache).insertOnConflictUpdate(companion());
    await db.into(db.meteoCache).insertOnConflictUpdate(companion());

    expect(await db.select(db.meteoCache).get(), hasLength(1));
  });
}
