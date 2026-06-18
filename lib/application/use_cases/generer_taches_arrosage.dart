import 'package:uuid/uuid.dart';

import '../../domain/entities/plantation.dart';
import '../../domain/entities/tache.dart';
import '../../domain/enums/cible_tache.dart';
import '../../domain/enums/priorite_tache.dart';
import '../../domain/enums/type_tache.dart';
import '../../domain/enums/urgence_arrosage.dart';
import '../../domain/repositories/abstract_notification_service.dart';
import '../../domain/repositories/abstract_plantation_repository.dart';
import '../../domain/repositories/abstract_potager_repository.dart';
import '../../domain/repositories/abstract_tache_repository.dart';
import '../../domain/value_objects/conseil_arrosage.dart';
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
/// Also schedules a local push notification (category `'arrosage'`) at 08:00
/// on the task day — does nothing if 08:00 has already passed (ADR-0015).
class GenererTachesArrosage {
  final AbstractPlantationRepository _plantations;
  final AbstractPotagerRepository _potager;
  final AbstractTacheRepository _taches;
  final AbstractNotificationService _notifications;
  final CalculerBesoinArrosage _calcul;

  GenererTachesArrosage(
    this._plantations,
    this._potager,
    this._taches,
    this._notifications,
    this._calcul, {
    DateTime Function()? maintenant,
  }) : _maintenant = maintenant ?? DateTime.now;

  final DateTime Function() _maintenant;
  static const Uuid _uuid = Uuid();

  /// Generates or removes watering tasks according to the current advice for
  /// every active plantation. Safe to call multiple times on the same day.
  ///
  /// - `arroserMaintenant` → task due **today** (priority: urgente) + push notification.
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

    for (final plantation in plantations) {
      final conseil = await _calcul.executer(
        plantation: plantation,
        localisation: potager.localisation,
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

      // Create only if no task on the target day (completed or not).
      // A completed task on the target day means the user already watered — skip.
      final tousAuTarget = toutesExistantes
          .where((t) => _memeJour(t.datePrevue, targetDate))
          .toList();
      if (tousAuTarget.isEmpty) {
        await _taches.sauvegarder(Tache(
          id: _uuid.v4(),
          titre: 'Arroser',
          type: TypeTache.arrosage,
          cible: CibleTache.plantation,
          cibleId: plantation.id,
          datePrevue: targetDate,
          priorite: priorite,
        ));
        // Push notifications only for truly urgent cases (today).
        if (urgence == UrgenceArrosage.arroserMaintenant) {
          await _programmerNotification(plantation, targetDate);
        }
      }
    }
  }

  /// Target day for a watering task: today for [UrgenceArrosage.arroserMaintenant],
  /// today + [ConseilArrosage.joursAvantArrosage] for [UrgenceArrosage.bientot].
  DateTime _dateCible(ConseilArrosage conseil, DateTime debutJour) {
    if (conseil.urgence == UrgenceArrosage.arroserMaintenant) return debutJour;
    return debutJour.add(Duration(days: conseil.joursAvantArrosage ?? 2));
  }

  /// Schedules a push notification at 08:00 on [debutJour].
  /// Does nothing if 08:00 has already passed on that day.
  Future<void> _programmerNotification(
    Plantation plantation,
    DateTime debutJour,
  ) async {
    final heure = debutJour.copyWith(
        hour: 8, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    if (!heure.isAfter(_maintenant())) return;
    final dateStr =
        '${debutJour.year.toString().padLeft(4, '0')}'
        '-${debutJour.month.toString().padLeft(2, '0')}'
        '-${debutJour.day.toString().padLeft(2, '0')}';
    await _notifications.programmer(
      NotificationLocale(
        id: 'arrosage_${plantation.id}_$dateStr',
        titre: 'Arrosage à prévoir',
        corps: "Une de vos cultures a besoin d'eau aujourd'hui.",
        dateProgrammee: heure,
        categorie: 'arrosage',
        cibleRoute: '/potager',
      ),
    );
  }

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
    await ref.read(calculerBesoinArrosageProvider.future),
  ),
);
