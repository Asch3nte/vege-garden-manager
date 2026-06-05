import '../enums/permission_localisation.dart';
import '../value_objects/localisation.dart';

/// Contract for reading the device location (implemented with `geolocator` in
/// the infrastructure layer).
///
/// Geolocation is **opt-out and disabled by default** (privacy by design): the
/// Application layer only calls this when the user explicitly enabled it. The
/// returned [Localisation] has its coordinates rounded to ~1 km
/// ([Localisation.gps]); no city name is attached.
///
/// See `docs/05-modele-de-domaine.md` §7 and `docs/11-parametres-et-opt-outs.md`.
abstract class AbstractGeolocalisationService {
  /// Whether the OS location service (GPS) is currently enabled.
  Future<bool> serviceActif();

  /// Current permission state, without prompting the user.
  Future<PermissionLocalisation> permission();

  /// Prompts the user for permission and returns the resulting state.
  Future<PermissionLocalisation> demanderPermission();

  /// The device's current position as a rounded [Localisation].
  ///
  /// Throws `GeolocalisationIndisponibleException` if the service is off,
  /// permission is not granted, or the query fails.
  Future<Localisation> positionActuelle();
}
