import 'package:uuid/uuid.dart';

import '../../domain/entities/plantation.dart';
import '../../domain/entities/tache.dart';
import '../../domain/enums/cible_tache.dart';
import '../../domain/enums/priorite_tache.dart';
import '../../domain/enums/type_tache.dart';
import '../../domain/enums/urgence_arrosage.dart';
import '../../domain/repositories/abstract_fiche_plante_repository.dart';
import '../../domain/repositories/abstract_notification_service.dart';
import '../../domain/repositories/abstract_plantation_repository.dart';
import '../../domain/repositories/abstract_potager_repository.dart';
import '../../domain/repositories/abstract_preferences_repository.dart';
import '../../domain/repositories/abstract_tache_repository.dart';
import '../../domain/value_objects/conseil_arrosage.dart';
import '../../domain/value_objects/fenetre_ne_pas_deranger.dart';
import '../../domain/value_objects/notification_locale.dart';
import '../providers/repository_providers.dart';
import '../providers/service_providers.dart';
import 'calculer_besoin_arrosage.dart';
import 'package:riverpod/riverpod.dart';

/// Materializes watering tasks for all active plantations that need water today.
///
/// Called once per dashboard load (see `AccueilNotifier`). Idempotent: skips
/// plantations that already have an uncompleted watering task today, and removes
/// tasks for plantations whose urgency has dropped below
/// [UrgenceArrosage.arroserMaintenant] (e.g. after rain).
///
/// Each generated task names its crop ("Arroser : Tomate") so the plan says
/// *what* to water, not a generic chore. To water today, a **single** recap
/// notification (category `'arrosage'`) is scheduled at 08:00 — never one per
/// plant (minimise spam) — carrying the crop names in its title (with a "+N"
/// overflow marker) and the full list in its body (maximum detail). It does
/// nothing if 08:00 has already passed (ADR-0015).
///
/// The notification id is **day-scoped** (`arrosage_<yyyy-MM-dd>`), so re-running
/// rewrites the pending notification with an up-to-date list instead of stacking
/// duplicates, and a day that no longer needs any watering **cancels** it
/// (ADR-0020). Crops the user has already ticked off are excluded from the count.
///
/// The push notification honours the user's notification **opt-outs** (docs/11,
/// absolute constraint #3): it is suppressed when the master switch is off, when
/// the `'arrosage'` category is muted, or when 08:00 falls inside the
/// do-not-disturb window. The **tasks themselves are always created** — opt-outs
/// mute notifications, not the gardening plan.
class GenererTachesArrosage {
  final AbstractPlantationRepository _plantations;
  final AbstractPotagerRepository _potager;
  final AbstractTacheRepository _taches;
  final AbstractNotificationService _notifications;
  final AbstractPreferencesRepository _preferences;
  final AbstractFichePlanteRepository _fiches;
  final CalculerBesoinArrosage _calcul;

  GenererTachesArrosage(
    this._plantations,
    this._potager,
    this._taches,
    this._notifications,
    this._preferences,
    this._fiches,
    this._calcul, {
    DateTime Function()? maintenant,
  }) : _maintenant = maintenant ?? DateTime.now;

  final DateTime Function() _maintenant;
  static const Uuid _uuid = Uuid();

