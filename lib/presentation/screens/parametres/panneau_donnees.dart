import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/service_providers.dart';
import '../../../application/state/preferences_notifier.dart';
import '../../../application/state/statistiques_donnees_notifier.dart';
import '../../../domain/enums/mode_import.dart';
import '../../../domain/exceptions/sauvegarde_invalide_exception.dart';
import '../../../l10n/app_localizations.dart';
import '../../services/gestionnaire_sauvegarde_fichier.dart';
import '../../widgets/dialogue_confirmation.dart';
import '../../widgets/invalidation_vues.dart';
import 'widgets_parametres.dart';

/// Settings category — **Sauvegarde & données**: export (share a JSON backup),
/// import (restore from a picked file, replace or merge), and a destructive
/// **factory reset** (double-confirmed). All local: backups are produced and
/// consumed on-device; sharing is driven by the user.
class PanneauDonnees extends ConsumerWidget {
  const PanneauDonnees({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return PanneauParametres(
      titre: l10n.categDonnees,
      enfants: [
        ZoneParametres(
          titre: l10n.donneesSauvegardeSectionTitre,
          note: l10n.donneesExportNote,
          enfants: [
            _Ligne(
              icone: Icons.ios_share,
              libelle: l10n.donneesExportBouton,
              onTap: () => _exporter(context, ref),
            ),
            const Divider(height: 1),
            _Ligne(
              icone: Icons.file_open_outlined,
              libelle: l10n.donneesImportBouton,
              onTap: () => _importer(context, ref),
            ),
          ],
        ),
        const _SectionStockage(),
        ZoneParametres(
          titre: l10n.donneesResetSectionTitre,
          note: l10n.donneesResetNote,
          enfants: [
            _Ligne(
              icone: Icons.delete_forever_outlined,
              libelle: l10n.donneesResetBouton,
              couleur: theme.colorScheme.error,
              onTap: () => _reinitialiser(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  /// Exports the whole database to a JSON file and opens the share sheet.
  Future<void> _exporter(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final json = await ref.read(sauvegardeServiceProvider).exporterJson();
      // Filesystem-safe stamp (no ':' from the ISO time → invalid on Windows /
      // some share targets): YYYY-MM-DDTHH-MM-SS.
      final horodatage = DateTime.now()
          .toIso8601String()
          .split('.')
          .first
          .replaceAll(':', '-');
      await ref
          .read(gestionnaireSauvegardeFichierProvider)
          .partager(json, 'potager-export-$horodatage.json');
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.donneesExportErreur)));
    }
  }

  /// Picks a backup file, asks for the import mode, then restores it.
  Future<void> _importer(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    final contenu =
        await ref.read(gestionnaireSauvegardeFichierProvider).choisirEtLire();
    if (contenu == null || !context.mounted) return; // cancelled

    final mode = await _choisirMode(context);
    if (mode == null) return;

    try {
      await ref.read(sauvegardeServiceProvider).importerJson(contenu, mode);
      // The imported data (and possibly preferences) must replace the cached
      // state everywhere.
      ref.invalidate(preferencesProvider);
      invaliderVuesDonnees(ref);
      messenger.showSnackBar(SnackBar(content: Text(l10n.donneesImportSucces)));
    } on SauvegardeInvalideException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.donneesImportErreur)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.donneesImportErreur)));
    }
  }

  /// Asks whether to replace everything or merge by id; `null` if cancelled.
  Future<ModeImport?> _choisirMode(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<ModeImport>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.donneesImportModeTitre),
        children: [
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: Text(l10n.donneesImportModeRemplacer),
            subtitle: Text(l10n.donneesImportModeRemplacerSub),
            onTap: () => Navigator.of(ctx).pop(ModeImport.remplacer),
          ),
          ListTile(
            leading: const Icon(Icons.merge_type),
            title: Text(l10n.donneesImportModeFusionner),
            subtitle: Text(l10n.donneesImportModeFusionnerSub),
            onTap: () => Navigator.of(ctx).pop(ModeImport.fusionner),
          ),
        ],
      ),
    );
  }

  /// Double-confirms, then wipes everything and reloads the gating providers so
  /// the router redirects to the onboarding.
  Future<void> _reinitialiser(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;

    final premier = await confirmerAction(
      context,
      titre: l10n.donneesResetTitre,
      message: l10n.donneesResetMessage1,
      libelleConfirmer: l10n.donneesResetConfirmer1,
      destructif: true,
    );
    if (!premier || !context.mounted) return;

    final second = await confirmerAction(
      context,
      titre: l10n.donneesResetTitre,
      message: l10n.donneesResetMessage2,
      libelleConfirmer: l10n.donneesResetConfirmer2,
      destructif: true,
    );
    if (!second) return;

    await ref.read(reinitialisationServiceProvider).reinitialiserTout();
    // Reload the first-run gate (preferences → onboarding) and every data view
    // (so no stale garden/zones linger); the router's refresh on preferences
    // then redirects to the onboarding.
    ref.invalidate(preferencesProvider);
    invaliderVuesDonnees(ref);
  }
}

/// Data-transparency section (docs/11 §6): the database's on-disk size and the
/// per-table record counts — read live from the SQLite database, so the user
/// can see exactly what the app keeps on this device (nothing leaves it).
class _SectionStockage extends ConsumerWidget {
  const _SectionStockage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final stats = ref.watch(statistiquesDonneesProvider);

    return ZoneParametres(
      titre: l10n.donneesStockageSectionTitre,
      note: l10n.donneesStockageNote,
      enfants: [
        stats.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, _) => Material(
            type: MaterialType.transparency,
            child: ListTile(
              leading: Icon(Icons.error_outline, color: theme.colorScheme.error),
              title: Text(l10n.donneesStockageErreur),
              trailing: TextButton(
                onPressed: () => ref.invalidate(statistiquesDonneesProvider),
                child: Text(l10n.actionReessayer),
              ),
            ),
          ),
          data: (s) => Column(
            children: [
              Material(
                type: MaterialType.transparency,
                child: ListTile(
                  leading: const Icon(Icons.sd_storage_outlined),
                  title: Text(l10n.donneesStockageTaille),
                  subtitle: Text(l10n.donneesStockageTotalLignes(s.totalLignes)),
                  trailing: Text(
                    _formaterTaille(l10n, s.tailleOctets),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
              for (final t in s.tables) ...[
                const Divider(height: 1),
                Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    dense: true,
                    title: Text(t.nom, style: theme.textTheme.bodyMedium),
                    trailing: Text(
                      '${t.lignes}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Formats a byte count into a compact localised size (o / Ko / Mo), one
  /// decimal above the byte range.
  static String _formaterTaille(AppLocalizations l10n, int octets) {
    if (octets < 1024) return l10n.donneesTailleOctets(octets);
    final ko = octets / 1024;
    if (ko < 1024) return l10n.donneesTailleKo(ko.toStringAsFixed(1));
    final mo = ko / 1024;
    return l10n.donneesTailleMo(mo.toStringAsFixed(1));
  }
}

/// A tappable settings row, wrapped in a transparent Material so its ink ripple
/// is not hidden by the section's coloured background (ZoneParametres).
class _Ligne extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final VoidCallback onTap;
  final Color? couleur;

  const _Ligne({
    required this.icone,
    required this.libelle,
    required this.onTap,
    this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        leading: Icon(icone, color: couleur),
        title: Text(libelle, style: couleur == null ? null : TextStyle(color: couleur)),
        onTap: onTap,
      ),
    );
  }
}
