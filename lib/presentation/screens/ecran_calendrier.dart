import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/couleurs_app.dart';
import '../../app/theme/dimensions_app.dart';
import '../../application/providers/horloge_provider.dart';
import '../../application/state/calendrier_notifier.dart';
import '../../application/state/calendrier_vue.dart';
import '../../application/state/saison_notifier.dart';
import '../../application/state/saison_vue.dart';
import '../../domain/entities/tache.dart';
import '../../domain/enums/type_tache.dart';
import '../../domain/value_objects/periode.dart';
import '../../l10n/app_localizations.dart';
import '../forms/formulaire_tache.dart';
import '../widgets/dialogue_confirmation.dart';
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
    final notifier = ref.read(calendrierProvider.notifier);

    Future<void> creerTache() async {
      final messenger = ScaffoldMessenger.of(context);
      final tache = await ouvrirFormulaireTache(context);
      if (tache == null) return;
      ref.invalidate(calendrierProvider);
      messenger.showSnackBar(SnackBar(content: Text(l10n.snackTacheCreee)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navCalendrier),
        actions: [
          PopupMenuButton<TypeTache?>(
            icon: Icon(notifier.filtreType == null
                ? Icons.filter_list
                : Icons.filter_list_alt),
            tooltip: l10n.calendrierFiltrer,
            onSelected: notifier.definirFiltreType,
            itemBuilder: (context) => [
              PopupMenuItem(value: null, child: Text(l10n.calendrierFiltreTous)),
              for (final t in TypeTache.values)
                PopupMenuItem(value: t, child: Text(l10n.typeTache(t))),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.calendrierAjouterTache,
            onPressed: creerTache,
          ),
        ],
      ),
      body: vue.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _EtatErreur(onReessayer: () => ref.invalidate(calendrierProvider)),
        data: (data) => _Contenu(vue: data),
      ),
    );
  }
}

class _Contenu extends ConsumerStatefulWidget {
  final CalendrierVue vue;

  const _Contenu({required this.vue});

  @override
  ConsumerState<_Contenu> createState() => _ContenuState();
}

class _ContenuState extends ConsumerState<_Contenu> {
  _VueCal _vue = _VueCal.agenda;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          child: SegmentedButton<_VueCal>(
            segments: [
              ButtonSegment(
                value: _VueCal.agenda,
                icon: const Icon(Icons.view_agenda_outlined),
                label: Text(l10n.calendrierVueAgenda),
              ),
              ButtonSegment(
                value: _VueCal.mois,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(l10n.calendrierVueMois),
              ),
              ButtonSegment(
                value: _VueCal.saison,
                icon: const Icon(Icons.eco_outlined),
                label: Text(l10n.calendrierVueSaison),
              ),
            ],
            selected: {_vue},
            onSelectionChanged: (s) => setState(() => _vue = s.first),
            showSelectedIcon: false,
          ),
        ),
        Expanded(
          child: switch (_vue) {
            _VueCal.agenda => _VueAgenda(vue: widget.vue),
            _VueCal.mois => _VueMois(vue: widget.vue),
            _VueCal.saison => const _VueSaison(),
          },
        ),
      ],
    );
  }
}

/// The three calendar views.
enum _VueCal { agenda, mois, saison }

/// The **Agenda** view: week/month scope selector, summary and day groups.
class _VueAgenda extends ConsumerWidget {
  final CalendrierVue vue;

