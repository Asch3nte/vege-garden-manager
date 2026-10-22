import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/domain/value_objects/lieu_trouve.dart';
import 'package:pot_a_gerer/infrastructure/api/nominatim_client.dart';
import 'package:pot_a_gerer/infrastructure/services/geocodage_service_impl.dart';

class _MockClient extends Mock implements NominatimClient {}

void main() {
  late _MockClient client;
  late GeocodageServiceImpl service;
  final lieu = LieuTrouve(nom: 'Namur', latitude: 50.47, longitude: 4.87);

  setUp(() {
    client = _MockClient();
    service = GeocodageServiceImpl(client);
  });

  test('delegates the place search to the client', () async {
    when(() => client.rechercherLieux('Namur')).thenAnswer((_) async => [lieu]);
    expect(await service.rechercherLieux('Namur'), [lieu]);
  });

  test('delegates the place naming to the client', () async {
    when(() => client.identifierLieu(50.47, 4.87))
        .thenAnswer((_) async => lieu);
    expect(await service.identifierLieu(50.47, 4.87), lieu);
  });
}
