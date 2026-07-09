import '../entities/preferences_utilisateur.dart';
import '../value_objects/notification_locale.dart';

/// Applies the user's notification opt-outs to a notification **before** it is
/// scheduled (docs/11 §opt-outs). Pure logic, no side effect — the Application
/// layer runs a candidate notification through [filtrer] and only schedules the
/// returned value.
///
/// Three opt-outs, in order of precedence:
/// 1. **Master switch** off (`notificationsGlobalesActives`) → suppressed.
/// 2. **Per-category mute** (`notificationsParCategorie[categorie] == false`)
///    → suppressed. Absent category defaults to on.
/// 3. **Do-not-disturb window** (`nePasDeranger*`): a notification whose time
///    falls inside the quiet hours is **deferred to the end of the window**
///    (nothing is lost, only delayed). The window may wrap past midnight
///    (e.g. 22:00 → 07:00).
class FiltreNotifications {
  final PreferencesUtilisateur _prefs;

  const FiltreNotifications(this._prefs);

  /// Returns the notification to schedule (possibly time-shifted out of the
  /// do-not-disturb window), or `null` when it must be suppressed entirely.
  NotificationLocale? filtrer(NotificationLocale notif) {
    if (!_prefs.notificationsGlobalesActives) return null;
    if (_prefs.notificationsParCategorie[notif.categorie] == false) return null;

    final report = _reporterHorsCreneau(notif.dateProgrammee);
    return report == null ? notif : notif.copierAvec(dateProgrammee: report);
  }

  /// If [quand] falls inside the do-not-disturb window, returns the deferred
  /// instant (the next occurrence of the window's end); otherwise `null`.
  DateTime? _reporterHorsCreneau(DateTime quand) {
    final debut = _minutes(_prefs.nePasDerangerDebut);
    final fin = _minutes(_prefs.nePasDerangerFin);
    // No window, or a zero-length window: nothing to defer.
    if (debut == null || fin == null || debut == fin) return null;

    final t = quand.hour * 60 + quand.minute;
    final chevauche = debut < fin
        // Same-day window [debut, fin).
        ? (t >= debut && t < fin)
        // Wrapping window: [debut, 24:00) ∪ [00:00, fin).
        : (t >= debut || t < fin);
    if (!chevauche) return null;

    final finHeure = fin ~/ 60;
    final finMinute = fin % 60;
    // Deferred to the window end. For a wrapping window entered in the evening
    // (t >= debut), the end is on the next day; otherwise it is the same day.
    final jour = DateTime(quand.year, quand.month, quand.day);
    final base = (debut > fin && t >= debut) ? jour.add(const Duration(days: 1)) : jour;
    return base.copyWith(hour: finHeure, minute: finMinute);
  }

  /// Parses an `HH:MM` string to minutes-since-midnight, or `null` if absent or
  /// malformed (a malformed bound is treated as "no window", never as a crash).
  static int? _minutes(String? hhmm) {
    if (hhmm == null) return null;
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) return null;
    return h * 60 + m;
  }
}
