import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/domain/exceptions/notification_indisponible_exception.dart';
import 'package:pot_a_gerer/domain/value_objects/notification_locale.dart';
import 'package:pot_a_gerer/infrastructure/services/notification_service_impl.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);
    registerFallbackValue(tz.TZDateTime.now(tz.UTC));
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
  });

  late MockPlugin plugin;
  late NotificationServiceImpl service;

  setUp(() {
    plugin = MockPlugin();
    service = NotificationServiceImpl(plugin);
  });

  NotificationLocale notif() => NotificationLocale(
        id: 'a3f1c2d4-0000-4000-8000-000000000001',
        titre: 'Arrosage',
        corps: 'Vos tomates ont besoin d\'eau',
        dateProgrammee: DateTime.utc(2026, 6, 10, 8),
        categorie: 'arrosage',
        cibleRoute: '/plantation/42',
      );

  test('intIdPour is deterministic and a non-negative 31-bit int', () {
    final id = NotificationServiceImpl.intIdPour('some-uuid');
    expect(id, NotificationServiceImpl.intIdPour('some-uuid'));
    expect(id, isNonNegative);
    expect(id, lessThanOrEqualTo(0x7fffffff));
    expect(id, isNot(NotificationServiceImpl.intIdPour('other-uuid')));
  });

  test('programmer schedules with the mapped int id, title, body and payload',
      () async {
    when(() => plugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          payload: any(named: 'payload'),
        )).thenAnswer((_) async {});

    final n = notif();
    await service.programmer(n);

    verify(() => plugin.zonedSchedule(
          id: NotificationServiceImpl.intIdPour(n.id),
          title: 'Arrosage',
          body: n.corps,
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: '/plantation/42',
        )).called(1);
  });

  test('annuler cancels the mapped int id', () async {
    when(() => plugin.cancel(id: any(named: 'id')))
        .thenAnswer((_) async {});

    await service.annuler('a3f1c2d4-0000-4000-8000-000000000001');

    verify(() => plugin.cancel(
        id: NotificationServiceImpl.intIdPour(
            'a3f1c2d4-0000-4000-8000-000000000001'))).called(1);
  });

  test('programmer wraps a plugin error into a typed exception', () async {
    when(() => plugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          payload: any(named: 'payload'),
        )).thenThrow(Exception('platform boom'));

    await expectLater(
      service.programmer(notif()),
      throwsA(isA<NotificationIndisponibleException>()),
    );
  });
}
