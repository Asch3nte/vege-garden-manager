// Unit tests for [PileNavigation] — the cross-branch back stack.
//
// Pure list logic (no widgets): exercises the browser-history folding done by
// [enregistrer] and the [peutRevenir]/[precedent] accessors that the shell's
// PopScope relies on to drive the system back button (docs/15 §8 D #5/#6).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pot_a_gerer/app/historique_navigation.dart';
import 'package:pot_a_gerer/app/router.dart';

void main() {
  late ProviderContainer container;
  late PileNavigation pile;

  setUp(() {
    container = ProviderContainer();
    pile = container.read(pileNavigationProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('seeds the stack on the Accueil branch and cannot go back yet', () {
    expect(container.read(pileNavigationProvider), [RoutesApp.accueil]);
    expect(pile.peutRevenir, isFalse);
  });

  test('a new location is a forward move (pushed on top)', () {
    pile.enregistrer(RoutesApp.catalogue);

    expect(container.read(pileNavigationProvider),
        [RoutesApp.accueil, RoutesApp.catalogue]);
    expect(pile.peutRevenir, isTrue);
    expect(pile.precedent, RoutesApp.accueil);
  });

  test('re-reporting the current top is a no-op (duplicate router events)', () {
    pile.enregistrer(RoutesApp.catalogue);
    pile.enregistrer(RoutesApp.catalogue);

    expect(container.read(pileNavigationProvider),
        [RoutesApp.accueil, RoutesApp.catalogue]);
  });

  test('a requested back move pops instead of pushing a duplicate', () {
    pile.enregistrer(RoutesApp.catalogue);
    pile.enregistrer(RoutesApp.potager);

    pile.enregistrer(pile.revenir());
    expect(container.read(pileNavigationProvider),
        [RoutesApp.accueil, RoutesApp.catalogue]);
  });

  test('re-tapping the tab below the top is a forward move', () {
    pile.enregistrer(RoutesApp.catalogue);

    pile.enregistrer(RoutesApp.accueil);
    expect(container.read(pileNavigationProvider),
        [RoutesApp.accueil, RoutesApp.catalogue, RoutesApp.accueil]);
    expect(pile.precedent, RoutesApp.catalogue);
  });

  test('a duplicate event does not consume a pending back move', () {
    pile.enregistrer(RoutesApp.catalogue);
    final cible = pile.revenir();

    pile.enregistrer(RoutesApp.catalogue);
    pile.enregistrer(cible);
    expect(container.read(pileNavigationProvider), [RoutesApp.accueil]);
  });

  test('oublier drops a deleted resource and its sub-routes', () {
    pile.enregistrer(RoutesApp.potager);
    pile.enregistrer(RoutesApp.zoneDetail('z1'));
    pile.enregistrer(RoutesApp.potager);
    pile.enregistrer('${RoutesApp.zoneDetail('z1')}/x');
    pile.enregistrer(RoutesApp.zoneDetail('z10'));

    final top = pile.oublier(RoutesApp.zoneDetail('z1'));
    expect(container.read(pileNavigationProvider),
        [RoutesApp.accueil, RoutesApp.potager, RoutesApp.zoneDetail('z10')]);
    expect(top, RoutesApp.zoneDetail('z10'));
  });

  test('oublier on the current screen returns the previous one', () {
    pile.enregistrer(RoutesApp.tacheDetail('t1'));

    expect(pile.oublier(RoutesApp.tacheDetail('t1')), RoutesApp.accueil);
    expect(container.read(pileNavigationProvider), [RoutesApp.accueil]);
  });

  test('reinitialiser drops the history, keeping the current screen', () {
    pile.enregistrer(RoutesApp.zoneDetail('z1'));
    pile.enregistrer(RoutesApp.plusDonnees);

    pile.reinitialiser(courant: RoutesApp.plusDonnees);
    expect(container.read(pileNavigationProvider),
        [RoutesApp.accueil, RoutesApp.plusDonnees]);

    pile.reinitialiser();
    expect(container.read(pileNavigationProvider), [RoutesApp.accueil]);
  });

  test('a full back-and-forth retraces every step then exits', () {
    // #6 scenario: Accueil → Catalogue → Potager, then back, back.
    pile.enregistrer(RoutesApp.catalogue);
    pile.enregistrer(RoutesApp.potager);

    pile.enregistrer(pile.revenir()); // back → Catalogue
    expect(pile.precedent, RoutesApp.accueil);
    pile.enregistrer(pile.revenir()); // back → Accueil

    expect(container.read(pileNavigationProvider), [RoutesApp.accueil]);
    expect(pile.peutRevenir, isFalse);
  });

  test('cross-branch jump then back lands on the source (#5)', () {
    // Dashboard zone tile jumps to the zone detail under the Potager branch…
    pile.enregistrer(RoutesApp.zoneDetail('z1'));
    expect(pile.precedent, RoutesApp.accueil);

    // …and a single back returns straight to Accueil.
    pile.enregistrer(pile.revenir());
    expect(container.read(pileNavigationProvider), [RoutesApp.accueil]);
  });

  test('exposes an immutable view of the stack', () {
    expect(() => container.read(pileNavigationProvider).add('/x'),
        throwsUnsupportedError);
  });
}
