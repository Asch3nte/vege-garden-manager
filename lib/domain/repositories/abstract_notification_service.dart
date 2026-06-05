import '../value_objects/notification_locale.dart';

/// Contract for scheduling local notifications (implemented with
/// `flutter_local_notifications` in the infrastructure layer).
///
/// See `docs/05-modele-de-domaine.md` §7.
abstract class AbstractNotificationService {
  /// Schedules [notif].
  Future<void> programmer(NotificationLocale notif);

  /// Cancels a scheduled notification by [id].
  Future<void> annuler(String id);

  /// Whether the OS currently allows notifications.
  Future<bool> sontAutorisees();
}
