import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/state/journal_erreurs_chargement.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/fiche_asset_source.dart';
import 'package:riverpod/riverpod.dart';

class _SourceInvalide implements FicheAssetSource {
  @override
  Future<List<String>> listerCheminsFiches() async => ['legumes/cassee.yaml'];

  @override
  Future<String> lireFiche(String chemin) async => 'id: [non fermé';
}

void main() {
  test('records each failure with its source', () {
    final journal = JournalErreursChargement();

    journal.signaler('legumes/cassee.yaml', const FormatException('YAML'));

    expect(journal.erreurs.single.source, 'legumes/cassee.yaml');
    expect(journal.erreurs.single.erreur, isA<FormatException>());
  });

  test('a reload replaces the previous entry of the same source', () {
    final journal = JournalErreursChargement()
      ..signaler('a.yaml', const FormatException('v1'))
      ..signaler('a.yaml', const FormatException('v2'));

    expect(journal.erreurs, hasLength(1));
    expect((journal.erreurs.single.erreur as FormatException).message, 'v2');
  });

  test('exposes an unmodifiable list', () {
    final journal = JournalErreursChargement()
      ..signaler('a.yaml', const FormatException('YAML'));

    expect(() => journal.erreurs.clear(), throwsUnsupportedError);
  });

  test('an invalid catalogue sheet is reported, not dropped silently',
      () async {
    final c = ProviderContainer(overrides: [
      ficheAssetSourceProvider.overrideWithValue(_SourceInvalide()),
    ]);
    addTearDown(c.dispose);

    await c.read(catalogueLoaderProvider).charger();

    expect(c.read(journalErreursChargementProvider).erreurs.single.source,
        'legumes/cassee.yaml');
  });
}
