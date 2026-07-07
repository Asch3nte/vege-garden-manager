import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/dimensions_app.dart';
import '../../../application/providers/service_providers.dart';
import '../../../l10n/app_localizations.dart';
import 'widgets_parametres.dart';

/// Public source repository (docs/11 §7 — "lien GitHub").
final Uri _urlCodeSource =
    Uri.parse('https://github.com/Asch3nte/vege-garden-manager');

/// Category 6 — **À propos**: identity, version, MIT licence, source/links,
/// credits, and the standard third-party licences page.
class PanneauAPropos extends ConsumerWidget {
  const PanneauAPropos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final version = ref.watch(versionAppliProvider).value ?? '…';

    return PanneauParametres(
      titre: l10n.categApropos,
      enfants: [
        // Identity block.
        Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.3),
              child: Icon(Icons.eco, color: theme.colorScheme.primary, size: TaillesIconesApp.xl),
            ),
            const SizedBox(height: EspacementsApp.s3),
            Text(l10n.aproposNom, style: theme.textTheme.headlineSmall),
            const SizedBox(height: EspacementsApp.s1),
            Text(
              l10n.aproposVersion(version),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: EspacementsApp.s1),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_outlined, size: TaillesIconesApp.sm, color: theme.colorScheme.primary),
                const SizedBox(width: EspacementsApp.s1),
                Text(
                  l10n.aproposLicence,
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: EspacementsApp.s5),
        ZoneParametres(
          enfants: [
            _LigneAction(
              icone: Icons.code,
              label: l10n.aproposCodeSource,
              onTap: () => _ouvrirLien(context, ref, _urlCodeSource),
            ),
            _LigneAction(
              icone: Icons.description_outlined,
              label: l10n.aproposLicences,
              onTap: () => showLicensePage(
                context: context,
                applicationName: l10n.aproposNom,
                applicationVersion: version,
              ),
            ),
          ],
        ),
        ZoneParametres(
          titre: l10n.aproposCredits,
          enfants: [
            _LigneCredit(titre: l10n.aproposCreditsDonnees, sousTitre: l10n.aproposCreditsDonneesSub),
            _LigneCredit(titre: l10n.aproposCreditsIcones, sousTitre: l10n.aproposCreditsIconesSub),
          ],
        ),
      ],
    );
  }

  /// Opens [url] externally; shows a snackbar if no handler is available.
  Future<void> _ouvrirLien(
    BuildContext context,
    WidgetRef ref,
    Uri url,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final ouvert = await ref.read(ouvertureLienServiceProvider).ouvrir(url);
    if (!ouvert) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.aproposLienErreur)));
    }
  }
}

class _LigneAction extends StatelessWidget {
  final IconData icone;
  final String label;
  final VoidCallback? onTap;

  const _LigneAction({required this.icone, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Transparent Material so the ink ripple isn't hidden by the section's
    // coloured background (ZoneParametres) — same fix as panneau_donnees.dart.
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        enabled: onTap != null,
        leading: Icon(icone, color: theme.colorScheme.primary),
        title: Text(label, style: theme.textTheme.bodyMedium),
        trailing: Icon(Icons.chevron_right, size: TaillesIconesApp.md, color: theme.colorScheme.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }
}

class _LigneCredit extends StatelessWidget {
  final String titre;
  final String sousTitre;

  const _LigneCredit({required this.titre, required this.sousTitre});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(titre, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        sousTitre,
        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}
