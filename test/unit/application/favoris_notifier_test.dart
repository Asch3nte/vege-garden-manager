import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/state/favoris_notifier.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_favori_repository.dart';
import 'package:riverpod/riverpod.dart';

class MockFavoris extends Mock implements AbstractFavoriRepository {}

void main() {
  late MockFavoris repo;
  late Set<String> enBase;

  setUp(() {
    repo = MockFavoris();
    enBase = {'tomate'};
    when(() => repo.obtenirIds()).thenAnswer((_) async => {...enBase});
    when(() => repo.ajouter(any())).thenAnswer((i) async {
      enBase.add(i.positionalArguments.single as String);
    });
    when(() => repo.retirer(any())).thenAnswer((i) async {
      enBase.remove(i.positionalArguments.single as String);
    });
  });

  ProviderContainer conteneur() {
    final c = ProviderContainer(
      overrides: [favoriRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('loads the stored favourites', () async {
    expect(await conteneur().read(favorisProvider.future), {'tomate'});
  });

  test('toggling adds then removes a favourite', () async {
    final c = conteneur();
    await c.read(favorisProvider.future);
    final notifier = c.read(favorisProvider.notifier);

    await notifier.basculer('basilic');
    expect(c.read(favorisProvider).value, {'tomate', 'basilic'});
    verify(() => repo.ajouter('basilic')).called(1);

    await notifier.basculer('tomate');
    expect(c.read(favorisProvider).value, {'basilic'});
    verify(() => repo.retirer('tomate')).called(1);
  });
}
