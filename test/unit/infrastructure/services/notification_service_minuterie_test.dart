import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/domain/exceptions/notification_indisponible_exception.dart';
import 'package:pot_a_gerer/domain/value_objects/notification_locale.dart';
import 'package:pot_a_gerer/infrastructure/services/notification_service_impl.dart';
import 'package:pot_a_gerer/infrastructure/services/notification_service_minuterie.dart';

class MockBase extends Mock implements NotificationServiceImpl {}

void main() {
  final echeance = DateTime(2026, 6, 10, 8);
  late MockBase base;
  late DateTime maintenant;
  late NotificationServiceMinuterie service;

  NotificationLocale notif([String id = 'n-1']) => NotificationLocale(
        id: id,
        titre: 'Arrosage',
        corps: 'Vos tomates ont besoin d\'eau',
        dateProgrammee: echeance,
        categorie: 'arrosage',
        cibleRoute: '/calendrier',
      );

  setUpAll(() => registerFallbackValue(notif()));

  setUp(() {
    base = MockBase();
    when(() => base.afficher(any())).thenAnswer((_) async {});
    when(() => base.annuler(any())).thenAnswer((_) async {});
    maintenant = echeance.subtract(const Duration(hours: 12));
    service = NotificationServiceMinuterie(base, maintenant: () => maintenant);
    addTearDown(service.fermer);
  });

  test('shows a notification once due, then never again', () async {
    await service.programmer(notif());

    await service.verifierEcheances();
    verifyNever(() => base.afficher(any()));

    // Wall clock: a machine that slept past the due time shows it on wake-up.
    maintenant = echeance.add(const Duration(hours: 3));
    await service.verifierEcheances();
    await service.verifierEcheances();

    verify(() => base.afficher(any(that: isA<NotificationLocale>()
        .having((n) => n.id, 'id', 'n-1')))).called(1);
  });

  test('a cancelled notification never shows', () async {
    await service.programmer(notif());
    await service.annuler('n-1');
    maintenant = echeance;

    await service.verifierEcheances();

    verifyNever(() => base.afficher(any()));
    verify(() => base.annuler('n-1')).called(1);
  });

  test('a past time is refused like the platform scheduler does', () async {
    maintenant = echeance;

    await expectLater(service.programmer(notif()),
        throwsA(isA<NotificationIndisponibleException>()));
  });

  test('a failed display is logged, the others still show', () async {
    when(() => base.afficher(any(
            that: isA<NotificationLocale>().having((n) => n.id, 'id', 'n-1'))))
        .thenThrow(NotificationIndisponibleException('dbus absent'));
    await service.programmer(notif('n-1'));
    await service.programmer(notif('n-2'));
    maintenant = echeance;

    await service.verifierEcheances();

    verify(() => base.afficher(any())).called(2);
  });
}
