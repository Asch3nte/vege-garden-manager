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

  test('navigating to the entry below the top is a backward move (pop)', () {
    pile.enregistrer(RoutesApp.catalogue);
    pile.enregistrer(RoutesApp.potager);
    expect(container.read(pileNavigationProvider),
        [RoutesApp.accueil, RoutesApp.catalogue, RoutesApp.potager]);

    // Going back to Catalogue (the entry just below Potager) pops, it does not
    // push a duplicate.
    pile.enregistrer(RoutesApp.catalogue);
    expect(container.read(pileNavigationProvider),
        [RoutesApp.accueil, RoutesApp.catalogue]);
  });

  test('a full back-and-forth retraces every step then exits', () {
    // #6 scenario: Accueil → Catalogue → Potager, then back, back.
    pile.enregistrer(RoutesApp.catalogue);
    pile.enregistrer(RoutesApp.potager);

    pile.enregistrer(pile.precedent); // back → Catalogue
    expect(pile.precedent, RoutesApp.accueil);
    pile.enregistrer(pile.precedent); // back → Accueil

    expect(container.read(pileNavigationProvider), [RoutesApp.accueil]);
    expect(pile.peutRevenir, isFalse);
  });

  test('cross-branch jump then back lands on the source (#5)', () {
    // Dashboard zone tile jumps to the zone detail under the Potager branch…
    pile.enregistrer(RoutesApp.zoneDetail('z1'));
    expect(pile.precedent, RoutesApp.accueil);

    // …and a single back returns straight to Accueil.
    pile.enregistrer(pile.precedent);
    expect(container.read(pileNavigationProvider), [RoutesApp.accueil]);
  });

  test('exposes an immutable view of the stack', () {
    expect(() => container.read(pileNavigationProvider).add('/x'),
        throwsUnsupportedError);
  });
}
