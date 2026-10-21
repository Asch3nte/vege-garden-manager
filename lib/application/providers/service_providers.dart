import 'package:riverpod/riverpod.dart';

import '../../domain/repositories/abstract_geocodage_service.dart';
import '../../domain/repositories/abstract_geolocalisation_service.dart';
import '../../domain/repositories/abstract_info_application_service.dart';
import '../../domain/repositories/abstract_meteo_service.dart';
import '../../domain/repositories/abstract_notification_service.dart';
import '../../domain/repositories/abstract_ouverture_lien_service.dart';
import '../../domain/repositories/abstract_reinitialisation_service.dart';
import '../../domain/repositories/abstract_sauvegarde_service.dart';
import '../../domain/repositories/abstract_statistiques_donnees_service.dart';
import '../../domain/repositories/abstract_textes_notifications.dart';
import 'non_branche.dart';

/// Domain service ports. Their implementations are bound by the composition
/// root; tests override them with doubles. `AbstractSyncService` is
/// intentionally absent (WiFi sync is deferred to V2).

/// Reverse-geocoding service (Nominatim / OSM).
final geocodageServiceProvider = Provider<AbstractGeocodageService>(
  (ref) => nonBranche('geocodageServiceProvider'),
);

final meteoServiceProvider = Provider<AbstractMeteoService>(
  (ref) => nonBranche('meteoServiceProvider'),
);

final notificationServiceProvider = Provider<AbstractNotificationService>(
  (ref) => nonBranche('notificationServiceProvider'),
);

/// Notification texts in the user language.
final textesNotificationsProvider = Provider<AbstractTextesNotifications>(
  (ref) => nonBranche('textesNotificationsProvider'),
);

final geolocalisationServiceProvider =
    Provider<AbstractGeolocalisationService>(
  (ref) => nonBranche('geolocalisationServiceProvider'),
);

final sauvegardeServiceProvider = Provider<AbstractSauvegardeService>(
  (ref) => nonBranche('sauvegardeServiceProvider'),
);

final reinitialisationServiceProvider =
    Provider<AbstractReinitialisationService>(
  (ref) => nonBranche('reinitialisationServiceProvider'),
);

/// Local-storage statistics for the data-transparency panel.
final statistiquesDonneesServiceProvider =
    Provider<AbstractStatistiquesDonneesService>(
  (ref) => nonBranche('statistiquesDonneesServiceProvider'),
);

final infoApplicationServiceProvider =
    Provider<AbstractInfoApplicationService>(
  (ref) => nonBranche('infoApplicationServiceProvider'),
);

/// One-shot read of the running app's version ("À propos").
final versionAppliProvider = FutureProvider<String>(
  (ref) => ref.watch(infoApplicationServiceProvider).obtenirVersionAffichee(),
);

final ouvertureLienServiceProvider = Provider<AbstractOuvertureLienService>(
  (ref) => nonBranche('ouvertureLienServiceProvider'),
);
