import 'package:pot_a_gerer/app/composition.dart';
import 'package:pot_a_gerer/application/providers/service_providers.dart';
import 'package:pot_a_gerer/domain/enums/permission_localisation.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_geolocalisation_service.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_info_application_service.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_notification_service.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_ouverture_lien_service.dart';
import 'package:pot_a_gerer/domain/exceptions/geolocalisation_indisponible_exception.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/domain/value_objects/notification_locale.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/presentation/services/gestionnaire_sauvegarde_fichier.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/misc.dart';

class MockNotificationService extends Mock
    implements AbstractNotificationService {}

class MockGeolocalisationService extends Mock
    implements AbstractGeolocalisationService {}

class MockGestionnaireSauvegardeFichier extends Mock
    implements AbstractGestionnaireSauvegardeFichier {}

class MockInfoApplicationService extends Mock
    implements AbstractInfoApplicationService {}

class MockOuvertureLienService extends Mock
    implements AbstractOuvertureLienService {}

class _FallbackNotification extends Fake implements NotificationLocale {}

/// Notification mock that keeps the scheduled notifications readable.
class NotificationsDeTest {
  /// The mock to inject.
  final MockNotificationService service = MockNotificationService();

  NotificationsDeTest() {
    registerFallbackValue(_FallbackNotification());
    when(() => service.programmer(any())).thenAnswer((i) async {
      final notif = i.positionalArguments.first as NotificationLocale;
      _programmees.removeWhere((n) => n.id == notif.id);
      _programmees.add(notif);
    });
    when(() => service.annuler(any())).thenAnswer((i) async {
      final id = i.positionalArguments.first as String;
      _programmees.removeWhere((n) => n.id == id);
    });
    when(() => service.sontAutorisees()).thenAnswer((_) async => true);
  }

  final List<NotificationLocale> _programmees = [];

  /// Currently scheduled notifications.
  List<NotificationLocale> get programmees => List.unmodifiable(_programmees);
}

/// Geolocation mock with a fixed position, or a refusal.
class GeolocalisationDeTest {
  /// The mock to inject.
  final MockGeolocalisationService service = MockGeolocalisationService();

  /// Grants permission and returns [position].
  GeolocalisationDeTest(Localisation position) {
    when(() => service.serviceActif()).thenAnswer((_) async => true);
    when(
      () => service.permission(),
    ).thenAnswer((_) async => PermissionLocalisation.accordee);
    when(
      () => service.demanderPermission(),
    ).thenAnswer((_) async => PermissionLocalisation.accordee);
    when(() => service.positionActuelle()).thenAnswer((_) async => position);
  }

  /// Denies permission; reading the position fails.
  GeolocalisationDeTest.refus() {
    when(() => service.serviceActif()).thenAnswer((_) async => false);
    when(
      () => service.permission(),
    ).thenAnswer((_) async => PermissionLocalisation.refusee);
    when(
      () => service.demanderPermission(),
    ).thenAnswer((_) async => PermissionLocalisation.refusee);
    when(
      () => service.positionActuelle(),
    ).thenThrow(GeolocalisationIndisponibleException('Permission denied.'));
  }
}

/// File manager mock: canned read and recorded shares.
class FichiersDeTest {
  /// The mock to inject.
  final MockGestionnaireSauvegardeFichier service =
      MockGestionnaireSauvegardeFichier();

  /// Content returned by `choisirEtLire`; `null` simulates a cancel.
  String? aLire;

  /// Content of the last shared document.
  String? dernierPartage;

  /// Name of the last shared document.
  String? dernierNomFichier;

  FichiersDeTest({this.aLire}) {
    when(() => service.partager(any(), any())).thenAnswer((i) async {
      dernierPartage = i.positionalArguments[0] as String;
      dernierNomFichier = i.positionalArguments[1] as String;
    });
    when(() => service.choisirEtLire()).thenAnswer((_) async => aLire);
  }
}

final Set<Object> _natifs = {
  notificationServiceProvider,
  geolocalisationServiceProvider,
  gestionnaireSauvegardeFichierProvider,
  infoApplicationServiceProvider,
  ouvertureLienServiceProvider,
};

/// Overrides wiring the real implementations on [base] and replacing every
/// platform-bound service with a mock.
List<Override> surchargesDeTest(
  AppDatabase base, {
  NotificationsDeTest? notifications,
  GeolocalisationDeTest? geoloc,
  FichiersDeTest? fichiers,
}) {
  registerFallbackValue(Uri());
  final info = MockInfoApplicationService();
  when(
    () => info.obtenirVersionAffichee(),
  ).thenAnswer((_) async => '0.0.0-test');
  final lien = MockOuvertureLienService();
  when(() => lien.ouvrir(any())).thenAnswer((_) async => true);
  return [
    ...Composition.surcharges(base).where((o) => !_natifs.contains(o.origin)),
    notificationServiceProvider.overrideWithValue(
      (notifications ?? NotificationsDeTest()).service,
    ),
    geolocalisationServiceProvider.overrideWithValue(
      (geoloc ?? GeolocalisationDeTest.refus()).service,
    ),
    gestionnaireSauvegardeFichierProvider.overrideWithValue(
      (fichiers ?? FichiersDeTest()).service,
    ),
    infoApplicationServiceProvider.overrideWithValue(info),
    ouvertureLienServiceProvider.overrideWithValue(lien),
  ];
}
