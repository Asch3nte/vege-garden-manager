import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/dimensions_app.dart';
import '../../application/providers/horloge_provider.dart';
import '../../application/state/notifications_notifier.dart';
import '../../domain/enums/type_alerte_meteo.dart';
import '../../domain/value_objects/alerte_culture.dart';
import '../../l10n/app_localizations.dart';
import '../glossaire/terme_cliquable.dart';
import '../glossaire/terme_glossaire.dart';
import '../glossaire/type_terme_glossaire.dart';

/// Notifications inbox opened from the dashboard bell (`/accueil/notifications`).
///
/// Surfaces the app's active **weather alerts** — the structured verdicts of
/// [alertesMeteoProvider] (frost / heatwave / heavy rain over the alert horizon)
/// — which until now only existed as a count on the dashboard. In V1 an alert is
/// generic: it concerns every in-place culture of the active garden (no per-plant
/// sensitivity data yet, see `docs/13` §2.1), so the card reports how many
/// cultures are affected rather than naming them.
///
/// Empty (and without any forecast fetch) when the auto-weather opt-out is off,
/// when the garden has no position, or when there is no in-place culture.
class EcranNotifications extends ConsumerWidget {
  const EcranNotifications({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final alertes = ref.watch(alertesMeteoProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsTitre)),
      body: alertes.when(
        // Keep the list on screen while it silently reloads (no flash).
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _EtatErreur(
          onReessayer: () => ref.invalidate(alertesMeteoProvider),
        ),
        data: (liste) => liste.isEmpty ? const _EtatVide() : _Liste(alertes: liste),
      ),
    );
  }
}

/// Non-empty state: a scrollable, pull-to-refresh list of alert cards.
class _Liste extends ConsumerWidget {
  final List<AlerteCulture> alertes;

  const _Liste({required this.alertes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final now = ref.read(horlogeProvider)();
    final aujourd = DateTime(now.year, now.month, now.day);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(alertesMeteoProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          EspacementsApp.s4,
          EspacementsApp.s4,
          EspacementsApp.s4,
          EspacementsApp.s6,
        ),
        children: [
          // Clickable glossary term (ADR-0017): explains what weather alerts are.
          Padding(
            padding: const EdgeInsets.only(bottom: EspacementsApp.s2),
            child: TermeCliquable(
              idTerme: TermeGlossaire.idNotion('alertes-meteo'),
              texte: l10n.notificationsEntete,
              type: TypeTermeGlossaire.notion,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final alerte in alertes)
            Padding(
              padding: const EdgeInsets.only(bottom: EspacementsApp.s3),
              child: _CarteAlerte(alerte: alerte, aujourd: aujourd),
            ),
        ],
      ),
    );
  }
}

/// One alert: type icon, title, triggering figure, day and affected-culture count.
class _CarteAlerte extends StatelessWidget {
  final AlerteCulture alerte;

  /// Local midnight of "today", to label the day relative to now.
  final DateTime aujourd;

  const _CarteAlerte({required this.alerte, required this.aujourd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final couleur = _couleur(theme);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(EspacementsApp.s3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.16),
                borderRadius: const BorderRadius.all(RayonsApp.md),
              ),
              child: Icon(_icone, color: couleur, size: TaillesIconesApp.md),
            ),
            const SizedBox(width: EspacementsApp.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_titre(l10n), style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    _detail(l10n),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: EspacementsApp.s2),
                  Row(
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: TaillesIconesApp.sm,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _libelleDate(l10n, alerte.date, aujourd),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      Text(
                        ' · ',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      Flexible(
                        child: Text(
                          l10n.notificationsCulturesConcernees(
                              alerte.plantationsConcernees.length),
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData get _icone => switch (alerte.type) {
        TypeAlerteMeteo.gel => Icons.ac_unit,
        TypeAlerteMeteo.canicule => Icons.wb_sunny_outlined,
        TypeAlerteMeteo.fortePluie => Icons.water_drop_outlined,
      };

  Color _couleur(ThemeData theme) => switch (alerte.type) {
        // Frost reads cold (secondary/blue-ish), heat & heavy rain read as risk.
        TypeAlerteMeteo.gel => theme.colorScheme.primary,
        TypeAlerteMeteo.canicule => theme.colorScheme.error,
        TypeAlerteMeteo.fortePluie => theme.colorScheme.tertiary,
      };

  String _titre(AppLocalizations l10n) => switch (alerte.type) {
        TypeAlerteMeteo.gel => l10n.notificationsAlerteGelTitre,
        TypeAlerteMeteo.canicule => l10n.notificationsAlerteCaniculeTitre,
        TypeAlerteMeteo.fortePluie => l10n.notificationsAlerteFortePluieTitre,
      };

  String _detail(AppLocalizations l10n) {
    final v = alerte.valeurDeclenchante.round();
    return switch (alerte.type) {
      TypeAlerteMeteo.gel => l10n.notificationsAlerteGelDetail(v),
      TypeAlerteMeteo.canicule => l10n.notificationsAlerteCaniculeDetail(v),
      TypeAlerteMeteo.fortePluie => l10n.notificationsAlerteFortePluieDetail(v),
    };
  }
}

/// Day label relative to today: "Aujourd'hui" / "Demain" / "12 juillet".
String _libelleDate(AppLocalizations l10n, DateTime jour, DateTime aujourd) {
  final j = DateTime(jour.year, jour.month, jour.day);
  final delta = j.difference(aujourd).inDays;
  if (delta == 0) return l10n.jourAujourdhui;
  if (delta == 1) return l10n.jourDemain;
  return l10n.dateJourMois(j.day, _moisFr[j.month - 1]);
}

/// French month names, matching the convention of the weather/calendar screens.
const List<String> _moisFr = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

/// Empty state: reassuring message when there is nothing to alert about.
class _EtatVide extends StatelessWidget {
  const _EtatVide();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EspacementsApp.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: EspacementsApp.s3),
            Text(
              l10n.notificationsVide,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: EspacementsApp.s2),
            Text(
              l10n.notificationsVideDetail,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Error state with a retry action.
class _EtatErreur extends StatelessWidget {
  final VoidCallback onReessayer;

  const _EtatErreur({required this.onReessayer});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EspacementsApp.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.accueilErreurChargement, textAlign: TextAlign.center),
            const SizedBox(height: EspacementsApp.s3),
            FilledButton.tonal(
              onPressed: onReessayer,
              child: Text(l10n.actionReessayer),
            ),
          ],
        ),
      ),
    );
  }
}
