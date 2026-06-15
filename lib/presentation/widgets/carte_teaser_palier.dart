import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/dimensions_app.dart';
import '../../domain/enums/niveau_experience.dart';
import '../../l10n/app_localizations.dart';
import 'libelles_enums.dart';

/// A contextual **level-up teaser** (ADR-0009 §4b): a small, dismissable card
/// shown on a gated screen to a user below the unlocking level. It names the
/// locked [feature], the [niveauRequis] that opens it, and offers a one-tap
/// "learn more" that jumps to the **Guide des niveaux** (mini-tuto §4a). Never a
/// blocking modal.
class CarteTeaserPalier extends StatelessWidget {
  final IconData icone;
  final String feature;
  final NiveauExperience niveauRequis;
  final VoidCallback onFermer;

  const CarteTeaserPalier({
    super.key,
    required this.icone,
    required this.feature,
    required this.niveauRequis,
    required this.onFermer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.all(EspacementsApp.s4),
      padding: const EdgeInsets.fromLTRB(EspacementsApp.s4, EspacementsApp.s3,
          EspacementsApp.s2, EspacementsApp.s3),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: const BorderRadius.all(RayonsApp.lg),
      ),
      child: Row(
        children: [
          Icon(icone,
              size: TaillesIconesApp.md,
              color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: EspacementsApp.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.teaserPalierTexte(
                      feature, l10n.niveauExperience(niveauRequis)),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSecondaryContainer),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: EspacementsApp.s1),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => context.go(RoutesApp.plusNiveaux),
                    child: Text(l10n.teaserPalierAction),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: l10n.teaserFermer,
            icon: Icon(Icons.close,
                size: TaillesIconesApp.md,
                color: theme.colorScheme.onSecondaryContainer),
            onPressed: onFermer,
          ),
        ],
      ),
    );
  }
}
