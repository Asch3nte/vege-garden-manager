import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// One primary navigation destination: its route, label and icons.
///
/// [icone] is the resting (outline) icon; [iconeActive] the selected (filled)
/// one — mirroring the design system's Regular-vs-Bold/Fill icon states
/// (docs/08 §7). Material icons stand in for the eventual Phosphor set.
class DestinationNav {
  /// go_router path of this destination's branch (e.g. `/accueil`).
  final String route;

  /// Resolves the localized label (deferred so it reads the current locale).
  final String Function(AppLocalizations l10n) libelle;

  /// Resting icon.
  final IconData icone;

  /// Selected icon.
  final IconData iconeActive;

  const DestinationNav({
    required this.route,
    required this.libelle,
    required this.icone,
    required this.iconeActive,
  });
}

/// Responsive navigation shell hosting the five primary destinations.
///
/// Per docs/09 §2: a bottom [NavigationBar] on mobile (< 600px) and a vertical
/// [NavigationRail] on tablet/desktop (≥ 600px). The shell is route-driven — it
/// renders whatever [child] go_router gives it for the active branch and only
/// owns the chrome and the switch between branches.
class EchafaudageNavigation extends StatelessWidget {
  /// Breakpoint (logical px) above which the rail replaces the bottom bar.
  static const double seuilTablette = 600;

  /// The active branch's screen, provided by the router's [StatefulShellRoute].
  final Widget child;

  /// Index of the currently selected destination.
  final int indexActif;

  /// Destinations, in display order.
  final List<DestinationNav> destinations;

  /// Called with the destination index the user tapped.
  final ValueChanged<int> onSelection;

  const EchafaudageNavigation({
    super.key,
    required this.child,
    required this.indexActif,
    required this.destinations,
    required this.onSelection,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final largeur = MediaQuery.sizeOf(context).width;
    final estLarge = largeur >= seuilTablette;

    if (estLarge) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: indexActif,
              onDestinationSelected: onSelection,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icone),
                    selectedIcon: Icon(d.iconeActive),
                    label: Text(d.libelle(l10n)),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: indexActif,
        onDestinationSelected: onSelection,
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icone),
              selectedIcon: Icon(d.iconeActive),
              label: d.libelle(l10n),
            ),
        ],
      ),
    );
  }
}