  const _VueAgenda({required this.vue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(calendrierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: EspacementsApp.s4,
            vertical: EspacementsApp.s2,
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
                        cibleLabelDe: vue.cibleNom,
                        onCocher: notifier.cocher,
                        onModifier: (t) => _modifierTache(context, ref, t),
                        onSupprimer: (t) => _supprimerTache(context, ref, t),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// The **Mois** view: a navigable monthly grid with per-day task dots, and the
/// selected day's task list below.
class _VueMois extends ConsumerStatefulWidget {
  final CalendrierVue vue;

  const _VueMois({required this.vue});

  @override
  ConsumerState<_VueMois> createState() => _VueMoisState();
}

class _VueMoisState extends ConsumerState<_VueMois> {
  /// User-picked day, or null to fall back to today / the first of the month.
  DateTime? _selection;

  static bool _memeMois(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final vue = widget.vue;
    final notifier = ref.read(calendrierProvider.notifier);
    final n = ref.read(horlogeProvider)();
    final aujourdhui = DateTime(n.year, n.month, n.day);
    final mois = vue.moisAffiche;

    final jourSel = (_selection != null && _memeMois(_selection!, mois))
        ? _selection!
        : (_memeMois(aujourdhui, mois) ? aujourdhui : mois);
    final groupeSel = vue.groupePourJour(jourSel);
    final tachesSel = groupeSel?.taches ?? const <Tache>[];
    final faitesSel = tachesSel.where((t) => t.estFaite).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        EspacementsApp.s4,
        0,
        EspacementsApp.s4,
        EspacementsApp.s6,
      ),
      children: [
        _BarreMois(
          mois: mois,
          onPrecedent: notifier.moisPrecedent,
          onSuivant: notifier.moisSuivant,
          onAujourdhui: () {
            notifier.revenirMoisActuel();
            setState(() => _selection = aujourdhui);
          },
        ),
        const SizedBox(height: EspacementsApp.s3),
        _Grille(
          mois: mois,
          aujourdhui: aujourdhui,
          selection: jourSel,
          vue: vue,
          onJour: (j) => setState(() => _selection = j),
        ),
        const SizedBox(height: EspacementsApp.s4),
        Row(
          children: [
            Text(
              l10n.dateJourMois(jourSel.day, _mois(jourSel.month)),
              style: theme.textTheme.titleLarge,
            ),
            const Spacer(),
            if (tachesSel.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: EspacementsApp.s3,
                  vertical: EspacementsApp.s1,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: const BorderRadius.all(RayonsApp.full),
                ),
                child: Text(
                  l10n.calendrierProgression(faitesSel, tachesSel.length),
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.primary),
                ),
              ),
          ],
        ),
        const SizedBox(height: EspacementsApp.s3),
        if (tachesSel.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: EspacementsApp.s5),
            child: Text(
              l10n.calendrierVide,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          )
        else
          for (final tache in tachesSel) ...[
            _CarteTache(
              tache: tache,
              cibleLabel: vue.cibleNom(tache),
              onCocher: notifier.cocher,
              onModifier: (t) => _modifierTache(context, ref, t),
              onSupprimer: (t) => _supprimerTache(context, ref, t),
            ),
            const SizedBox(height: EspacementsApp.s2),
          ],
      ],
    );
  }
}

/// Month bar: ‹ Month Year › + "Aujourd'hui".
class _BarreMois extends StatelessWidget {
  final DateTime mois;
  final VoidCallback onPrecedent;
  final VoidCallback onSuivant;
  final VoidCallback onAujourdhui;

  const _BarreMois({
    required this.mois,
    required this.onPrecedent,
    required this.onSuivant,
    required this.onAujourdhui,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final libelle = _moisFr[mois.month - 1];
    final titre = '${libelle[0].toUpperCase()}${libelle.substring(1)} ${mois.year}';

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrecedent,
        ),
        Expanded(
          child: Text(
            titre,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: onSuivant,
        ),
        TextButton(onPressed: onAujourdhui, child: Text(l10n.jourAujourdhui)),
      ],
    );
  }
}

/// The day grid: weekday header + day cells (leading blanks for the offset).
class _Grille extends StatelessWidget {
  final DateTime mois;
  final DateTime aujourdhui;
  final DateTime selection;
  final CalendrierVue vue;
  final ValueChanged<DateTime> onJour;

  const _Grille({
    required this.mois,
    required this.aujourdhui,
    required this.selection,
    required this.vue,
    required this.onJour,
  });

