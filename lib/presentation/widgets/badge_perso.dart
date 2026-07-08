import 'package:flutter/material.dart';

import '../../app/theme/dimensions_app.dart';
import '../../l10n/app_localizations.dart';

/// Small pill tagging a plant sheet as user-authored ("Perso"), so a personal
/// sheet is told apart from a built-in one at a glance wherever the catalogue
/// shows it (list cards and detail header). Tinted with the tertiary colour to
/// stand out from the neutral metadata around it.
class BadgePerso extends StatelessWidget {
  const BadgePerso({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: EspacementsApp.s2, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary.withValues(alpha: 0.16),
        borderRadius: const BorderRadius.all(RayonsApp.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline,
              size: TaillesIconesApp.sm, color: theme.colorScheme.tertiary),
          const SizedBox(width: 4),
          Text(
            l10n.fichePersoBadge,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.tertiary),
          ),
        ],
      ),
    );
  }
}
