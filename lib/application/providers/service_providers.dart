import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod/riverpod.dart';

import '../../domain/repositories/abstract_geocodage_service.dart';
import '../../domain/repositories/abstract_geolocalisation_service.dart';
import '../../domain/repositories/abstract_info_application_service.dart';
import '../../domain/repositories/abstract_meteo_service.dart';
import '../../domain/repositories/abstract_notification_service.dart';
import '../../domain/repositories/abstract_reinitialisation_service.dart';
import '../../domain/repositories/abstract_sauvegarde_service.dart';
import '../../infrastructure/api/nominatim_client.dart';
import '../../infrastructure/api/open_meteo_client.dart';
import '../../infrastructure/repositories/meteo_service_impl.dart';
import '../../infrastructure/services/geocodage_service_impl.dart';
import '../../infrastructure/services/geolocalisation_service_impl.dart';
import '../../infrastructure/services/info_application_service_impl.dart';
import '../../infrastructure/services/notification_service_impl.dart';
import '../../infrastructure/services/reinitialisation_service_impl.dart';
import '../../infrastructure/services/sauvegarde_service_impl.dart';
import 'database_providers.dart';

/// Dependency-injection providers for the domain service interfaces.
///
/// Each exposes the **Domain abstraction**, backed by its infrastructure
/// implementation. Tests override these with mocks. `AbstractSyncService` is
/// intentionally absent (WiFi sync is deferred to V2).

/// Open-Meteo HTTP client (owns a default `http.Client`).
final openMeteoClientProvider = Provider<OpenMeteoClient>(
  (ref) => OpenMeteoClient(),
);

/// Nominatim HTTP client (owns a default `http.Client`).
final nominatimClientProvider = Provider<NominatimClient>(
  (ref) => NominatimClient(),
);

/// Reverse-geocoding service (Nominatim / OSM — ADR-0016).
final geocodageServiceProvider = Provider<AbstractGeocodageService>(
  (ref) => GeocodageServiceImpl(ref.watch(nominatimClientProvider)),
);

final meteoServiceProvider = Provider<AbstractMeteoService>(
  (ref) => MeteoServiceImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(openMeteoClientProvider),
  ),
);

final notificationServiceProvider = Provider<AbstractNotificationService>(
  (ref) => NotificationServiceImpl(FlutterLocalNotificationsPlugin()),
);

final geolocalisationServiceProvider =
    Provider<AbstractGeolocalisationService>(
  (ref) => GeolocalisationServiceImpl(),
);

final sauvegardeServiceProvider = Provider<AbstractSauvegardeService>(
  (ref) => SauvegardeServiceImpl(ref.watch(appDatabaseProvider)),
);

final reinitialisationServiceProvider =
    Provider<AbstractReinitialisationService>(
  (ref) => ReinitialisationServiceImpl(ref.watch(appDatabaseProvider)),
);

final infoApplicationServiceProvider =
    Provider<AbstractInfoApplicationService>(
  (ref) => InfoApplicationServiceImpl(),
);

/// One-shot read of the running app's version (docs/11 §7 — "À propos").
final versionAppliProvider = FutureProvider<String>(
  (ref) => ref.watch(infoApplicationServiceProvider).obtenirVersionAffichee(),
);