  static const List<String> _joursSemaine = [
    'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offset = mois.weekday - 1; // Monday-based leading blanks
    final nbJours = DateTime(mois.year, mois.month + 1, 0).day;

    // Cap the grid width so cells stay phone-sized on wide screens.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          children: [
            Row(
              children: [
                for (final j in _joursSemaine)
                  Expanded(
                    child: Text(
                      j,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: EspacementsApp.s2),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.9,
              children: [
                for (var i = 0; i < offset; i++) const SizedBox.shrink(),
                for (var jour = 1; jour <= nbJours; jour++)
                  _CelluleJour(
                    date: DateTime(mois.year, mois.month, jour),
                    aujourdhui: aujourdhui,
                    selection: selection,
                    groupe:
                        vue.groupePourJour(DateTime(mois.year, mois.month, jour)),
                    onTap: onJour,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A single day cell: number + up to three task dots (or a check if all done).
class _CelluleJour extends StatelessWidget {
  final DateTime date;
  final DateTime aujourdhui;
  final DateTime selection;
  final GroupeJour? groupe;
  final ValueChanged<DateTime> onTap;

  const _CelluleJour({
    required this.date,
    required this.aujourdhui,
    required this.selection,
    required this.groupe,
    required this.onTap,
  });

  static bool _memeJour(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estAujourdhui = _memeJour(date, aujourdhui);
    final estSelectionne = _memeJour(date, selection);
    final taches = groupe?.taches ?? const <Tache>[];
    final toutFait = taches.isNotEmpty && taches.every((t) => t.estFaite);

    return InkWell(
      borderRadius: RayonsApp.brMd,
      onTap: () => onTap(date),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: estSelectionne
              ? theme.colorScheme.primary.withValues(alpha: 0.18)
              : null,
          borderRadius: const BorderRadius.all(RayonsApp.md),
          border: estAujourdhui
              ? Border.all(color: theme.colorScheme.primary, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: estSelectionne || estAujourdhui
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 8,
              child: toutFait
                  ? Icon(Icons.check,
                      size: 10, color: theme.colorScheme.primary)
                  : _Pastilles(taches: taches),
            ),
          ],
        ),
      ),
    );
  }
}

/// Up to three coloured dots for a day's tasks, then a "+N" overflow.
class _Pastilles extends StatelessWidget {
  final List<Tache> taches;

  const _Pastilles({required this.taches});

  @override
  Widget build(BuildContext context) {
    if (taches.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final montrees = taches.take(3).toList();
    final reste = taches.length - montrees.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final t in montrees)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: couleurTypeTache(t.type),
                shape: BoxShape.circle,
              ),
            ),
          ),
        if (reste > 0)
          Text(
            '+$reste',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
      ],
    );
  }
}

/// The **Saison** view: per-plant sowing/planting/harvest bands across the year,
/// resolved for the active garden's hemisphere × climate. Read-only.
class _VueSaison extends ConsumerWidget {
  const _VueSaison();

  /// Leading column width (plant name / band label), shared by header and rows.
  static const double _largeurLabel = 78;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(saisonProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.calendrierErreurChargement)),
      data: (vue) {
        if (!vue.contexteConnu) return _MessageCentre(texte: l10n.saisonSansContexte);
        if (vue.vide) return _MessageCentre(texte: l10n.saisonVide);
        final moisActuel = ref.read(horlogeProvider)().month;

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            EspacementsApp.s4,
            0,
            EspacementsApp.s4,
            EspacementsApp.s6,
          ),
          children: [
            if (vue.hemisphereSuppose)
              Padding(
                padding: const EdgeInsets.only(bottom: EspacementsApp.s3),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: TaillesIconesApp.sm,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: EspacementsApp.s2),
                    Expanded(
                      child: Text(
                        l10n.saisonHemisphereSuppose,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            _EnteteMois(moisActuel: moisActuel, largeurLabel: _largeurLabel),
            for (final ligne in vue.lignes)
              _BlocSaison(
                ligne: ligne,
                moisActuel: moisActuel,
                largeurLabel: _largeurLabel,
              ),
            const SizedBox(height: EspacementsApp.s4),
            const _LegendeSaison(),
          ],
        );
      },
    );
  }
}