  /// Generates or removes watering tasks according to the current advice for
  /// every active plantation. Safe to call multiple times on the same day.
  ///
  /// - `arroserMaintenant` → task due **today** (priority: urgente), counted in
  ///   the day's single push notification.
  /// - `bientot` → task due **today + joursAvantArrosage** (priority: normale, no notification).
  /// - `pasNecessaire` / null → all pending watering tasks are removed.
  ///
  /// Idempotent: if a task already exists on the target day (completed or not),
  /// no duplicate is created. A completed task is never deleted — it records that
  /// the user already watered the plant. Pending tasks on the *wrong* day are
  /// cleaned up when urgency or timing shifts.
  Future<void> executer() async {
    final potager = await _potager.obtenirPotagerActif();
    if (potager == null) return;

    final plantations = await _plantations.obtenirActives();
    final n = _maintenant();
    final debutJour = DateTime(n.year, n.month, n.day);

    // Notification opt-outs (constraint #3): the watering push is only scheduled
    // when the master switch is on and the 'arrosage' category is not muted.
    // The do-not-disturb window is time-based, so it is checked per scheduled
    // time in [_programmerRecap]. Loaded once — constant across plantations.
    final prefs = await _preferences.charger();
    final arrosageNotifiable = prefs.notificationsGlobalesActives &&
        (prefs.notificationsParCategorie['arrosage'] ?? true);
    final fenetreNpd = prefs.fenetreNePasDeranger;

    // Crops still waiting for water **today** — already-ticked ones excluded, so
    // the day's single recap always reflects what is actually left to do. Names
    // are collected (not just counted) so the notification can be specific while
    // staying a single ping (never one per plant: minimise notification spam).
    final aArroserAujourdhui = <String?>[];

    for (final plantation in plantations) {
      final conseil = await _calcul.executer(
        plantation: plantation,
        localisation: potager.localisation,
        meteoAutoActive: prefs.meteoAutoActive,
      );

      // All watering tasks for this plantation regardless of day.
      final toutesExistantes = (await _taches.obtenirParCible(
        CibleTache.plantation,
        plantation.id,
      ))
          .where((t) => t.type == TypeTache.arrosage)
          .toList();

      final urgence = conseil?.urgence;

      if (urgence == null || urgence == UrgenceArrosage.pasNecessaire) {
        // No watering needed — remove all pending tasks.
        for (final t in toutesExistantes.where((t) => !t.estFaite)) {
          await _taches.supprimer(t.id);
        }
        continue;
      }

      final targetDate = _dateCible(conseil!, debutJour);
      final priorite = urgence == UrgenceArrosage.arroserMaintenant
          ? PrioriteTache.urgente
          : PrioriteTache.normale;
      // Remove uncompleted tasks on wrong days (urgency or timing shifted).
      for (final t in toutesExistantes
          .where((t) => !t.estFaite && !_memeJour(t.datePrevue, targetDate))) {
        await _taches.supprimer(t.id);
      }

      // Resolve the crop's common name so the task (and the recap notification)
      // names *which* plant to water — "Arroser : Tomate" rather than a generic
      // "Arroser" that reads like a whole-garden chore. Null when the sheet is
      // missing; the title then falls back to the generic verb.
      final nom = await _nomPlante(plantation);

      // Create only if no task on the target day (completed or not).
      // A completed task on the target day means the user already watered — skip.
      final tousAuTarget = toutesExistantes
          .where((t) => _memeJour(t.datePrevue, targetDate))
          .toList();

      if (tousAuTarget.isEmpty) {
        await _taches.sauvegarder(Tache(
          id: _uuid.v4(),
          titre: nom == null ? 'Arroser' : 'Arroser : $nom',
          type: TypeTache.arrosage,
          cible: CibleTache.plantation,
          cibleId: plantation.id,
          datePrevue: targetDate,
          priorite: priorite,
        ));
      }

      // Recap the notification only for what is urgent **today** and not already
      // watered (a completed task on the target day means the user watered it).
      if (urgence == UrgenceArrosage.arroserMaintenant &&
          !tousAuTarget.any((t) => t.estFaite)) {
        aArroserAujourdhui.add(nom);
      }
    }

    // A single push notification for everything urgent today, honouring the
    // notification opt-outs (constraint #3). The tasks themselves are always
    // created above — opt-outs mute the notification, not the gardening plan.
    // Called even with nothing to water: the day-scoped id must then be
    // cancelled rather than left pending (ADR-0020).
    await _programmerRecap(
      aArroserAujourdhui,
      debutJour,
      fenetreNpd,
      notifiable: arrosageNotifiable,
    );
  }

  /// Target day for a watering task: today for [UrgenceArrosage.arroserMaintenant],
  /// today + [ConseilArrosage.joursAvantArrosage] for [UrgenceArrosage.bientot].
  DateTime _dateCible(ConseilArrosage conseil, DateTime debutJour) {
    if (conseil.urgence == UrgenceArrosage.arroserMaintenant) return debutJour;
    return debutJour.add(Duration(days: conseil.joursAvantArrosage ?? 2));
  }

  /// The plant's French common name for [plantation], or `null` when its sheet
  /// cannot be resolved. French is used deliberately (a stored task title / OS
  /// notification, generated without a UI locale — the app is French-first; the
  /// notification-i18n debt is tracked separately, docs/15).
  Future<String?> _nomPlante(Plantation plantation) async {
    final fiche = await _fiches.obtenirParId(plantation.planteId);
    return fiche?.nomLocalise('fr');
  }

