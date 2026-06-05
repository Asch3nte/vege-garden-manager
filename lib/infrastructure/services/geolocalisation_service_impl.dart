import 'package:geolocator/geolocator.dart';

import '../../domain/enums/permission_localisation.dart';
import '../../domain/exceptions/geolocalisation_indisponible_exception.dart';
import '../../domain/repositories/abstract_geolocalisation_service.dart';
import '../../domain/value_objects/localisation.dart';

/// `geolocator`-backed implementation of [AbstractGeolocalisationService].
///
/// The [GeolocatorPlatform] is injected (default [GeolocatorPlatform.instance])
/// so it can be mocked in tests. [positionActuelle] never prompts the user: it
/// requires the service to be on and permission already granted, and the
/// Application layer is responsible for calling [demanderPermission] first.
/// Coordinates are rounded to ~1 km by [Localisation.gps] (privacy by design).
class GeolocalisationServiceImpl implements AbstractGeolocalisationService {
  final GeolocatorPlatform _geolocator;

  GeolocalisationServiceImpl({GeolocatorPlatform? geolocator})
      : _geolocator = geolocator ?? GeolocatorPlatform.instance;

  @override
  Future<bool> serviceActif() => _geolocator.isLocationServiceEnabled();

  @override
  Future<PermissionLocalisation> permission() async =>
      _versPermission(await _geolocator.checkPermission());

  @override
  Future<PermissionLocalisation> demanderPermission() async =>
      _versPermission(await _geolocator.requestPermission());

  @override
  Future<Localisation> positionActuelle() async {
    if (!await _geolocator.isLocationServiceEnabled()) {
      throw GeolocalisationIndisponibleException(
        'Location service is disabled on the device.',
      );
    }
    final permission = _versPermission(await _geolocator.checkPermission());
    if (permission != PermissionLocalisation.accordee) {
      throw GeolocalisationIndisponibleException(
        'Location permission not granted (state: ${permission.name}).',
      );
    }
    try {
      final position = await _geolocator.getCurrentPosition();
      return Localisation.gps(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      throw GeolocalisationIndisponibleException(
        'Failed to read the device position.',
        cause: e,
      );
    }
  }

  /// Maps the plugin's [LocationPermission] to the domain enum.
  PermissionLocalisation _versPermission(LocationPermission p) {
    return switch (p) {
      LocationPermission.always ||
      LocationPermission.whileInUse =>
        PermissionLocalisation.accordee,
      LocationPermission.denied => PermissionLocalisation.refusee,
      LocationPermission.deniedForever =>
        PermissionLocalisation.refuseeDefinitivement,
      LocationPermission.unableToDetermine =>
        PermissionLocalisation.indeterminee,
    };
  }
}
