import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';

/// Application-wide navigation history — a single, cross-branch back stack.
///
/// The router uses a [StatefulShellRoute.indexedStack], whose native back
/// behaviour only pops *within* the active branch and never retraces tab
/// switches. To give the user a browser-like "back always returns to the
/// previous screen, even across tabs", this notifier keeps
/// the ordered list of visited **absolute locations** (top = current screen).
///
/// It is fed by a single listener on the [GoRouter] (see [routeurProvider]): the
/// router is the source of truth for the current location, and [enregistrer]
/// folds each reported location into a back stack with browser semantics. The
/// shell's `PopScope` then drives the system back button by navigating to
/// [precedent], which the same listener recognises as a backward step.
class PileNavigation extends Notifier<List<String>> {
  /// Entries kept at most; the oldest are dropped beyond.
  static const int _tailleMax = 50;

  /// Whether the next reported location is an explicit forward move.
  bool _avanceForcee = false;

  @override
  List<String> build() => const [RoutesApp.accueil];

  /// Folds [location] (the router's current location) into the back stack.
  ///
  /// Idempotent against duplicate router events:
  /// - same as the current top → no-op;
  /// - equal to the entry just below the top → pop, unless [avancer] was
  ///   called (a tab tap is a forward move);
  /// - otherwise → push.
  void enregistrer(String location) {
    final pile = state;
    if (pile.isNotEmpty && pile.last == location) return;
    final avance = _avanceForcee;
    _avanceForcee = false;
    if (!avance && pile.length >= 2 && pile[pile.length - 2] == location) {
      state = List.unmodifiable(pile.sublist(0, pile.length - 1));
      return;
    }
    final suivante = [...pile, location];
    state = List.unmodifiable(suivante.length > _tailleMax
        ? suivante.sublist(suivante.length - _tailleMax)
        : suivante);
  }

  /// Marks the next reported location as a forward move.
  void avancer() => _avanceForcee = true;

  /// Whether there is a previous screen to return to (otherwise the system back
  /// button should let the OS pop the app).
  bool get peutRevenir => state.length > 1;

  /// The location to navigate to on a back gesture. Only valid when
  /// [peutRevenir] is `true`.
  String get precedent => state[state.length - 2];

  /// Removes every entry showing [location] or one of its sub-routes (a deleted
  /// resource), merges the resulting adjacent duplicates and returns the new top.
  String oublier(String location) {
    final restants = <String>[];
    for (final entree in state) {
      if (entree == location || entree.startsWith('$location/')) continue;
      if (restants.isNotEmpty && restants.last == entree) continue;
      restants.add(entree);
    }
    if (restants.isEmpty) restants.add(RoutesApp.accueil);
    _avanceForcee = false;
    state = List.unmodifiable(restants);
    return restants.last;
  }

  /// Drops the whole history (data reset or import), keeping [courant] on top
  /// of the root when given.
  void reinitialiser({String? courant}) {
    _avanceForcee = false;
    state = List.unmodifiable([
      RoutesApp.accueil,
      if (courant != null && courant != RoutesApp.accueil) courant,
    ]);
  }
}

/// The cross-branch navigation history. Lives for the app's lifetime (the
/// provider caches the single instance), fed by the [routeurProvider] listener.
final pileNavigationProvider =
    NotifierProvider<PileNavigation, List<String>>(PileNavigation.new);
