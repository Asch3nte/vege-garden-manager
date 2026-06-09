import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../presentation/screens/ecran_accueil.dart';
import '../presentation/screens/ecran_calendrier.dart';
import '../presentation/screens/ecran_catalogue.dart';
import '../presentation/screens/ecran_plus.dart';
import '../presentation/screens/ecran_potager.dart';
import '../presentation/widgets/echafaudage_navigation.dart';

/// Route paths of the five primary navigation branches.
///
/// Centralised so screens can navigate by name without re-typing literals.
abstract final class RoutesApp {
  const RoutesApp._();

  static const String accueil = '/accueil';
  static const String potager = '/potager';
  static const String catalogue = '/catalogue';
  static const String calendrier = '/calendrier';
  static const String plus = '/plus';
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

/// Builds the application [GoRouter].
///
/// Uses a [StatefulShellRoute.indexedStack] so each of the five tabs keeps its
/// own navigation state and scroll position when switching between them — the
/// dashboard, the multi-level Potager, etc. stay where the user left them. The
/// shell renders the responsive [EchafaudageNavigation] chrome around the
/// active branch.
///
/// Kept as a top-level factory (not a provider) for now: routing has no runtime
/// dependencies yet. It moves behind a Riverpod provider once a route needs to
/// react to app state (e.g. onboarding completion).
GoRouter creerRouteur() {
  return GoRouter(
    initialLocation: RoutesApp.accueil,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return EchafaudageNavigation(
            indexActif: navigationShell.currentIndex,
            destinations: _destinations,
            onSelection: (index) => navigationShell.goBranch(
              index,
              // Re-tapping the active tab pops it back to its root.
              initialLocation: index == navigationShell.currentIndex,
            ),
            child: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutesApp.accueil,
                builder: (context, state) => const EcranAccueil(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutesApp.potager,
                builder: (context, state) => const EcranPotager(),
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
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
