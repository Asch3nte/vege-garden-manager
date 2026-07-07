import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/couleurs_termes.dart';
import '../../app/theme/dimensions_app.dart';
import '../../l10n/app_localizations.dart';
import 'libelles_glossaire.dart';
import 'liens_glossaire.dart';
import 'terme_glossaire.dart';

/// One glossary term row (search results, chapter lists): kind badge + title +
/// the definition's first words (wiki markup stripped). Tapping opens the term
/// page.
class LigneTermeGlossaire extends StatelessWidget {
  final TermeGlossaire terme;

  const LigneTermeGlossaire({super.key, required this.terme});

  /// The definition with wiki links flattened to their display text, so list
  /// previews never show raw `[[…]]` markup.
  String get _apercu =>
      analyserLiensGlossaire(terme.definition).map((s) => s.texte).join();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: EspacementsApp.s2),
      child: Material(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: RayonsApp.brLg,
        child: InkWell(
          borderRadius: RayonsApp.brLg,
          onTap: () => context.go(RoutesApp.aideTerme(terme.id)),
          child: Container(
            padding: const EdgeInsets.all(EspacementsApp.s3),
            decoration: BoxDecoration(
              borderRadius: RayonsApp.brLg,
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(terme.titre,
                                style: theme.textTheme.bodyLarge),
                          ),
                          BadgeTypeTerme(terme: terme),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _apercu,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: EspacementsApp.s2),
                Icon(Icons.chevron_right,
                    size: TaillesIconesApp.md,
                    color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The small kind badge of a term (« Famille botanique », « Maladie »…),
/// tinted by the per-type colour chart (ADR-0017 D5).
class BadgeTypeTerme extends StatelessWidget {
  final TermeGlossaire terme;

  const BadgeTypeTerme({super.key, required this.terme});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final couleur = couleursTermesDe(context).couleurDe(terme.type);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: EspacementsApp.s2, vertical: 2),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.all(RayonsApp.full),
        border: Border.all(color: couleur.withValues(alpha: 0.4)),
      ),
      child: Text(
        l10n.typeTermeGlossaire(terme.type),
        style: theme.textTheme.labelSmall
            ?.copyWith(color: couleur, fontWeight: FontWeight.w600),
      ),
    );
  }
}
