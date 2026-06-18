import 'package:riverpod/riverpod.dart';

import '../../domain/entities/potager.dart';
import '../../domain/entities/tache.dart';
import '../../domain/enums/cible_tache.dart';
import '../../domain/enums/type_tache.dart';
import '../../domain/repositories/abstract_fiche_plante_repository.dart';
import '../../domain/repositories/abstract_parcelle_repository.dart';
import '../../domain/repositories/abstract_plantation_repository.dart';
import '../../domain/repositories/abstract_potager_repository.dart';
import '../../domain/repositories/abstract_tache_repository.dart';
import '../providers/horloge_provider.dart';
import '../providers/repository_providers.dart';
import '../use_cases/generer_taches_arrosage.dart';
import 'calendrier_vue.dart';

/// Locale used to resolve crop display names (French-first app).
const String _locale = 'fr';

/// Drives the **Calendrier** agenda: the tasks over the current window
/// ([PorteeAgenda]), grouped by day, with the action to tick a task off.
///
/// Reads come from [AbstractTacheRepository.obtenirEntreDates]; ticking a task
/// uses the domain's `Tache.marquerFaite` then persists via the repository.
/// Reopening a completed task is **not** offered — the domain has no plain
/// "reopen" transition (only `reporter`, which reschedules); see docs/15.
class CalendrierNotifier extends AsyncNotifier<CalendrierVue> {
  PorteeAgenda _portee = PorteeAgenda.semaine;

  /// First day of the month shown by the monthly grid (set on first build).
  DateTime? _moisAffiche;

  /// Active gesture filter (null = show every type), applied to both views.
  TypeTache? _filtreType;

  /// The currently selected gesture filter (null = all).
  TypeTache? get filtreType => _filtreType;

  @override
  Future<CalendrierVue> build() async {
    final taches = ref.watch(tacheRepositoryProvider);
    final parcelles = ref.watch(parcelleRepositoryProvider);
    final plantations = ref.watch(plantationRepositoryProvider);
    final potagers = ref.watch(potagerRepositoryProvider);
    // The catalogue loads from YAML assets asynchronously.
    final fiches = await ref.watch(fichePlanteRepositoryProvider.future);
    final maintenant = ref.watch(horlogeProvider);
    final n = maintenant();
    _moisAffiche ??= DateTime(n.year, n.month, 1);

    // Ensure watering tasks are generated before querying the task list so the
    // calendar is up-to-date even when the user opens this tab first.
    // ref.read() — one-shot action, must not create a reactive dependency.
    final generateur = await ref.read(genererTachesArrosageProvider.future);
    await generateur.executer();

    return _assembler(
        taches, parcelles, plantations, potagers, fiches, maintenant);
  }

  /// Switches the window scope (week / month) and reloads.
  Future<void> definirPortee(PorteeAgenda portee) async {
    if (portee == _portee) return;
    _portee = portee;
    await _recharger();
  }

  /// Moves the monthly grid to the previous month and reloads.
  Future<void> moisPrecedent() async {
    final m = _moisAffiche!;
    _moisAffiche = DateTime(m.year, m.month - 1, 1);
    await _recharger();
  }

  /// Moves the monthly grid to the next month and reloads.
  Future<void> moisSuivant() async {
    final m = _moisAffiche!;
    _moisAffiche = DateTime(m.year, m.month + 1, 1);
    await _recharger();
  }

  /// Returns the monthly grid to the current month and reloads.
  Future<void> revenirMoisActuel() async {
    final n = ref.read(horlogeProvider)();
    _moisAffiche = DateTime(n.year, n.month, 1);
    await _recharger();
  }

  /// Filters both views to a single gesture type (null = show all) and reloads.
  Future<void> definirFiltreType(TypeTache? type) async {
    if (type == _filtreType) return;
    _filtreType = type;
    await _recharger();
  }

  /// Deletes [tache] and reloads.
  Future<void> supprimer(Tache tache) async {
    await ref.read(tacheRepositoryProvider).supprimer(tache.id);
    await _recharger();
  }

  /// Toggles [tache]'s completion (check ↔ uncheck), persists it, then reloads.
  Future<void> cocher(Tache tache) async {
    if (tache.estFaite) {
      tache.rouvrir();
    } else {
      tache.marquerFaite(ref.read(horlogeProvider)());
    }
    await ref.read(tacheRepositoryProvider).sauvegarder(tache);
    await _recharger();
  }

  Future<void> _recharger() async {
    final taches = ref.read(tacheRepositoryProvider);
    final parcelles = ref.read(parcelleRepositoryProvider);
    final plantations = ref.read(plantationRepositoryProvider);
    final potagers = ref.read(potagerRepositoryProvider);
    final maintenant = ref.read(horlogeProvider);
    // Keep the current data visible during the reload (no loading flash), so the
    // month grid and its day selection don't reset on a tick / month change.
    state = await AsyncValue.guard(() async {
      final fiches = await ref.read(fichePlanteRepositoryProvider.future);
      return _assembler(
          taches, parcelles, plantations, potagers, fiches, maintenant);
    });
  }

