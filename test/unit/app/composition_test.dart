import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/app/composition.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/providers/service_providers.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/fiche_plante_cache.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/repositories/potager_repository_impl.dart';
import 'package:pot_a_gerer/infrastructure/services/sauvegarde_service_impl.dart';
import 'package:riverpod/riverpod.dart';

class MockPotagerRepository extends Mock implements AbstractPotagerRepository {}

void main() {
  ProviderContainer withDb() {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(overrides: Composition.surcharges(db));
    addTearDown(() {
      db.close();
      container.dispose();
    });
    return container;
  }

  test('a port without implementation fails explicitly', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Riverpod 3.x wraps initialisation errors, so match the message instead.
    expect(
      () => container.read(potagerRepositoryProvider),
      throwsA(predicate((e) => e.toString().contains('must be overridden'))),
    );
  });

  test('repository providers resolve to drift implementations', () {
    final container = withDb();
    expect(container.read(potagerRepositoryProvider),
        isA<PotagerRepositoryImpl>());
  });

  test('a repository provider can be overridden with a mock', () {
    final mock = MockPotagerRepository();
    when(mock.obtenirTous).thenAnswer((_) async => const <Potager>[]);
    final container = ProviderContainer(overrides: [
      potagerRepositoryProvider.overrideWithValue(mock),
    ]);
    addTearDown(container.dispose);
    expect(container.read(potagerRepositoryProvider), same(mock));
  });

  test('the wired potager repository round-trips through the in-memory DB',
      () async {
    final container = withDb();
    final repo = container.read(potagerRepositoryProvider);
    await repo.sauvegarder(Potager(
      id: 'p1',
      nom: 'Jardin',
      zoneClimatique:
          const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
      dateCreation: DateTime.utc(2026, 5, 1),
    ));
    expect((await repo.obtenirTous()).single.id, 'p1');
  });

  test('service providers resolve and the backup service is functional',
      () async {
    final container = withDb();
    expect(container.read(sauvegardeServiceProvider),
        isA<SauvegardeServiceImpl>());
    final json = await container.read(sauvegardeServiceProvider).exporterJson();
    expect(json, contains('"schemaVersion"'));
    // meteo/geoloc/notification providers also resolve without throwing.
    expect(() => container.read(meteoServiceProvider), returnsNormally);
    expect(() => container.read(geolocalisationServiceProvider), returnsNormally);
    expect(() => container.read(notificationServiceProvider), returnsNormally);
  });

  test('fichePlanteRepositoryProvider resolves from the loaded cache', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [
      ...Composition.surcharges(db),
      fichePlanteCacheProvider
          .overrideWith((ref) async => FichePlanteCache(const [])),
    ]);
    addTearDown(() {
      db.close();
      container.dispose();
    });
    final repo = await container.read(fichePlanteRepositoryProvider.future);
    expect(repo, isNotNull);
  });
}
