import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/type_equipement.dart';
import 'package:pot_a_gerer/domain/value_objects/effet_equipement.dart';

void main() {
  group('EffetEquipement — neutre & defaults', () {
    test('neutre modifies nothing and protects nothing', () {
      const e = EffetEquipement.neutre;
      expect(e.modificateurBesoinEau, 1.0);
      expect(e.modificateurEnsoleillement, 1.0);
      expect(e.modificateurTemperatureC, 0.0);
      expect(e.protectionGel, isFalse);
      expect(e.protectionInsectes, isFalse);
      expect(e.protectionOiseaux, isFalse);
      expect(e.supportPhysique, isFalse);
      expect(e.favoriseBiodiversite, isFalse);
      expect(e.dureeEfficaciteJours, isNull);
    });

    test('default constructor equals neutre', () {
      expect(EffetEquipement(), EffetEquipement.neutre);
    });
  });

  group('EffetEquipement — invariants', () {
    test('rejects a non-positive water modifier', () {
      expect(
        () => EffetEquipement(modificateurBesoinEau: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects a non-positive sunlight modifier', () {
      expect(
        () => EffetEquipement(modificateurEnsoleillement: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects a non-positive duration', () {
      expect(
        () => EffetEquipement(dureeEfficaciteJours: 0),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('EffetEquipement — pourType', () {
    test('oya strongly reduces the water need', () {
      expect(
        EffetEquipement.pourType(TypeEquipement.oya).modificateurBesoinEau,
        0.4,
      );
    });

    test('voile d\'hivernage warms and protects from frost', () {
      final e = EffetEquipement.pourType(TypeEquipement.voileHivernage);
      expect(e.modificateurTemperatureC, 3);
      expect(e.protectionGel, isTrue);
    });

    test('tuteur provides physical support', () {
      expect(
        EffetEquipement.pourType(TypeEquipement.tuteur).supportPhysique,
        isTrue,
      );
    });

    test('filet anti-insecte protects from insects', () {
      expect(
        EffetEquipement.pourType(TypeEquipement.filetAntiInsecte)
            .protectionInsectes,
        isTrue,
      );
    });

    test('hotel a insectes favours biodiversity', () {
      expect(
        EffetEquipement.pourType(TypeEquipement.hotelInsectes)
            .favoriseBiodiversite,
        isTrue,
      );
    });

    test('autre has no effect', () {
      expect(EffetEquipement.pourType(TypeEquipement.autre),
          EffetEquipement.neutre);
    });

    test('every type maps to an effect (no missing case)', () {
      for (final type in TypeEquipement.values) {
        expect(EffetEquipement.pourType(type), isA<EffetEquipement>());
      }
    });
  });

  group('EffetEquipement — equality by value', () {
    test('same modifiers are equal and share a hashCode', () {
      final a = EffetEquipement(modificateurTemperatureC: 3, protectionGel: true);
      final b = EffetEquipement(modificateurTemperatureC: 3, protectionGel: true);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differing on a field breaks equality', () {
      expect(
        EffetEquipement(protectionGel: true) ==
            EffetEquipement(protectionGel: false),
        isFalse,
      );
    });
  });
}