  /// Schedules **one** recap notification at 08:00 on [debutJour] for all the
  /// cultures to water today ([noms], `null` = an unresolved crop).
  ///
  /// One notification per day, not one per crop: five thirsty crops used to mean
  /// five identical pings. The id is **day-scoped** (`arrosage_<yyyy-MM-dd>`), so
  /// re-running rewrites the pending notification with an up-to-date list rather
  /// than stacking duplicates — and a day with nothing left to water **cancels**
  /// it (ADR-0020). The cancellation goes through regardless of the time of day;
  /// scheduling does nothing once 08:00 has passed.
  ///
  /// To limit spam to a single notification while still being specific, the crop
  /// names go **in the title** (truncated with a "+N" overflow marker) and the
  /// **full list** in the body.
  ///
  /// [notifiable] carries the notification opt-outs (constraint #3): when false,
  /// nothing is scheduled and any pending notification for the day is cancelled.
  /// [fenetreNpd] suppresses a notification whose time falls in the
  /// do-not-disturb window.
  Future<void> _programmerRecap(
    List<String?> noms,
    DateTime debutJour,
    FenetreNePasDeranger? fenetreNpd, {
    required bool notifiable,
  }) async {
    final dateStr = '${debutJour.year.toString().padLeft(4, '0')}'
        '-${debutJour.month.toString().padLeft(2, '0')}'
        '-${debutJour.day.toString().padLeft(2, '0')}';
    final id = 'arrosage_$dateStr';

    // Nothing left to water today (or notifications opted out) → drop any
    // notification already pending for the day instead of letting it fire.
    if (noms.isEmpty || !notifiable) {
      await _notifications.annuler(id);
      return;
    }

    final heure = debutJour.copyWith(
        hour: 8, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    if (!heure.isAfter(_maintenant())) return;
    // Do-not-disturb: suppress a notification whose time is inside the window.
    if (fenetreNpd != null && fenetreNpd.contient(heure)) return;

    final connus = noms.whereType<String>().toList();
    final total = noms.length;

    await _notifications.programmer(
      NotificationLocale(
        id: id,
        titre: _titreRecap(connus, total),
        corps: _corpsRecap(connus, total),
        dateProgrammee: heure,
        categorie: 'arrosage',
        cibleRoute: '/calendrier',
      ),
    );
  }

  /// Notification title: the named crops (up to [_maxNomsTitre]) after the verb,
  /// with a "+N" marker for the rest — e.g. "Arroser Tomate, Courgette +2".
  /// Falls back to a generic title when no crop name could be resolved.
  static String _titreRecap(List<String> connus, int total) {
    if (connus.isEmpty) return 'Arrosage à prévoir';
    final visibles = connus.take(_maxNomsTitre).join(', ');
    final restants = total - connus.take(_maxNomsTitre).length;
    return restants > 0 ? 'Arroser $visibles +$restants' : 'Arroser $visibles';
  }

  /// Notification body: the full crop list (max detail), or a count when names
  /// are unavailable.
  static String _corpsRecap(List<String> connus, int total) {
    if (connus.isEmpty) {
      return total == 1
          ? "Une culture a besoin d'eau aujourd'hui."
          : "$total cultures ont besoin d'eau aujourd'hui.";
    }
    if (total == 1) return "${connus.first} a besoin d'eau aujourd'hui.";
    return "Cultures à arroser aujourd'hui : ${connus.join(', ')}.";
  }

  /// How many crop names to spell out in the notification title before the
  /// "+N" overflow marker (the body always lists them all).
  static const int _maxNomsTitre = 3;

  bool _memeJour(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// DI provider for [GenererTachesArrosage]. Async because [CalculerBesoinArrosage]
/// depends on the YAML catalogue (async load). Uses [Ref.read] for all repos —
/// this is a one-shot action provider, not a reactive dependency.
final genererTachesArrosageProvider = FutureProvider<GenererTachesArrosage>(
  (ref) async => GenererTachesArrosage(
    ref.read(plantationRepositoryProvider),
    ref.read(potagerRepositoryProvider),
    ref.read(tacheRepositoryProvider),
    ref.read(notificationServiceProvider),
    ref.read(preferencesRepositoryProvider),
    await ref.read(fichePlanteRepositoryProvider.future),
    await ref.read(calculerBesoinArrosageProvider.future),
  ),
);
