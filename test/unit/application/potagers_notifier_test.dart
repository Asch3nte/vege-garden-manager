import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/application/providers/database_providers.dart';
import 'package:pot_a_gerer/application/state/potagers_notifier.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  const zone = ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8);

  ProviderContainer makeContainer() {
    final container = ProviderContainer(overrides: [
      appDatabaseProvider
          .overrideWithValue(AppDatabase(NativeDatabase.memory())),
    ]);
    addTearDown(() {
      container.read(appDatabaseProvider).close();
      container.dispose();
    });
    return container;
  }

  test('build() exposes the (initially empty) list', () async {
    final container = makeContainer();
    expect(await container.read(potagersProvider.future), isEmpty);
  });

  test('creer() persists and the list reflects it', () async {
    final container = makeContainer();
    await container.read(potagersProvider.future); // initialise

    final notifier = container.read(potagersProvider.notifier);
    final created =
        await notifier.creer(nom: 'Jardin maison', zoneClimatique: zone);

    final list = await container.read(potagersProvider.future);
    expect(list, hasLength(1));
    expect(list.single.id, created.id);
    expect(list.single.nom, 'Jardin maison');
  });

  test('modifier() persists a domain mutation', () async {
    final container = makeContainer();
    await container.read(potagersProvider.future);
    final notifier = container.read(potagersProvider.notifier);

    final created = await notifier.creer(nom: 'Ancien nom', zoneClimatique: zone);
    created.renommer('Nouveau nom');
    await notifier.modifier(created);

    final list = await container.read(potagersProvider.future);
    expect(list.single.nom, 'Nouveau nom');
  });
}
