import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/exceptions/notification_indisponible_exception.dart';
import '../../domain/repositories/abstract_notification_service.dart';
import '../../domain/value_objects/notification_locale.dart';

/// `flutter_local_notifications`-backed implementation of
/// [AbstractNotificationService].
///
/// All notifications are **local** (no server, privacy by design) and scheduled
/// in the device's local timezone via `zonedSchedule`. This service is a thin
/// wrapper: the **opt-out logic** (per-category mute, do-not-disturb window —
/// see `docs/11-parametres-et-opt-outs.md`) lives in the Application layer,
/// which decides whether to call [programmer] at all.
///
/// Domain notification ids are UUID [String]s, whereas the plugin keys
/// notifications by `int`; the two are bridged by a stable hash ([intIdPour]),
/// so [annuler] can target the same notification [programmer] created.
///
/// Scheduling uses [AndroidScheduleMode.inexactAllowWhileIdle]: it does not
/// require the `SCHEDULE_EXACT_ALARM` permission (gardening reminders tolerate
/// approximate timing).
///
/// Before first use the app must call [initialiser] (timezone database + plugin
/// init); the device's local zone should be set at bootstrap (`tz.setLocalLocation`).
class NotificationServiceImpl implements AbstractNotificationService {
  /// Notification channel used for every reminder (Android requirement).
  static const _channelId = 'potager_rappels';
  static const _channelName = 'Rappels';
  static const _channelDescription = 'Rappels et alertes du potager';

  final FlutterLocalNotificationsPlugin _plugin;

  NotificationServiceImpl(this._plugin);

  /// Initialises the timezone database and the platform plugin. Idempotent on
  /// the plugin side; call once at startup.
  Future<void> initialiser() async {
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
        macOS: DarwinInitializationSettings(),
        linux: LinuxInitializationSettings(defaultActionName: 'Ouvrir'),
      ),
    );
  }

  @override
  Future<void> programmer(NotificationLocale notif) async {
    try {
      await _plugin.zonedSchedule(
        id: intIdPour(notif.id),
        title: notif.titre,
        body: notif.corps,
        scheduledDate: tz.TZDateTime.from(notif.dateProgrammee, tz.local),
        notificationDetails: _detailsPour(notif.categorie),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: notif.cibleRoute,
      );
    } catch (e) {
      throw NotificationIndisponibleException(
        'Failed to schedule notification "${notif.id}".',
        cause: e,
      );
    }
  }

  @override
  Future<void> annuler(String id) async {
    try {
      await _plugin.cancel(id: intIdPour(id));
    } catch (e) {
      throw NotificationIndisponibleException(
        'Failed to cancel notification "$id".',
        cause: e,
      );
    }
  }

  @override
  Future<bool> sontAutorisees() async {
    // Best-effort cross-platform check. Android exposes an explicit toggle;
    // iOS/macOS report per-option permissions; desktop Linux has no gate.
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.areNotificationsEnabled() ?? false;

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final options = await ios.checkPermissions();
      return options?.isEnabled ?? false;
    }

    final macos = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    if (macos != null) {
      final options = await macos.checkPermissions();
      return options?.isEnabled ?? false;
    }

    return true;
  }

  /// Notification details, tagging the [categorie] for grouping/opt-out.
  NotificationDetails _detailsPour(String categorie) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        tag: categorie,
      ),
      iOS: DarwinNotificationDetails(threadIdentifier: categorie),
      macOS: DarwinNotificationDetails(threadIdentifier: categorie),
      linux: const LinuxNotificationDetails(),
    );
  }

  /// Maps a UUID [String] id to a stable non-negative 31-bit `int` for the
  /// plugin, using FNV-1a. Deterministic, so [annuler] targets the right
  /// notification.
  static int intIdPour(String id) {
    var hash = 0x811c9dc5;
    for (final unit in id.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
