import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/state/accueil_notifier.dart';
import '../application/state/calendrier_notifier.dart';
import '../application/state/potager_notifier.dart';
import '../application/state/potagers_notifier.dart';
import '../application/state/preferences_notifier.dart';
import '../l10n/app_localizations.dart';
import 'historique_navigation.dart';
import '../presentation/screens/ecran_accueil.dart';
import '../presentation/screens/ecran_calendrier.dart';
import '../presentation/screens/ecran_meteo_detail.dart';
import '../presentation/screens/ecran_onboarding.dart';
import '../presentation/screens/ecran_catalogue.dart';
import '../presentation/screens/ecran_plus.dart';
import '../presentation/screens/ecran_potager.dart';
import '../presentation/screens/ecran_zone_detail.dart';
import '../presentation/screens/parametres/panneau_a_propos.dart';
import '../presentation/screens/parametres/panneau_confidentialite.dart';
import '../presentation/screens/parametres/panneau_donnees.dart';
import '../presentation/screens/parametres/panneau_general.dart';
import '../presentation/screens/parametres/panneau_notifications.dart';
import '../presentation/widgets/echafaudage_navigation.dart';

/// Route paths of the five primary navigation branches.
///
/// Centralised so screens can navigate by name without re-typing literals.
abstract final class RoutesApp {
  const RoutesApp._();

  /// First-launch onboarding, a top-level route **outside** the navigation
  /// shell (no bottom bar / rail). Gated by the router [GoRouter.redirect] on
  /// the onboarding-completion preference.
  static const String onboarding = '/onboarding';

  static const String accueil = '/accueil';
  static const String potager = '/potager';
  static const String catalogue = '/catalogue';
  static const String calendrier = '/calendrier';
  static const String plus = '/plus';

  /// Path segment of the zone-detail sub-route (under [potager]).
  static const String zoneDetailSegment = 'zone/:id';

  /// Absolute location of the zone detail, under the **Potager** branch.
  ///
  /// The dashboard tiles also target this location: tapping a zone there
  /// switches to the Potager tab on that zone, and the global back stack
  /// (see [pileNavigationProvider]) returns straight to the dashboard
  /// (docs/15 §8 D #5).
  static String zoneDetail(String id) => '$potager/zone/$id';

  /// Hourly weather detail, under the **Accueil** branch (so re-tapping the
  /// Accueil tab pops back to the dashboard).
  static const String accueilMeteoSegment = 'meteo';
  static const String accueilMeteo = '$accueil/$accueilMeteoSegment';

  // Settings sub-panels, as go_router sub-routes of [plus] (so re-tapping the
  // Plus tab pops back to the settings root — imperative pushes would not).
  static const String plusGeneralSegment = 'general';
  static const String plusConfidentialiteSegment = 'confidentialite';
  static const String plusNotificationsSegment = 'notifications';
  static const String plusDonneesSegment = 'donnees';
  static const String plusAProposSegment = 'apropos';

  static const String plusGeneral = '$plus/$plusGeneralSegment';
  static const String plusConfidentialite = '$plus/$plusConfidentialiteSegment';
  static const String plusNotifications = '$plus/$plusNotificationsSegment';
  static const String plusDonnees = '$plus/$plusDonneesSegment';
  static const String plusAPropos = '$plus/$plusAProposSegment';
}

/// The five primary destinations, in display order (docs/09 §3).
///
/// Order is the contract between the router branches and the navigation shell:
/// the Nth branch corresponds to the Nth destination here.
// Icons map to the Phosphor set targeted by docs/09 §3 (House, Plant, BookOpen,
// CalendarBlank, DotsThree); Material stand-ins are used until Phosphor is
// re-wired (phosphor_flutter is incompatible with Flutter 3.44.1 — see docs/08
// §7). Outline for the resting state, filled for the selected state.
const List<DestinationNav> _destinations = [
  DestinationNav(
    route: RoutesApp.accueil,
    libelle: _libelleAccueil,
    icone: Icons.home_outlined,
    iconeActive: Icons.home,
  ),
  DestinationNav(
    route: RoutesApp.potager,
    libelle: _libellePotager,
    icone: Icons.local_florist_outlined,
    iconeActive: Icons.local_florist,
  ),
  DestinationNav(
    route: RoutesApp.catalogue,
    libelle: _libelleCatalogue,
    icone: Icons.menu_book_outlined,
    iconeActive: Icons.menu_book,
  ),
  DestinationNav(
    route: RoutesApp.calendrier,
    libelle: _libelleCalendrier,
    icone: Icons.calendar_today_outlined,
    iconeActive: Icons.calendar_today,
  ),
  DestinationNav(
    route: RoutesApp.plus,
    libelle: _libellePlus,
    icone: Icons.more_horiz_outlined,
    iconeActive: Icons.more_horiz,
  ),
];

