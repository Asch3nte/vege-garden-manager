import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/dimensions_app.dart';
import '../../application/providers/horloge_provider.dart';
import '../../application/state/calendrier_notifier.dart';
import '../../application/state/calendrier_vue.dart';
import '../../domain/entities/tache.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/libelles_enums.dart';

/// Tab 4 — **Calendrier**: agenda of upcoming tasks, grouped by day, each
/// tickable (docs/09 §6).
///
/// Reimplemented from `calendrier.jsx`, **Agenda view**: a summary, a week/month
/// scope selector and day groups of tickable task cards. The Month grid and the
/// Season (sowing→harvest) views are deferred — see docs/15.
class EcranCalendrier extends ConsumerWidget {
  const EcranCalendrier({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final vue = ref.watch(calendrierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navCalendrier)),
      body: vue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _EtatErreur(onReessayer: () => ref.invalidate(calendrierProvider)),
        data: (data) => _Contenu(vue: data),
      ),
    );
  }
}

class _Contenu extends ConsumerWidget {
  final CalendrierVue vue;

  const _Contenu({required this.vue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(calendrierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            EspacementsApp.s4,
            EspacementsApp.s3,
            EspacementsApp.s4,
            EspacementsApp.s2,
          ),
          child: _SelecteurPortee(
            portee: vue.portee,
            onChanger: notifier.definirPortee,
          ),
        ),
        if (!vue.vide)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: EspacementsApp.s4),
            child: _Resume(vue: vue),
          ),
        Expanded(
          child: vue.vide
              ? _EtatVide()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    EspacementsApp.s4,
                    EspacementsApp.s3,
                    EspacementsApp.s4,
                    EspacementsApp.s6,
                  ),
                  children: [
                    for (final groupe in vue.groupes)
                      _GroupeJour(
                        groupe: groupe,
                        onCocher: notifier.cocher,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Week / month scope selector.
class _SelecteurPortee extends StatelessWidget {
  final PorteeAgenda portee;
  final ValueChanged<PorteeAgenda> onChanger;

  const _SelecteurPortee({required this.portee, required this.onChanger});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<PorteeAgenda>(
      segments: [
        ButtonSegment(value: PorteeAgenda.semaine, label: Text(l10n.calendrierPorteeSemaine)),
        ButtonSegment(value: PorteeAgenda.mois, label: Text(l10n.calendrierPorteeMois)),
      ],
      selected: {portee},
      onSelectionChanged: (s) => onChanger(s.first),
      showSelectedIcon: false,
    );
  }
}

/// Summary: remaining count + done/total badge.
class _Resume extends StatelessWidget {
  final CalendrierVue vue;

  const _Resume({required this.vue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.calendrierResume(vue.restantes),
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: EspacementsApp.s3, vertical: EspacementsApp.s1),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.14),
            borderRadius: const BorderRadius.all(RayonsApp.full),
          ),
          child: Text(
            l10n.calendrierProgression(vue.faites, vue.total),
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }
}

/// A day's header + its task cards.
class _GroupeJour extends StatelessWidget {
  final GroupeJour groupe;
  final ValueChanged<Tache> onCocher;

  const _GroupeJour({required this.groupe, required this.onCocher});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: EspacementsApp.s4, bottom: EspacementsApp.s2),
          child: Row(
            children: [
              Text(_libelleJour(context, groupe.jour), style: theme.textTheme.titleLarge),
              const SizedBox(width: EspacementsApp.s2),
              Expanded(child: Divider(color: theme.colorScheme.outline)),
            ],
          ),
        ),
        for (final tache in groupe.taches) ...[
          _CarteTache(tache: tache, onCocher: onCocher),
          const SizedBox(height: EspacementsApp.s2),
        ],
      ],
    );
  }
}

/// One tickable task card: gesture icon + title + check.
class _CarteTache extends StatelessWidget {
  final Tache tache;
  final ValueChanged<Tache> onCocher;

  const _CarteTache({required this.tache, required this.onCocher});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final fait = tache.estFaite;

    return Card(
      child: InkWell(
        borderRadius: RayonsApp.brLg,
        // Done tasks can't be reopened (no domain transition — see docs/15).
        onTap: fait ? null : () => onCocher(tache),
        child: Padding(
          padding: const EdgeInsets.all(EspacementsApp.s3),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.all(RayonsApp.md),
                ),
                child: Icon(
                  iconeTypeTache(tache.type),
                  size: TaillesIconesApp.md,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: EspacementsApp.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tache.titre,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: fait ? theme.colorScheme.onSurfaceVariant : null,
                        decoration: fait ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(
                      l10n.typeTache(tache.type),
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: EspacementsApp.s2),
              Icon(
                fait ? Icons.check_circle : Icons.radio_button_unchecked,
                color: fait ? theme.colorScheme.primary : theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EtatVide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EspacementsApp.s6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.coffee_outlined, size: TaillesIconesApp.xl2, color: theme.colorScheme.secondary),
            const SizedBox(height: EspacementsApp.s4),
            Text(
              l10n.calendrierVide,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _EtatErreur extends StatelessWidget {
  final VoidCallback onReessayer;

  const _EtatErreur({required this.onReessayer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EspacementsApp.s6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: TaillesIconesApp.xl2, color: theme.colorScheme.error),
            const SizedBox(height: EspacementsApp.s4),
            Text(
              l10n.calendrierErreurChargement,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: EspacementsApp.s4),
            FilledButton(onPressed: onReessayer, child: Text(l10n.actionReessayer)),
          ],
        ),
      ),
    );
  }
}

/// "Aujourd'hui" / "Demain" / "j mois" for a day group header, relative to the
/// app clock (so it matches the window the notifier built).
String _libelleJour(BuildContext context, DateTime jour) {
  final l10n = AppLocalizations.of(context)!;
  final container = ProviderScope.containerOf(context, listen: false);
  final maintenant = container.read(horlogeProvider)();
  final aujourdhui = DateTime(maintenant.year, maintenant.month, maintenant.day);
  final delta = jour.difference(aujourdhui).inDays;

  if (delta == 0) return l10n.jourAujourdhui;
  if (delta == 1) return l10n.jourDemain;
  return l10n.dateJourMois(jour.day, _mois(jour.month));
}

const List<String> _moisFr = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

String _mois(int m) => _moisFr[m - 1];
