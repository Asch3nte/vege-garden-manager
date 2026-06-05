import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/type_releve_meteo.dart';
import 'package:pot_a_gerer/domain/value_objects/appareil_decouvert.dart';
import 'package:pot_a_gerer/domain/value_objects/donnees_meteo.dart';
import 'package:pot_a_gerer/domain/value_objects/notification_locale.dart';
import 'package:pot_a_gerer/domain/value_objects/prevision_meteo.dart';

final _d = DateTime(2026, 6, 15);

void main() {
  group('DonneesMeteo', () {
    test('exposes its fields and compares by value', () {
      final a = DonneesMeteo(
        date: _d,
        tempMin: 8,
        tempMax: 22,
        tempMoyenne: 15,
        precipitationsMm: 2,
        ventVitesseMax: 30,
        risqueGel: false,
      );
      final b = DonneesMeteo(
        date: _d,
        tempMin: 8,
        tempMax: 22,
        tempMoyenne: 15,
        precipitationsMm: 2,
        ventVitesseMax: 30,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.tempMax, 22);
    });

    test('rejects tempMin > tempMax', () {
      expect(
        () => DonneesMeteo(
          date: _d,
          tempMin: 25,
          tempMax: 10,
          tempMoyenne: 15,
          precipitationsMm: 0,
          ventVitesseMax: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('PrevisionMeteo', () {
    test('rejects a rain probability out of 0..1', () {
      expect(
        () => PrevisionMeteo(
          date: _d,
          tempMin: 5,
          tempMax: 10,
          precipitationsMm: 0,
          probabilitePluie: 1.5,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('defaults type to prevu', () {
      final p = PrevisionMeteo(
        date: _d,
        tempMin: 5,
        tempMax: 10,
        precipitationsMm: 0,
      );
      expect(p.type, TypeReleveMeteo.prevu);
    });
  });

  group('NotificationLocale', () {
    test('rejects empty id/titre/categorie', () {
      expect(
        () => NotificationLocale(
          id: '',
          titre: 'X',
          corps: 'Y',
          dateProgrammee: _d,
          categorie: 'arrosage',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('keeps its fields', () {
      final n = NotificationLocale(
        id: 'n1',
        titre: 'Arrosage',
        corps: 'Vos tomates ont soif',
        dateProgrammee: _d,
        categorie: 'arrosage',
        cibleRoute: '/potager/par1',
      );
      expect(n.categorie, 'arrosage');
      expect(n.cibleRoute, '/potager/par1');
    });
  });

  group('AppareilDecouvert', () {
    test('rejects a non-positive port', () {
      expect(
        () => AppareilDecouvert(
          id: 'a',
          nom: 'PC',
          adresseIp: '192.168.1.10',
          port: 0,
          derniereVue: _d,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('compares by value', () {
      final a = AppareilDecouvert(
        id: 'a',
        nom: 'PC',
        adresseIp: '192.168.1.10',
        port: 8765,
        derniereVue: DateTime(2026, 6, 1),
      );
      final b = AppareilDecouvert(
        id: 'a',
        nom: 'PC',
        adresseIp: '192.168.1.10',
        port: 8765,
        derniereVue: DateTime(2026, 6, 1),
      );
      expect(a, b);
    });
  });
}