// Top-level label resolvers (const tear-offs can't be closures/getters).
String _libelleAccueil(AppLocalizations l) => l.navAccueil;
String _libellePotager(AppLocalizations l) => l.navPotager;
String _libelleCatalogue(AppLocalizations l) => l.navCatalogue;
String _libelleCalendrier(AppLocalizations l) => l.navCalendrier;
String _libellePlus(AppLocalizations l) => l.navPlus;

/// Invalidates the time-sensitive view-model of the tab at [index] so it
/// reloads on (re)entry — keeping the dashboard, the garden plan and the agenda
/// in sync with edits made elsewhere. Catalogue (static) and Plus are left as-is.
void _rafraichirBranche(WidgetRef ref, int index) {
  switch (index) {
    case 0:
      ref.invalidate(accueilProvider);
    case 1:
      ref.invalidate(potagerProvider);
    case 3:
      ref.invalidate(calendrierProvider);
  }
}

/// Maps an absolute [location] to the index of the branch that owns it, by
/// matching the top-level path segment. Used to refresh the destination branch
/// when the global back stack navigates there.
int _indexBranche(String location) {
  if (location.startsWith(RoutesApp.potager)) return 1;
  if (location.startsWith(RoutesApp.catalogue)) return 2;
  if (location.startsWith(RoutesApp.calendrier)) return 3;
  if (location.startsWith(RoutesApp.plus)) return 4;
  return 0; // Accueil (default / fallback).
}

/// Replays one step of the cross-branch history: navigates to the previous
/// screen ([PileNavigation.precedent]) and refreshes its branch. Shared by the
/// shell's back handler (branch roots) and every sub-route's [_RetourGlobal]
/// (deep screens) so the system back button behaves identically everywhere.
void _retourGlobal(BuildContext context, WidgetRef ref) {
  final notifier = ref.read(pileNavigationProvider.notifier);
  if (!notifier.peutRevenir) return;
  final precedent = notifier.precedent;
  _rafraichirBranche(ref, _indexBranche(precedent));
  context.go(precedent);
}

/// Wraps a **sub-route** screen so the system back button replays the global
/// cross-branch history instead of letting the branch Navigator pop to the
/// branch root.
///
/// The shell-level `PopScope` is an *ancestor* of the branch Navigators, so for
/// a deep screen (zone detail, weather detail, a settings panel) the branch
/// Navigator pops the sub-route first and the shell handler never runs — back
/// would land on the branch root rather than the screen the user came from
/// (e.g. a dashboard → zone jump returning to the Potager root instead of the
/// dashboard). This PopScope sits *inside* the sub-route page (deeper than the
/// branch Navigator), so it wins and drives the same global history (docs/15
/// §8 D #5/#6).
class _RetourGlobal extends ConsumerWidget {
  final Widget child;

  const _RetourGlobal({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peutRevenir = ref.watch(pileNavigationProvider).length > 1;
    return PopScope(
      canPop: !peutRevenir,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _retourGlobal(context, ref);
      },
      child: child,
    );
  }
}

/// The application [GoRouter], built once and cached for the app's lifetime.
///
/// Uses a [StatefulShellRoute.indexedStack] so each of the five tabs keeps the
/// state of its **root** screen (dashboard scroll, catalogue search…) when
/// switching between them. Native indexed-stack back, however, only pops within
/// the active branch; to give a browser-like back that retraces every step
/// across tabs (docs/15 §8 D #5/#6), the router feeds a single cross-branch
/// history ([pileNavigationProvider]) from a listener on its
/// [GoRouterDelegate], and the shell's `PopScope` drives the system back button
/// from it. Tapping any tab resets that tab to its root (so a tab never
/// restores a stale sub-route — the back button, not the tab, replays a deep
/// path).
///
/// Lives behind a provider because routing now reacts to app state (the history
/// notifier); the provider caches the single [GoRouter] instance.
/// A [Listenable] the router can refresh on demand: it exposes a public
/// [rafraichir] because [ChangeNotifier.notifyListeners] is protected.
class _RafraichisseurRoute extends ChangeNotifier {
  void rafraichir() => notifyListeners();
}

