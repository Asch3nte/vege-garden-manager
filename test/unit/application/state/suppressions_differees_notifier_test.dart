import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:pot_a_gerer/application/state/suppressions_differees_notifier.dart';

class _DisquePlein implements Exception {}

void main() {
  const delai = Duration(milliseconds: 20);
  late ProviderContainer c;
  late List<String> effaces;

  setUp(() {
    effaces = [];
    c = ProviderContainer(overrides: [
      suppressionsDiffereesProvider
          .overrideWith(() => SuppressionsDiffereesNotifier(delai)),
    ]);
    addTearDown(c.dispose);
  });

  SuppressionsDiffereesNotifier service() =>
      c.read(suppressionsDiffereesProvider.notifier);

  Future<void> effacer(String id) async => effaces.add(id);

  Future<void> attendreDelai() => Future<void>.delayed(delai * 3);

  test('a scheduled deletion is pending, then erased once the delay passes',
      () async {
    service().programmer('a', (_) => effacer('a'));

    expect(c.read(suppressionsDiffereesProvider), {'a'});
    expect(effaces, isEmpty);

    await attendreDelai();

    expect(effaces, ['a']);
    expect(c.read(suppressionsDiffereesProvider), isEmpty);
  });

  test('cancelling drops the pending deletion: nothing is erased', () async {
    service().programmer('a', (_) => effacer('a'));

    expect(service().annuler('a'), isTrue);
    await attendreDelai();

    expect(effaces, isEmpty);
    expect(c.read(suppressionsDiffereesProvider), isEmpty);
  });

  test('cancelling after the erasure has started does nothing', () async {
    service().programmer('a', (_) => effacer('a'));
    await service().valider('a');

    expect(service().annuler('a'), isFalse);
    expect(effaces, ['a']);
  });

  test('toutValider erases every pending deletion at once', () async {
    service()
      ..programmer('a', (_) => effacer('a'))
      ..programmer('b', (_) => effacer('b'));

    await service().toutValider();

    expect(effaces, unorderedEquals(['a', 'b']));
    expect(c.read(suppressionsDiffereesProvider), isEmpty);
    await attendreDelai();
    expect(effaces, hasLength(2));
  });

  test('a failed erasure brings the item back', () async {
    service().programmer('a', (_) async => throw _DisquePlein());

    await service().valider('a');

    expect(c.read(suppressionsDiffereesProvider), isEmpty);
  });

  test('an id already pending is not scheduled twice', () async {
    service()
      ..programmer('a', (_) => effacer('a'))
      ..programmer('a', (_) => effacer('a'));

    await attendreDelai();

    expect(effaces, ['a']);
  });
}
