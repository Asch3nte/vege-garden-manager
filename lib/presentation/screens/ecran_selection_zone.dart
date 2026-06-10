import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/dimensions_app.dart';
import '../../application/state/potager_notifier.dart';
import '../../l10n/app_localizations.dart';
import 'ecran_potager.dart' show PlanPotager;

/// Asks the user to pick a zone on the garden plan and returns its id (or `null`
/// if dismissed).
///
/// Used by the "add a plant" flow when the user reached the catalogue without a
/// pre-selected zone (free browse, docs spec §8): the plan opens so they tap the
/// destination bed.
Future<String?> selectionnerZonePourAjout(BuildContext context) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) => const EcranSelectionZone(),
      fullscreenDialog: true,
    ),
  );
}

/// Zone-picker screen: the garden plan, where tapping a bed returns that zone.
class EcranSelectionZone extends ConsumerWidget {
  const EcranSelectionZone({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final vue = ref.watch(potagerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.selectionZoneTitre)),
      body: vue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.potagerErreurChargement)),
        data: (data) {
          if (data.zones.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(EspacementsApp.s6),
                child: Text(
                  l10n.selectionZoneVide,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(EspacementsApp.s4),
            children: [
              Text(
                l10n.selectionZoneInvite,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: EspacementsApp.s3),
              PlanPotager(
                zones: data.zones,
                onZoneTap: (id) => Navigator.of(context).pop(id),
              ),
            ],
          );
        },
      ),
    );
  }
}
