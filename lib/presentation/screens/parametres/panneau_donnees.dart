import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/dimensions_app.dart';
import '../../../application/providers/service_providers.dart';
import '../../../application/state/preferences_notifier.dart';
import '../../../domain/enums/mode_import.dart';
import '../../../domain/exceptions/sauvegarde_invalide_exception.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/inventaire_donnees_provider.dart';
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
        const _SectionTransparence(),
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

/// Display order of the stored tables (user data first, technical tables last);
/// any table not listed here is still shown, appended with its raw SQL name.
const List<String> _ordreTables = [
  'potagers',
  'parcelles',
  'plantations',
  'taches',
  'rappels',
  'observations',
  'recoltes',
  'equipements',
  'fiches_plantes_personnelles',
  'meteo_cache',
  'parametres',
  'preferences',
];

/// Human label for a stored table; falls back to the raw SQL name so a table
/// added later is never hidden from the inventory.
String _libelleTable(AppLocalizations l10n, String table) => switch (table) {
      'potagers' => l10n.transparenceTablePotagers,
      'parcelles' => l10n.transparenceTableParcelles,
      'plantations' => l10n.transparenceTablePlantations,
      'recoltes' => l10n.transparenceTableRecoltes,
      'equipements' => l10n.transparenceTableEquipements,
      'taches' => l10n.transparenceTableTaches,
      'rappels' => l10n.transparenceTableRappels,
      'observations' => l10n.transparenceTableObservations,
      'meteo_cache' => l10n.transparenceTableMeteoCache,
      'parametres' => l10n.transparenceTableParametres,
      'fiches_plantes_personnelles' => l10n.transparenceTableFichesPerso,
      'preferences' => l10n.transparenceTablePreferences,
      _ => table,
    };

/// Read-only data-transparency section: how many records each stored table
/// holds, a total, and the "everything stays local" guarantee. No access
/// journal is kept (docs/15 §6): a local app has no third party to audit.
class _SectionTransparence extends ConsumerWidget {
  const _SectionTransparence();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final async = ref.watch(inventaireDonneesProvider);

    return async.when(
      loading: () => ZoneParametres(
        titre: l10n.transparenceSectionTitre,
        note: l10n.transparenceNote,
        enfants: const [
          Padding(
            padding: EdgeInsets.all(EspacementsApp.s4),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
      error: (_, _) => ZoneParametres(
        titre: l10n.transparenceSectionTitre,
        enfants: [
          Padding(
            padding: const EdgeInsets.all(EspacementsApp.s3),
            child: Text(
              l10n.transparenceErreur,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
      data: (inventaire) {
        // Ordered entries (curated order first, unknown tables appended).
        final parNom = {for (final e in inventaire.entrees) e.table: e.nombre};
        final ordonnees = <String>[
          ..._ordreTables.where(parNom.containsKey),
          ...parNom.keys.where((t) => !_ordreTables.contains(t)),
        ];
        return ZoneParametres(
          titre: l10n.transparenceSectionTitre,
          note: l10n.transparenceNote,
          enfants: [
            for (final table in ordonnees)
              _LigneInventaire(
                libelle: _libelleTable(l10n, table),
                nombre: parNom[table]!,
              ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: EspacementsApp.s3,
                vertical: EspacementsApp.s3,
              ),
              child: Text(
                l10n.transparenceTotal(inventaire.total),
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// One inventory row: a table label on the left, its record count on the right.
class _LigneInventaire extends StatelessWidget {
  final String libelle;
  final int nombre;

  const _LigneInventaire({required this.libelle, required this.nombre});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EspacementsApp.s3,
        vertical: EspacementsApp.s2,
      ),
      child: Row(
        children: [
          Expanded(child: Text(libelle, style: theme.textTheme.bodyMedium)),
          Text(
            '$nombre',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
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
