import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/dimensions_app.dart';
import '../../app/theme/theme_app.dart';
import '../../domain/entities/tache.dart';
import '../../domain/enums/type_alerte_meteo.dart';
import '../../domain/value_objects/alerte_culture.dart';
import '../../l10n/app_localizations.dart';
import '../providers/notifications_accueil_provider.dart';
import 'libelles_enums.dart';

/// Opens the home **notifications** panel as a bottom sheet: the current weather
/// alerts (frost / heatwave / heavy rain on the cultures in place) and today's
/// urgent, not-yet-done tasks. Read-only — the panel surfaces what already fires
/// as OS notifications (no notification history is stored, docs/15 §2).
Future<void> afficherNotificationsAccueil(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _PanneauNotificationsAccueil(),
  );
}

class _PanneauNotificationsAccueil extends ConsumerWidget {
  const _PanneauNotificationsAccueil();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final async = ref.watch(notificationsAccueilProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(EspacementsApp.s4, 0,
            EspacementsApp.s4, EspacementsApp.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.notifAccueilTitre, style: theme.textTheme.titleLarge),
            const SizedBox(height: EspacementsApp.s3),
            async.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(EspacementsApp.s5),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: EspacementsApp.s4),
                child: Text(
                  l10n.notifAccueilErreur,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              data: (vue) => _Contenu(vue: vue),
            ),
          ],
        ),
      ),
    );
  }
}

class _Contenu extends StatelessWidget {
  final NotificationsAccueilVue vue;

  const _Contenu({required this.vue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (vue.estVide) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: EspacementsApp.s4),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline,
                size: TaillesIconesApp.md, color: theme.colorScheme.primary),
            const SizedBox(width: EspacementsApp.s3),
            Expanded(
              child: Text(l10n.notifAccueilVide,
                  style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
      );
    }

    return Flexible(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (vue.alertes.isNotEmpty) ...[
              _TitreSection(texte: l10n.notifAccueilSectionAlertes),
              for (final a in vue.alertes) _LigneAlerte(alerte: a),
            ],
            if (vue.tachesUrgentes.isNotEmpty) ...[
              if (vue.alertes.isNotEmpty)
                const SizedBox(height: EspacementsApp.s3),
              _TitreSection(texte: l10n.notifAccueilSectionTaches),
              for (final t in vue.tachesUrgentes) _LigneTache(tache: t),
            ],
          ],
        ),
      ),
    );
  }
}

class _TitreSection extends StatelessWidget {
  final String texte;

  const _TitreSection({required this.texte});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: EspacementsApp.s1),
      child: Text(
        texte,
        style: theme.textTheme.labelMedium
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// One weather-alert row: type icon + localised message.
class _LigneAlerte extends StatelessWidget {
  final AlerteCulture alerte;

  const _LigneAlerte({required this.alerte});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accents = theme.extension<AccentsCarnet>()!;
    final l10n = AppLocalizations.of(context)!;

    final (IconData icone, Color couleur) = switch (alerte.type) {
      TypeAlerteMeteo.gel => (Icons.ac_unit, accents.info),
      TypeAlerteMeteo.canicule => (Icons.wb_sunny_outlined, accents.chaud),
      TypeAlerteMeteo.fortePluie => (Icons.water_drop_outlined, accents.info),
    };

    final count = alerte.plantationsConcernees.length;
    final date = _dateCourte(alerte.date);
    final valeur = alerte.valeurDeclenchante.round().toString();
    final message = switch (alerte.type) {
      TypeAlerteMeteo.gel => l10n.notifAlerteGel(count, date, valeur),
      TypeAlerteMeteo.canicule => l10n.notifAlerteCanicule(count, date, valeur),
      TypeAlerteMeteo.fortePluie =>
        l10n.notifAlerteFortePluie(count, date, valeur),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: EspacementsApp.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: TaillesIconesApp.md, color: couleur),
          const SizedBox(width: EspacementsApp.s3),
          Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// One urgent-task row: type icon + title + short due date.
class _LigneTache extends StatelessWidget {
  final Tache tache;

  const _LigneTache({required this.tache});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: EspacementsApp.s2),
      child: Row(
        children: [
          Icon(iconeTypeTache(tache.type),
              size: TaillesIconesApp.md, color: theme.colorScheme.primary),
          const SizedBox(width: EspacementsApp.s3),
          Expanded(child: Text(tache.titre, style: theme.textTheme.bodyMedium)),
          Text(
            _dateCourte(tache.datePrevue),
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Short `dd/MM` date (matches the app's other compact date displays).
String _dateCourte(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
