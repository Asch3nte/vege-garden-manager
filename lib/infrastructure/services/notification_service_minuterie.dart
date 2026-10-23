import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../domain/exceptions/notification_indisponible_exception.dart';
import '../../domain/repositories/abstract_notification_service.dart';
import '../../domain/value_objects/notification_locale.dart';
import 'notification_service_impl.dart';

/// [AbstractNotificationService] where the plugin cannot schedule (Linux): the
/// running app shows each notification once due.
///
/// Due times are checked against the wall clock every [periode], so a reminder
/// due while the machine slept shows on wake-up; none shows while the app is
/// closed.
class NotificationServiceMinuterie
    implements AbstractNotificationService, NotificationsAInitialiser {
  static const Duration periodeParDefaut = Duration(minutes: 1);

  final NotificationServiceImpl _base;
  final DateTime Function() _maintenant;
  final Duration _periode;
  final Map<String, NotificationLocale> _enAttente = {};
  Timer? _minuterie;

  NotificationServiceMinuterie(
    this._base, {
    DateTime Function()? maintenant,
    this._periode = periodeParDefaut,
  }) : _maintenant = maintenant ?? DateTime.now;

  @override
  Future<void> initialiser() => _base.initialiser();

  @override
  Future<void> programmer(NotificationLocale notif) async {
    if (!notif.dateProgrammee.isAfter(_maintenant())) {
      throw NotificationIndisponibleException(
          'Notification "${notif.id}" is due in the past.');
    }
    _enAttente[notif.id] = notif;
    _minuterie ??=
        Timer.periodic(_periode, (_) => unawaited(verifierEcheances()));
  }

  @override
  Future<void> annuler(String id) async {
    _enAttente.remove(id);
    _arreterSiVide();
    await _base.annuler(id);
  }

  @override
  Future<bool> sontAutorisees() => _base.sontAutorisees();

  /// Shows every pending notification now due.
  @visibleForTesting
  Future<void> verifierEcheances() async {
    final maintenant = _maintenant();
    final dues = [
      for (final n in _enAttente.values)
        if (!n.dateProgrammee.isAfter(maintenant)) n,
    ];
    for (final n in dues) {
      _enAttente.remove(n.id);
      try {
        await _base.afficher(n);
      } on NotificationIndisponibleException catch (e) {
        developer.log('Notification ${n.id} not shown',
            name: 'notifications', error: e);
      }
    }
    _arreterSiVide();
  }

  /// Stops checking; pending notifications are dropped.
  void fermer() {
    _enAttente.clear();
    _arreterSiVide();
  }

  void _arreterSiVide() {
    if (_enAttente.isNotEmpty) return;
    _minuterie?.cancel();
    _minuterie = null;
  }
}
