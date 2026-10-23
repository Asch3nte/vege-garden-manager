import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/router.dart';
import '../../../app/theme/dimensions_app.dart';
import '../../../application/providers/service_providers.dart';
import '../../../l10n/app_localizations.dart';
import 'widgets_parametres.dart';

/// Public source repository ("lien GitHub").
const String _depot = '/Asch3nte/vege-garden-manager';

final Uri _urlCodeSource = Uri.https('github.com', _depot);

final Uri _urlDocumentation = Uri.https('github.com', '$_depot/tree/main/docs');

/// The bug form, prefilled with the app [version] and nothing else.
Uri _urlSignalerBug(String? version) => Uri.https(
      'github.com',
      '$_depot/issues/new',
      {'template': 'bug.yml', 'version': ?version},
    );

/// Category 6 — **À propos**: identity, version, MIT licence, source/links,
/// credits, and the standard third-party licences page.
class PanneauAPropos extends ConsumerWidget {
  const PanneauAPropos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final versionConnue = ref.watch(versionAppliProvider).value;
    final version = versionConnue ?? '…';

    return PanneauParametres(
      titre: l10n.categApropos,
      enfants: [
        // Identity block.
        Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.3),
              child: Icon(PhosphorIconsBold.leaf, color: theme.colorScheme.primary, size: TaillesIconesApp.xl),
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
                Icon(PhosphorIconsRegular.sealCheck, size: TaillesIconesApp.sm, color: theme.colorScheme.primary),
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
              icone: PhosphorIconsRegular.code,
              label: l10n.aproposCodeSource,
              onTap: () => _ouvrirLien(context, ref, _urlCodeSource),
            ),
            _LigneAction(
              icone: PhosphorIconsRegular.bookOpen,
              label: l10n.aproposDocumentation,
              onTap: () => _ouvrirLien(context, ref, _urlDocumentation),
            ),
            _LigneAction(
              icone: PhosphorIconsRegular.bug,
              label: l10n.aproposSignalerBug,
              onTap: () =>
                  _ouvrirLien(context, ref, _urlSignalerBug(versionConnue)),
            ),
            _LigneAction(
              icone: PhosphorIconsRegular.shieldCheck,
              label: l10n.politiqueConfidentialite,
              onTap: () => context.go(RoutesApp.plusPolitique),
            ),
            _LigneAction(
              icone: PhosphorIconsRegular.fileText,
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
        trailing: Icon(PhosphorIconsRegular.caretRight, size: TaillesIconesApp.md, color: theme.colorScheme.onSurfaceVariant),
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
