import 'package:riverpod/riverpod.dart';

import '../../domain/entities/tache.dart';
import '../../domain/enums/cible_tache.dart';
import '../../domain/enums/priorite_tache.dart';
import '../providers/horloge_provider.dart';
import '../providers/repository_providers.dart';
import 'accueil_notifier.dart';
import 'calendrier_notifier.dart';

/// Locale used to resolve the crop display name (French-first app).
const String _locale = 'fr';

/// View-model of the task-detail screen: the task itself plus its resolved
/// target (a display name and, when navigable, the in-app route to open it).
///
/// A result value object assembled by [DetailTacheNotifier]; immutable snapshot.
class DetailTacheVue {
  final Tache _tache;
  final String? _cibleNom;
  final String? _cibleRoute;

  const DetailTacheVue._(this._tache, this._cibleNom, this._cibleRoute);

  factory DetailTacheVue({
    required Tache tache,
    String? cibleNom,
    String? cibleRoute,
  }) =>
      DetailTacheVue._(tache, cibleNom, cibleRoute);

  /// The task being viewed.
  Tache get tache => _tache;

  /// Display name of the task's target (zone / crop / garden), or `null` when
  /// it cannot be resolved (e.g. a deleted zone, or an equipment target).
  String? get cibleNom => _cibleNom;

  /// In-app route that opens the task's target, or `null` when there is nothing
  /// to navigate to.
  String? get cibleRoute => _cibleRoute;
}

/// Drives the **task-detail** screen (`/calendrier/tache/:id`): loads one task,
/// resolves its target, and exposes the actions that mutate it — completing /
/// reopening, rescheduling, cancelling, changing the priority and editing the
/// free-text notes.
///
/// Editing notes and priority is the detail screen's own value: the quick task
/// form covers title/type/date/target, but leaves those two — and the lifecycle
/// transitions — without a surface. Every mutation persists through the domain
/// entity's own methods, then reloads and invalidates the agenda and dashboard
/// so their lists stay in sync.
///
/// `build` returns `null` when the id matches no task (e.g. it was just
/// deleted); the screen then shows a "not found" state.
class DetailTacheNotifier extends AsyncNotifier<DetailTacheVue?> {
  DetailTacheNotifier(this.tacheId);

  /// The task id being viewed (family argument).
  final String tacheId;

  @override
  Future<DetailTacheVue?> build() async {
    final tache = await ref.watch(tacheRepositoryProvider).obtenirParId(tacheId);
    if (tache == null) return null;

    final (nom, route) = await _resoudreCible(tache);
    return DetailTacheVue(tache: tache, cibleNom: nom, cibleRoute: route);
  }

  /// Marks the task done (now) or reopens it, then persists and reloads.
  Future<void> basculerFait() async {
    final tache = state.value?.tache;
    if (tache == null) return;
    if (tache.estFaite) {
      tache.rouvrir();
    } else {
      tache.marquerFaite(ref.read(horlogeProvider)());
    }
    await _persister(tache);
  }

  /// Reschedules the task to [nouvelleDate] (resets it to to-do).
  Future<void> reporter(DateTime nouvelleDate) async {
    final tache = state.value?.tache;
    if (tache == null) return;
    tache.reporter(nouvelleDate);
    await _persister(tache);
  }

  /// Cancels the task.
  Future<void> annuler() async {
    final tache = state.value?.tache;
    if (tache == null) return;
    tache.annuler();
    await _persister(tache);
  }

  /// Changes the task priority.
  Future<void> changerPriorite(PrioriteTache priorite) async {
    final tache = state.value?.tache;
    if (tache == null) return;
    tache.changerPriorite(priorite);
    await _persister(tache);
  }

  /// Deletes the task, then refreshes the agenda and dashboard. The screen pops
  /// afterwards (this view-model no longer has anything to show).
  Future<void> supprimerTache() async {
    final tache = state.value?.tache;
    if (tache == null) return;
    await ref.read(tacheRepositoryProvider).supprimer(tache.id);
    ref.invalidate(calendrierProvider);
    ref.invalidate(accueilProvider);
  }

  /// Sets or clears the task's free-text notes (the "add details later" field).
  Future<void> modifierNotes(String? notes) async {
    final tache = state.value?.tache;
    if (tache == null) return;
    final propre = (notes == null || notes.trim().isEmpty) ? null : notes.trim();
    tache.modifierNotes(propre);
    await _persister(tache);
  }

  /// Persists [tache], reloads this view-model, and refreshes the agenda and
  /// dashboard so their task lists reflect the change.
  Future<void> _persister(Tache tache) async {
    await ref.read(tacheRepositoryProvider).sauvegarder(tache);
    ref.invalidate(calendrierProvider);
    ref.invalidate(accueilProvider);
    ref.invalidateSelf();
  }

  /// Resolves a `(displayName, route)` pair for the task's target. The route is
  /// the zone detail for a parcelle/plantation (a plantation resolves through
  /// its parcelle), the Potager root for a garden target, and `null` for an
  /// equipment (no dedicated screen to deep-link to yet).
  Future<(String?, String?)> _resoudreCible(Tache tache) async {
    switch (tache.cible) {
      case CibleTache.potager:
        final potager =
            await ref.read(potagerRepositoryProvider).obtenirPotagerActif();
        final nom = potager?.id == tache.cibleId ? potager!.nom : null;
        return (nom, '/potager');
      case CibleTache.parcelle:
        final parcelle =
            await ref.read(parcelleRepositoryProvider).obtenirParId(tache.cibleId);
        if (parcelle == null) return (null, null);
        return (parcelle.nom, '/potager/zone/${parcelle.id}');
      case CibleTache.plantation:
        final plantation = await ref
            .read(plantationRepositoryProvider)
            .obtenirParId(tache.cibleId);
        if (plantation == null) return (null, null);
        final fiche = await (await ref.read(fichePlanteRepositoryProvider.future))
            .obtenirParId(plantation.planteId);
        final nom = fiche?.nomLocalise(_locale);
        // Deep-link to the plantation's zone (the crop is shown there).
        return (nom, '/potager/zone/${plantation.parcelleId}');
      case CibleTache.equipement:
        return (null, null);
    }
  }
}

/// Task-detail view-model, keyed by task id.
final detailTacheProvider = AsyncNotifierProvider.family<DetailTacheNotifier,
    DetailTacheVue?, String>(DetailTacheNotifier.new);
