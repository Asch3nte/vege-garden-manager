import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/dimensions_app.dart';
import '../../application/state/catalogue_notifier.dart';
import '../../domain/entities/fiche_plante.dart';
import '../../l10n/app_localizations.dart';
import 'libelles_enums.dart';

/// Opens the detail of a plant sheet as a draggable modal bottom sheet.
///
/// Shows the sheet's **real** fields (category, sun & water needs, spacing,
/// time-to-harvest) and its companion associations (resolved to plant names via
/// the loaded catalogue). The sowing/harvest month calendar of the mock-up is
/// deferred — periods are indexed by hemisphere/climate, which a catalogue
/// browse has no context for (see docs/15).
Future<void> afficherFichePlanteDetail(
  BuildContext context,
  FichePlante fiche,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) =>
          _FichePlanteDetail(fiche: fiche, scrollController: scrollController),
    ),
  );
}

class _FichePlanteDetail extends ConsumerWidget {
  final FichePlante fiche;
  final ScrollController scrollController;

  const _FichePlanteDetail({required this.fiche, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // The entity exposes association *predicates* (not the id sets), so derive
    // the companion names by scanning the loaded catalogue and asking the sheet
    // about each candidate — respecting the entity's encapsulation.
    final catalogue =
        ref.watch(catalogueProvider).value?.fiches ?? const <FichePlante>[];
    final bons = _noms(catalogue.where((f) => fiche.sAssocieBienAvec(f.id)));
    final aEviter = _noms(catalogue.where((f) => fiche.entreEnConflitAvec(f.id)));

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        EspacementsApp.s5,
        0,
        EspacementsApp.s5,
        EspacementsApp.s6,
      ),
      children: [
        Row(
          children: [
            Icon(Icons.eco, size: TaillesIconesApp.xl, color: theme.colorScheme.primary),
            const SizedBox(width: EspacementsApp.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fiche.nomLocalise('fr'), style: theme.textTheme.headlineSmall),
                  Text(
                    l10n.categorie(fiche.categorie),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: EspacementsApp.s2),
        Text(
          fiche.nomScientifique,
          style: theme.textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: EspacementsApp.s5),
        _Faits(fiche: fiche),
        const SizedBox(height: EspacementsApp.s5),
        Text(l10n.ficheAssociations, style: theme.textTheme.titleLarge),
        const SizedBox(height: EspacementsApp.s3),
        _Associations(bons: bons, aEviter: aEviter),
      ],
    );
  }

  /// Localized, alphabetically-sorted names of an iterable of sheets.
  List<String> _noms(Iterable<FichePlante> fiches) =>
      [for (final f in fiches) f.nomLocalise('fr')]..sort();
}

/// Two-column fact grid (exposure, watering, spacing, time-to-harvest).
class _Faits extends StatelessWidget {
  final FichePlante fiche;

  const _Faits({required this.fiche});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final faits = <(IconData, String, String)>[
      (Icons.wb_sunny_outlined, l10n.ficheExposition, l10n.exposition(fiche.besoins.soleil)),
      (Icons.water_drop_outlined, l10n.ficheArrosage, l10n.besoinEau(fiche.besoins.eau)),
      (Icons.straighten, l10n.ficheEspacement, l10n.ficheEspacementCm(fiche.espacementCm)),
      (
        Icons.eco_outlined,
        l10n.ficheRecolte,
        l10n.ficheRecolteJours(
          fiche.dureeAvantRecolteJoursMin,
          fiche.dureeAvantRecolteJoursMax,
        ),
      ),
    ];

    return Column(
      children: [
        for (final (icone, cle, valeur) in faits)
          Padding(
            padding: const EdgeInsets.only(bottom: EspacementsApp.s3),
            child: _Fait(icone: icone, cle: cle, valeur: valeur),
          ),
      ],
    );
  }
}

class _Fait extends StatelessWidget {
  final IconData icone;
  final String cle;
  final String valeur;

  const _Fait({required this.icone, required this.cle, required this.valeur});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icone, size: TaillesIconesApp.md, color: theme.colorScheme.primary),
        const SizedBox(width: EspacementsApp.s3),
        Text(
          cle,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const Spacer(),
        Text(valeur, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

/// Companion plants: good ones and ones to avoid.
class _Associations extends StatelessWidget {
  final List<String> bons;
  final List<String> aEviter;

  const _Associations({required this.bons, required this.aEviter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (bons.isEmpty && aEviter.isEmpty) {
      return Text(
        l10n.ficheAucuneAssociation,
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bons.isNotEmpty) ...[
          Text(l10n.ficheBonsCompagnons, style: theme.textTheme.bodySmall),
          const SizedBox(height: EspacementsApp.s2),
          Wrap(
            spacing: EspacementsApp.s2,
            runSpacing: EspacementsApp.s2,
            children: [for (final n in bons) Chip(label: Text(n))],
          ),
        ],
        if (aEviter.isNotEmpty) ...[
          const SizedBox(height: EspacementsApp.s4),
          Text(
            l10n.ficheAEviter,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
          ),
          const SizedBox(height: EspacementsApp.s2),
          Wrap(
            spacing: EspacementsApp.s2,
            runSpacing: EspacementsApp.s2,
            children: [
              for (final n in aEviter)
                Chip(
                  label: Text(n),
                  side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
