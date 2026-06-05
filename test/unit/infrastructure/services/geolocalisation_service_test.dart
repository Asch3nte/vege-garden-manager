import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/domain/enums/permission_localisation.dart';
import 'package:pot_a_gerer/domain/enums/source_localisation.dart';
import 'package:pot_a_gerer/domain/exceptions/geolocalisation_indisponible_exception.dart';
import 'package:pot_a_gerer/infrastructure/services/geolocalisation_service_impl.dart';

class MockGeolocatorPlatform extends Mock implements GeolocatorPlatform {}

Position positionLyon() => Position(
      latitude: 45.7589,
      longitude: 4.8512,
      timestamp: DateTime.utc(2026, 6, 5),
      accuracy: 5,
      altitude: 170,
      altitudeAccuracy: 1,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

void main() {
  late MockGeolocatorPlatform geolocator;
  late GeolocalisationServiceImpl service;

  setUp(() {
    geolocator = MockGeolocatorPlatform();
    service = GeolocalisationServiceImpl(geolocator: geolocator);
  });

  group('permission mapping', () {
    test('maps whileInUse/always to accordee', () async {
      when(() => geolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);
      expect(await service.permission(), PermissionLocalisation.accordee);
    });

    test('maps deniedForever to refuseeDefinitivement', () async {
      when(() => geolocator.requestPermission())
          .thenAnswer((_) async => LocationPermission.deniedForever);
      expect(await service.demanderPermission(),
          PermissionLocalisation.refuseeDefinitivement);
    });
  });

  group('positionActuelle', () {
    test('returns a rounded GPS Localisation when allowed', () async {
      when(() => geolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(() => geolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);
      when(() => geolocator.getCurrentPosition())
          .thenAnswer((_) async => positionLyon());

      final loc = await service.positionActuelle();

      expect(loc.source, SourceLocalisation.gps);
      // Rounded to ~1 km (2 decimals) by Localisation.gps.
      expect(loc.latitude, 45.76);
      expect(loc.longitude, 4.85);
      expect(loc.ville, isNull);
    });

    test('throws when the location service is off', () async {
      when(() => geolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => false);

      expect(
        () => service.positionActuelle(),
        throwsA(isA<GeolocalisationIndisponibleException>()),
      );
      verifyNever(() => geolocator.getCurrentPosition());
    });

    test('throws when permission is not granted', () async {
      when(() => geolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(() => geolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.denied);

      expect(
        () => service.positionActuelle(),
        throwsA(isA<GeolocalisationIndisponibleException>()),
      );
      verifyNever(() => geolocator.getCurrentPosition());
    });

    test('wraps a platform read error', () async {
      when(() => geolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(() => geolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.always);
      when(() => geolocator.getCurrentPosition())
          .thenThrow(Exception('GPS failure'));

      await expectLater(
        service.positionActuelle(),
        throwsA(isA<GeolocalisationIndisponibleException>()),
      );
    });
  });
}