/// Month-initials header aligned with the season tracks.
class _EnteteMois extends StatelessWidget {
  final int moisActuel;
  final double largeurLabel;

  const _EnteteMois({required this.moisActuel, required this.largeurLabel});

  static const List<String> _initiales = [
    'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: EspacementsApp.s2),
      child: Row(
        children: [
          SizedBox(width: largeurLabel),
          for (var m = 1; m <= 12; m++)
            Expanded(
              child: Text(
                _initiales[m - 1],
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: m == moisActuel
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: m == moisActuel ? FontWeight.w700 : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One plant's block: its name and its (present) sowing/planting/harvest tracks.
class _BlocSaison extends StatelessWidget {
  final LigneSaison ligne;
  final int moisActuel;
  final double largeurLabel;

  const _BlocSaison({
    required this.ligne,
    required this.moisActuel,
    required this.largeurLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: EspacementsApp.s3,
            bottom: EspacementsApp.s1,
          ),
          child: Text(ligne.nom, style: theme.textTheme.titleMedium),
        ),
        if (!ligne.aDesDonnees)
          Text(
            l10n.saisonNonRenseigne,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          )
        else ...[
          if (ligne.semis != null)
            _Piste(
              label: l10n.saisonSemis,
              periode: ligne.semis!,
              couleur: CouleursApp.decoVertMoyen,
              moisActuel: moisActuel,
              largeurLabel: largeurLabel,
            ),
          if (ligne.plantation != null)
            _Piste(
              label: l10n.saisonPlantation,
              periode: ligne.plantation!,
              couleur: CouleursApp.accentPrimaireClair,
              moisActuel: moisActuel,
              largeurLabel: largeurLabel,
            ),
          if (ligne.recolte != null)
            _Piste(
              label: l10n.saisonRecolte,
              periode: ligne.recolte!,
              couleur: CouleursApp.decoAubergine,
              moisActuel: moisActuel,
              largeurLabel: largeurLabel,
            ),
        ],
      ],
    );
  }
}

/// A 12-month track: cells filled where [periode] covers the month.
class _Piste extends StatelessWidget {
  final String label;
  final Periode periode;
  final Color couleur;
  final int moisActuel;
  final double largeurLabel;

  const _Piste({
    required this.label,
    required this.periode,
    required this.couleur,
    required this.moisActuel,
    required this.largeurLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: largeurLabel,
            child: Text(
              label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          for (var m = 1; m <= 12; m++)
            Expanded(
              child: Container(
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: periode.contientMois(m)
                      ? couleur
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.all(Radius.circular(3)),
                  border: m == moisActuel
                      ? Border.all(color: theme.colorScheme.primary, width: 1)
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Legend: the three band kinds + the current-month marker.
class _LegendeSaison extends StatelessWidget {
  const _LegendeSaison();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: EspacementsApp.s4,
      runSpacing: EspacementsApp.s2,
      children: [
        _ItemLegende(couleur: CouleursApp.decoVertMoyen, texte: l10n.saisonSemis),
        _ItemLegende(
          couleur: CouleursApp.accentPrimaireClair,
          texte: l10n.saisonPlantation,
        ),
        _ItemLegende(couleur: CouleursApp.decoAubergine, texte: l10n.saisonRecolte),
      ],
    );
  }
}

class _ItemLegende extends StatelessWidget {
  final Color couleur;
  final String texte;

  const _ItemLegende({required this.couleur, required this.texte});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: couleur,
            borderRadius: const BorderRadius.all(Radius.circular(3)),
          ),
        ),
        const SizedBox(width: EspacementsApp.s1),
        Text(texte, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

/// A centered informational message (no garden / no plant).
class _MessageCentre extends StatelessWidget {
  final String texte;

  const _MessageCentre({required this.texte});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EspacementsApp.s6),
        child: Text(
          texte,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
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

  /// Resolves a task's target display name (zone / crop / garden).
  final String? Function(Tache) cibleLabelDe;
  final ValueChanged<Tache> onCocher;
  final ValueChanged<Tache> onModifier;
  final ValueChanged<Tache> onSupprimer;

  const _GroupeJour({
    required this.groupe,
    required this.cibleLabelDe,
    required this.onCocher,
    required this.onModifier,
    required this.onSupprimer,
  });

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
          _CarteTache(
            tache: tache,
            cibleLabel: cibleLabelDe(tache),
            onCocher: onCocher,
            onModifier: onModifier,
            onSupprimer: onSupprimer,
          ),
          const SizedBox(height: EspacementsApp.s2),
        ],
      ],
    );
  }
}

/// One tickable task card: gesture icon + title + check.
class _CarteTache extends StatelessWidget {
  final Tache tache;

  /// Resolved name of the task's target (zone / crop / garden), or `null`.
  final String? cibleLabel;
  final ValueChanged<Tache> onCocher;
  final ValueChanged<Tache> onModifier;
  final ValueChanged<Tache> onSupprimer;

  const _CarteTache({
    required this.tache,
    required this.cibleLabel,
    required this.onCocher,
    required this.onModifier,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final fait = tache.estFaite;

    return Card(
      child: InkWell(
        borderRadius: RayonsApp.brLg,
        // Tapping toggles completion (check ↔ uncheck via Tache.rouvrir).
        onTap: () => onCocher(tache),
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
                    Row(
                      children: [
                        Text(
                          l10n.typeTache(tache.type),
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                        if (cibleLabel != null) ...[
                          Text(
                            ' · ',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                          Icon(
                            Icons.place_outlined,
                            size: TaillesIconesApp.sm,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          Flexible(
                            child: Text(
                              cibleLabel!,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: EspacementsApp.s2),
              Icon(
                fait ? Icons.check_circle : Icons.radio_button_unchecked,
                color: fait ? theme.colorScheme.primary : theme.colorScheme.outline,
              ),
              PopupMenuButton<_ActionTache>(
                tooltip: l10n.actionsTache,
                onSelected: (action) => switch (action) {
                  _ActionTache.modifier => onModifier(tache),
                  _ActionTache.supprimer => onSupprimer(tache),
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: _ActionTache.modifier,
                    child: Text(l10n.actionModifier),
                  ),
                  PopupMenuItem(
                    value: _ActionTache.supprimer,
                    child: Text(l10n.actionSupprimer),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Per-task overflow actions in the calendar.
enum _ActionTache { modifier, supprimer }

/// Opens the task form pre-filled on [tache]; reloads the agenda on save.
Future<void> _modifierTache(
  BuildContext context,
  WidgetRef ref,
  Tache tache,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context)!;
  final modifiee = await ouvrirFormulaireTache(context, tacheInitiale: tache);
  if (modifiee == null) return;
  ref.invalidate(calendrierProvider);
  messenger.showSnackBar(SnackBar(content: Text(l10n.snackTacheModifiee)));
}

/// Asks for confirmation, then deletes [tache] and reloads the agenda.
Future<void> _supprimerTache(
  BuildContext context,
  WidgetRef ref,
  Tache tache,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context)!;
  final confirme = await confirmerAction(
    context,
    titre: l10n.tacheSupprimerTitre,
    message: l10n.tacheSupprimerMessage(tache.titre),
    libelleConfirmer: l10n.actionSupprimer,
    destructif: true,
  );
  if (!confirme) return;
  await ref.read(calendrierProvider.notifier).supprimer(tache);
  messenger.showSnackBar(SnackBar(content: Text(l10n.snackTacheSupprimee)));
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
