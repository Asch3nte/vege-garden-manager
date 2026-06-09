import 'package:flutter/material.dart';

import '../../app/theme/dimensions_app.dart';

/// Temporary placeholder for a screen whose real content is not built yet.
///
/// Each of the five primary navigation destinations starts as one of these so
/// the navigation shell (bottom bar / rail, routing, theming) can be wired and
/// tested end-to-end *before* any single screen is implemented. They are
/// replaced one by one as each screen is translated from the design mock-ups.
///
/// Deliberately empty-state styled (duotone-ish icon + caption) per the empty
/// states of `docs/08-design-system.md` §9, rather than a blank page.
class EcranEnConstruction extends StatelessWidget {
  /// Title shown in the app bar and as the empty-state heading.
  final String titre;

  /// Material icon standing in for the eventual Phosphor icon of this screen.
  final IconData icone;

  const EcranEnConstruction({
    super.key,
    required this.titre,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(titre)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(EspacementsApp.s6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icone,
                size: TaillesIconesApp.xl2,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(height: EspacementsApp.s4),
              Text(titre, style: theme.textTheme.headlineSmall),
              const SizedBox(height: EspacementsApp.s2),
              Text(
                'Écran à venir.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
