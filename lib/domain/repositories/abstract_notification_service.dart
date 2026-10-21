import '../value_objects/notification_locale.dart';

/// Contract for scheduling local notifications (implemented with
/// `flutter_local_notifications` in the infrastructure layer).
abstract class AbstractNotificationService {
  /// Schedules [notif].
  Future<void> programmer(NotificationLocale notif);

  /// Cancels a scheduled notification by [id].
  Future<void> annuler(String id);

  /// Whether the OS currently allows notifications.
  Future<bool> sontAutorisees();
}
