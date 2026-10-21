import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_favori_repository.dart';

class MockFavoris extends Mock implements AbstractFavoriRepository {}

/// A [MockFavoris] backed by an in-memory set, seeded with [initiaux].
MockFavoris favorisEnMemoire([Set<String> initiaux = const {}]) {
  final ids = {...initiaux};
  final mock = MockFavoris();
  when(() => mock.obtenirIds()).thenAnswer((_) async => {...ids});
  when(
    () => mock.ajouter(any()),
  ).thenAnswer((i) async => ids.add(i.positionalArguments.single as String));
  when(
    () => mock.retirer(any()),
  ).thenAnswer((i) async => ids.remove(i.positionalArguments.single as String));
  return mock;
}
