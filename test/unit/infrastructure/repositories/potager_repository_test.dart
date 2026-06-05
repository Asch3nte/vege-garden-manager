import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/enums/source_localisation.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/type_emplacement.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/repositories/potager_repository_impl.dart';

void main() {
  late AppDatabase db;
  late PotagerRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = PotagerRepositoryImpl(db);
  });
  tearDown(() => db.close());

  Potager potager({
    String id = 'p1',
    TypeEmplacement emplacement = TypeEmplacement.balcon,
    Localisation? localisation,
    DateTime? date,
  }) =>
      Potager(
        id: id,
        nom: 'Jardin',
        emplacement: emplacement,
        localisation: localisation ?? const Localisation.nonDefinie(),
        zoneClimatique:
            const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
        dateCreation: date ?? DateTime.utc(2026, 3, 1),
      );

  test('save then read round-trips (shallow, no parcelles)', () async {
    await repo.sauvegarder(potager(
      localisation: Localisation.gps(latitude: 47.21, longitude: -1.55),
    ));
    final relu = (await repo.obtenirTous()).single;
    expect(relu.nom, 'Jardin');
    expect(relu.emplacement, TypeEmplacement.balcon);
    expect(relu.localisation.source, SourceLocalisation.gps);
    expect(relu.localisation.latitude, 47.21);
    expect(relu.zoneClimatique.type, TypeClimat.oceanique);
    expect(relu.zoneClimatique.rusticite, ZoneRusticite.zone8);
    expect(relu.parcelles, isEmpty);
  });

  test('undefined localisation round-trips (opt-out preserved)', () async {
    await repo.sauvegarder(potager());
    final relu = (await repo.obtenirTous()).single;
    expect(relu.localisation.estDefinie, isFalse);
    expect(relu.localisation.source, SourceLocalisation.nonDefinie);
  });

  test('manual localisation keeps the city', () async {
    await repo.sauvegarder(potager(
      localisation: Localisation.manuelle(
          ville: 'Nantes', latitude: 47.21, longitude: -1.55),
    ));
    final relu = (await repo.obtenirTous()).single;
    expect(relu.localisation.source, SourceLocalisation.manuelle);
    expect(relu.localisation.ville, 'Nantes');
  });

  test('sauvegarder upserts (no duplicate)', () async {
    await repo.sauvegarder(potager());
    await repo.sauvegarder(potager()); // same id
    expect(await repo.obtenirTous(), hasLength(1));
  });

  test('obtenirPotagerActif returns the earliest non-deleted', () async {
    await repo.sauvegarder(potager(id: 'b', date: DateTime.utc(2026, 5, 1)));
    await repo.sauvegarder(potager(id: 'a', date: DateTime.utc(2026, 1, 1)));
    expect((await repo.obtenirPotagerActif())!.id, 'a');
  });
}