  Future<CalendrierVue> _assembler(
    AbstractTacheRepository taches,
    AbstractParcelleRepository parcelles,
    AbstractPlantationRepository plantations,
    AbstractPotagerRepository potagers,
    AbstractFichePlanteRepository fiches,
    DateTime Function() maintenant,
  ) async {
    final debut = _minuit(maintenant());
    final fin = _finFenetre(debut);
    final liste = _filtrer(await taches.obtenirEntreDates(debut, fin));

    // Full displayed month for the grid (independent of the agenda window).
    final moisDebut = _moisAffiche!;
    final moisFin = DateTime(moisDebut.year, moisDebut.month + 1, 1);
    final listeMois =
        _filtrer(await taches.obtenirEntreDates(moisDebut, moisFin));

    final potagerActif = await potagers.obtenirPotagerActif();
    final ciblesNoms = await _resoudreCibles(
      [...liste, ...listeMois],
      parcelles,
      plantations,
      fiches,
      potagerActif,
    );

    return CalendrierVue(
      portee: _portee,
      groupes: _grouperParJour(liste),
      moisAffiche: moisDebut,
      groupesMois: _grouperParJour(listeMois),
      ciblesNoms: ciblesNoms,
    );
  }

  /// Resolves each task target to a display name, once per distinct
  /// `'<cible>:<cibleId>'`. A target that no longer resolves (deleted, or
  /// equipment which has no screen yet) is simply omitted — the card then shows
  /// no target rather than an invented one.
  Future<Map<String, String>> _resoudreCibles(
    Iterable<Tache> taches,
    AbstractParcelleRepository parcelles,
    AbstractPlantationRepository plantations,
    AbstractFichePlanteRepository fiches,
    Potager? potagerActif,
  ) async {
    // Distinct targets first, so each is resolved a single time.
    final distinctes = <String, Tache>{};
    for (final t in taches) {
      distinctes.putIfAbsent('${t.cible.name}:${t.cibleId}', () => t);
    }

    final noms = <String, String>{};
    for (final entree in distinctes.entries) {
      final nom = await _nomCible(
          entree.value, parcelles, plantations, fiches, potagerActif);
      if (nom != null) noms[entree.key] = nom;
    }
    return noms;
  }

  /// Display name of a single task's target, or `null` when unresolved.
  Future<String?> _nomCible(
    Tache tache,
    AbstractParcelleRepository parcelles,
    AbstractPlantationRepository plantations,
    AbstractFichePlanteRepository fiches,
    Potager? potagerActif,
  ) async {
    switch (tache.cible) {
      case CibleTache.potager:
        return potagerActif?.id == tache.cibleId ? potagerActif!.nom : null;
      case CibleTache.parcelle:
        return (await parcelles.obtenirParId(tache.cibleId))?.nom;
      case CibleTache.plantation:
        final plantation = await plantations.obtenirParId(tache.cibleId);
        if (plantation == null) return null;
        final fiche = await fiches.obtenirParId(plantation.planteId);
        return fiche?.nomLocalise(_locale);
      case CibleTache.equipement:
        return null;
    }
  }

  /// Exclusive end of the window: +7 days (week) or first day of next month.
  DateTime _finFenetre(DateTime debut) {
    return switch (_portee) {
      PorteeAgenda.semaine => debut.add(const Duration(days: 7)),
      PorteeAgenda.mois => DateTime(debut.year, debut.month + 1, 1),
    };
  }

  /// Groups tasks by local day, ordered by day then (undone first, by time).
  static List<GroupeJour> _grouperParJour(List<Tache> taches) {
    final parJour = <DateTime, List<Tache>>{};
    for (final t in taches) {
      final jour = _minuit(t.datePrevue);
      parJour.putIfAbsent(jour, () => []).add(t);
    }

    final jours = parJour.keys.toList()..sort();
    return [
      for (final jour in jours)
        GroupeJour(
          jour: jour,
          taches: parJour[jour]!
            ..sort((a, b) {
              if (a.estFaite != b.estFaite) return a.estFaite ? 1 : -1;
              return a.datePrevue.compareTo(b.datePrevue);
            }),
        ),
    ];
  }

  /// Applies the active gesture filter (no-op when none is set).
  List<Tache> _filtrer(List<Tache> taches) => _filtreType == null
      ? taches
      : taches.where((t) => t.type == _filtreType).toList();

  /// Local midnight of [d].
  static DateTime _minuit(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// The Calendrier agenda view-model provider.
final calendrierProvider =
    AsyncNotifierProvider<CalendrierNotifier, CalendrierVue>(
  CalendrierNotifier.new,
);
