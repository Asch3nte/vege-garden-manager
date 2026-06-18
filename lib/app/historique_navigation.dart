import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';

/// Application-wide navigation history — a single, cross-branch back stack.
///
/// The router uses a [StatefulShellRoute.indexedStack], whose native back
/// behaviour only pops *within* the active branch and never retraces tab
/// switches. To give the user a browser-like "back always returns to the
/// previous screen, even across tabs" (docs/15 §8 D #5/#6), this notifier keeps
/// the ordered list of visited **absolute locations** (top = current screen).
///
/// It is fed by a single listener on the [GoRouter] (see [routeurProvider]): the
/// router is the source of truth for the current location, and [enregistrer]
/// folds each reported location into a back stack with browser semantics. The
/// shell's `PopScope` then drives the system back button by navigating to
/// [precedent], which the same listener recognises as a backward step.
class PileNavigation extends Notifier<List<String>> {
  @override
  List<String> build() => const [RoutesApp.accueil];

  /// Folds [location] (the router's current location) into the back stack.
  ///
  /// Browser-history semantics, idempotent against duplicate router events:
  /// - same as the current top → no-op (re-entrancy / seed echoes);
  /// - equal to the entry just below the top → a **backward** move → pop;
  /// - otherwise → a **forward** move → push.
  void enregistrer(String location) {
    final pile = state;
    if (pile.isNotEmpty && pile.last == location) return;
    if (pile.length >= 2 && pile[pile.length - 2] == location) {
      state = List.unmodifiable(pile.sublist(0, pile.length - 1));
      return;
    }
    state = List.unmodifiable([...pile, location]);
  }

  /// Whether there is a previous screen to return to (otherwise the system back
  /// button should let the OS pop the app).
  bool get peutRevenir => state.length > 1;

  /// The location to navigate to on a back gesture. Only valid when
  /// [peutRevenir] is `true`.
  String get precedent => state[state.length - 2];
}

/// The cross-branch navigation history. Lives for the app's lifetime (the
/// provider caches the single instance), fed by the [routeurProvider] listener.
final pileNavigationProvider =
    NotifierProvider<PileNavigation, List<String>>(PileNavigation.new);
