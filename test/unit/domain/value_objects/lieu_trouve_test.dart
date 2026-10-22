import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/exceptions/invariant_domaine_exception.dart';
import 'package:pot_a_gerer/domain/value_objects/lieu_trouve.dart';

void main() {
  test('exposes its name, context and coordinates', () {
    final lieu = LieuTrouve(
      nom: 'Uccle',
      region: 'Bruxelles-Capitale',
      pays: 'Belgique',
      latitude: 50.80,
      longitude: 4.33,
    );
    expect(lieu.nom, 'Uccle');
    expect(lieu.region, 'Bruxelles-Capitale');
    expect(lieu.pays, 'Belgique');
    expect(lieu.latitude, 50.80);
    expect(lieu.longitude, 4.33);
  });

  test('blank region and country become null', () {
    final lieu = LieuTrouve(
        nom: 'X', region: ' ', pays: '', latitude: 0, longitude: 0);
    expect(lieu.region, isNull);
    expect(lieu.pays, isNull);
  });

  test('rejects an empty name', () {
    expect(() => LieuTrouve(nom: '  ', latitude: 0, longitude: 0),
        throwsA(isA<InvariantDomaineException>()));
  });

  test('rejects out-of-range coordinates', () {
    expect(() => LieuTrouve(nom: 'X', latitude: 91, longitude: 0),
        throwsA(isA<InvariantDomaineException>()));
    expect(() => LieuTrouve(nom: 'X', latitude: 0, longitude: -181),
        throwsA(isA<InvariantDomaineException>()));
  });

  test('equal when all fields match', () {
    LieuTrouve a() =>
        LieuTrouve(nom: 'A', pays: 'B', latitude: 1, longitude: 2);
    expect(a(), a());
    expect(a().hashCode, a().hashCode);
  });
}
