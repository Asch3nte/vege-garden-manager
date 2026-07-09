import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/services/filtre_notifications.dart';
import 'package:pot_a_gerer/domain/value_objects/notification_locale.dart';

void main() {
  NotificationLocale notifA(DateTime quand, {String categorie = 'arrosage'}) =>
      NotificationLocale(
        id: 'n-1',
        titre: 'Arrosage',
        corps: 'corps',
        dateProgrammee: quand,
        categorie: categorie,
      );

  group('master switch', () {
    test('off → suppressed (null)', () {
      final filtre = FiltreNotifications(
          PreferencesUtilisateur(notificationsGlobalesActives: false));
      expect(filtre.filtrer(notifA(DateTime(2026, 6, 9, 8))), isNull);
    });

    test('on with no window → passes through unchanged', () {
      final filtre = FiltreNotifications(PreferencesUtilisateur());
      final n = notifA(DateTime(2026, 6, 9, 8));
      expect(filtre.filtrer(n), same(n));
    });
  });

  group('per-category mute', () {
    test('muted category → suppressed', () {
      final filtre = FiltreNotifications(PreferencesUtilisateur(
          notificationsParCategorie: const {'arrosage': false}));
      expect(filtre.filtrer(notifA(DateTime(2026, 6, 9, 8))), isNull);
    });

    test('a different muted category does not affect this one', () {
      final filtre = FiltreNotifications(PreferencesUtilisateur(
          notificationsParCategorie: const {'semis': false}));
      final n = notifA(DateTime(2026, 6, 9, 8));
      expect(filtre.filtrer(n), same(n));
    });

    test('absent category defaults to on', () {
      final filtre = FiltreNotifications(
          PreferencesUtilisateur(notificationsParCategorie: const {}));
      final n = notifA(DateTime(2026, 6, 9, 8));
      expect(filtre.filtrer(n), same(n));
    });
  });

  group('do-not-disturb window', () {
    test('outside a same-day window → unchanged', () {
      final filtre = FiltreNotifications(
          PreferencesUtilisateur().avecNePasDeranger('12:00', '14:00'));
      final n = notifA(DateTime(2026, 6, 9, 8));
      expect(filtre.filtrer(n), same(n));
    });

    test('inside a same-day window → deferred to window end (same day)', () {
      final filtre = FiltreNotifications(
          PreferencesUtilisateur().avecNePasDeranger('12:00', '14:00'));
      final out = filtre.filtrer(notifA(DateTime(2026, 6, 9, 13)));
      expect(out, isNotNull);
      expect(out!.dateProgrammee, DateTime(2026, 6, 9, 14, 0));
    });

    test('wrapping window, evening notif → deferred to next-day end', () {
      // Quiet 22:00 → 07:00. A 23:00 notif is deferred to 07:00 the next day.
      final filtre = FiltreNotifications(
          PreferencesUtilisateur().avecNePasDeranger('22:00', '07:00'));
      final out = filtre.filtrer(notifA(DateTime(2026, 6, 9, 23)));
      expect(out!.dateProgrammee, DateTime(2026, 6, 10, 7, 0));
    });

    test('wrapping window, early-morning notif → deferred to same-day end', () {
      final filtre = FiltreNotifications(
          PreferencesUtilisateur().avecNePasDeranger('22:00', '07:00'));
      final out = filtre.filtrer(notifA(DateTime(2026, 6, 9, 3)));
      expect(out!.dateProgrammee, DateTime(2026, 6, 9, 7, 0));
    });

    test('the default 08:00 watering notif is outside the 22:00→07:00 window', () {
      final filtre = FiltreNotifications(
          PreferencesUtilisateur().avecNePasDeranger('22:00', '07:00'));
      final n = notifA(DateTime(2026, 6, 9, 8));
      expect(filtre.filtrer(n), same(n));
    });

    test('window boundary is half-open: notif exactly at end is not in window',
        () {
      final filtre = FiltreNotifications(
          PreferencesUtilisateur().avecNePasDeranger('12:00', '14:00'));
      final n = notifA(DateTime(2026, 6, 9, 14));
      expect(filtre.filtrer(n), same(n));
    });

    test('notif exactly at window start is deferred', () {
      final filtre = FiltreNotifications(
          PreferencesUtilisateur().avecNePasDeranger('12:00', '14:00'));
      final out = filtre.filtrer(notifA(DateTime(2026, 6, 9, 12)));
      expect(out!.dateProgrammee, DateTime(2026, 6, 9, 14, 0));
    });
  });
}
