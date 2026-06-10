// Unit tests for the pending "add a plant" target-zone state.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pot_a_gerer/presentation/providers/ajout_plante_provider.dart';

void main() {
  ProviderContainer conteneur() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  test('starts with no pending target', () {
    final c = conteneur();
    expect(c.read(ajoutPlanteProvider), isNull);
  });

  test('cibler sets the target zone', () {
    final c = conteneur();
    c.read(ajoutPlanteProvider.notifier).cibler(
          zoneId: 'z-1',
          zoneNom: 'Carré nord',
        );
    final cible = c.read(ajoutPlanteProvider);
    expect(cible, isNotNull);
    expect(cible!.zoneId, 'z-1');
    expect(cible.zoneNom, 'Carré nord');
  });

  test('effacer clears the target', () {
    final c = conteneur();
    final notifier = c.read(ajoutPlanteProvider.notifier);
    notifier.cibler(zoneId: 'z-1', zoneNom: 'Carré nord');
    notifier.effacer();
    expect(c.read(ajoutPlanteProvider), isNull);
  });
}