final routeurProvider = Provider<GoRouter>((ref) {
  // Re-runs [GoRouter.redirect] whenever the preferences change (notably once
  // they finish loading, or when onboarding is completed) so the onboarding
  // gate opens/closes without rebuilding the cached router.
  final rafraichir = _RafraichisseurRoute();
  ref.listen(preferencesProvider, (_, _) => rafraichir.rafraichir());
  // Also re-evaluate when the garden list loads/changes: the gate skips
  // onboarding when user data already exists (see the redirect below).
  ref.listen(potagersProvider, (_, _) => rafraichir.rafraichir());
  ref.onDispose(rafraichir.dispose);

  final routeur = GoRouter(
    initialLocation: RoutesApp.accueil,
    refreshListenable: rafraichir,
    // First-launch gate: until onboarding is completed, force the user onto
    // the onboarding flow; once done, keep them out of it. While preferences
    // are still loading (value null) we defer the decision — the refresh above
    // re-evaluates as soon as they arrive.
    redirect: (context, state) {
      final prefs = ref.read(preferencesProvider).value;
      final potagers = ref.read(potagersProvider).value;
      // Defer until both are loaded; the refresh above re-evaluates on arrival.
      if (prefs == null || potagers == null) return null;
      final surOnboarding = state.matchedLocation == RoutesApp.onboarding;
      // Onboarding is a first-run flow: only when it hasn't been completed AND
      // there is no user data yet. Pre-existing gardens (e.g. a database that
      // predates the onboarding flag) skip it — never overwrite real data.
      final doitOnboarder = !prefs.onboardingTermine && potagers.isEmpty;
      if (doitOnboarder) {
        return surOnboarding ? null : RoutesApp.onboarding;
      }
      // Just completed onboarding → land on the Potager screen (which now shows
      // the garden/zones just created) rather than the dashboard (feedback #4).
      return surOnboarding ? RoutesApp.potager : null;
    },
    routes: [
      GoRoute(
        path: RoutesApp.onboarding,
        builder: (context, state) => const EcranOnboarding(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // Consumer so the shell can read the cross-branch history (back
          // button) and refresh a tab's data when entered (the dashboard/agenda
          // must reflect changes made elsewhere).
          return Consumer(
            builder: (context, ref, _) {
              final pile = ref.watch(pileNavigationProvider);
              final peutRevenir = pile.length > 1;
              return PopScope(
                // While there is a previous screen, intercept the system back
                // button and replay the global history; at the first entry,
                // let the OS pop the app.
                canPop: !peutRevenir,
                onPopInvokedWithResult: (didPop, _) {
                  if (!didPop) _retourGlobal(context, ref);
                },
                child: EchafaudageNavigation(
                  indexActif: navigationShell.currentIndex,
                  destinations: _destinations,
                  onSelection: (index) {
                    _rafraichirBranche(ref, index);
                    // Any tab tap returns to that tab's root (docs/15 §8 D
                    // #5/#6): a deep sub-route is replayed via the back button,
                    // never restored by re-selecting the tab.
                    navigationShell.goBranch(index, initialLocation: true);
                  },
                  child: navigationShell,
                ),
              );
            },
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutesApp.accueil,
                builder: (context, state) => const EcranAccueil(),
                routes: [
                  // Hourly weather detail (opened from the weather card). The
                  // zone detail is no longer registered here: a dashboard zone
                  // tile now jumps to the Potager branch (#5), and the global
                  // back stack returns to the dashboard.
                  GoRoute(
                    path: RoutesApp.accueilMeteoSegment,
                    builder: (context, state) =>
                        const _RetourGlobal(child: EcranMeteoDetail()),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutesApp.potager,
                builder: (context, state) => const EcranPotager(),
                routes: [
                  // Zone detail, pushed on top of the Potager branch (keeps the
                  // bottom bar / rail and the branch's navigation state).
                  GoRoute(
                    path: RoutesApp.zoneDetailSegment,
                    builder: (context, state) => _RetourGlobal(
                      child: EcranZoneDetail(
                        zoneId: state.pathParameters['id']!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutesApp.catalogue,
                builder: (context, state) => const EcranCatalogue(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutesApp.calendrier,
                builder: (context, state) => const EcranCalendrier(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutesApp.plus,
                builder: (context, state) => const EcranPlus(),
                routes: [
                  GoRoute(
                    path: RoutesApp.plusGeneralSegment,
                    builder: (context, state) =>
                        const _RetourGlobal(child: PanneauGeneral()),
                  ),
                  GoRoute(
                    path: RoutesApp.plusConfidentialiteSegment,
                    builder: (context, state) =>
                        const _RetourGlobal(child: PanneauConfidentialite()),
                  ),
                  GoRoute(
                    path: RoutesApp.plusNotificationsSegment,
                    builder: (context, state) =>
                        const _RetourGlobal(child: PanneauNotifications()),
                  ),
                  GoRoute(
                    path: RoutesApp.plusDonneesSegment,
                    builder: (context, state) =>
                        const _RetourGlobal(child: PanneauDonnees()),
                  ),
                  GoRoute(
                    path: RoutesApp.plusAProposSegment,
                    builder: (context, state) =>
                        const _RetourGlobal(child: PanneauAPropos()),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );

  // Single source of truth for the cross-branch history: every location change
  // reported by the delegate (tab switch, sub-route push, programmatic go) is
  // folded into the back stack with browser semantics.
  void ecouter() {
    final location = routeur.routerDelegate.currentConfiguration.uri.toString();
    // The onboarding gate is not part of the browseable history: excluding it
    // keeps the back stack clean (no "back into onboarding" once completed).
    if (location == RoutesApp.onboarding) return;
    ref.read(pileNavigationProvider.notifier).enregistrer(location);
  }

  routeur.routerDelegate.addListener(ecouter);
  ref.onDispose(() {
    routeur.routerDelegate.removeListener(ecouter);
    routeur.dispose();
  });

  return routeur;
});
