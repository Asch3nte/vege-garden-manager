import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/equipement.dart';
import 'package:pot_a_gerer/domain/enums/etat_equipement.dart';
import 'package:pot_a_gerer/domain/enums/type_equipement.dart';

Equipement _equip({
  String id = 'e1',
  String nom = 'Oya 5L',
  String potagerId = 'pot1',
  String? parcelleId = 'par1',
  TypeEquipement type = TypeEquipement.oya,
}) =>
    Equipement(
      id: id,
      nom: nom,
      potagerId: potagerId,
      parcelleId: parcelleId,
      type: type,
      dateInstallation: DateTime(2026, 4, 1),
    );

void main() {
  group('Equipement — construction & defaults', () {
    test('condition is bon and it is in service by default', () {
      final e = _equip();
      expect(e.etat, EtatEquipement.bon);
      expect(e.estEnService, isTrue);
      expect(e.estTransverse, isFalse);
    });

    test('a null parcelle makes it transverse', () {
      expect(_equip(parcelleId: null).estTransverse, isTrue);
    });

    test('rejects empty id, nom or potagerId', () {
      expect(() => _equip(id: ''), throwsA(isA<AssertionError>()));
      expect(() => _equip(nom: ''), throwsA(isA<AssertionError>()));
      expect(() => _equip(potagerId: ''), throwsA(isA<AssertionError>()));
    });

    test('rejects a retirement date before installation', () {
      expect(
        () => Equipement(
          id: 'e1',
          nom: 'X',
          potagerId: 'pot1',
          type: TypeEquipement.oya,
          dateInstallation: DateTime(2026, 4, 1),
          dateRetrait: DateTime(2026, 3, 1),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Equipement — derived effect', () {
    test('effet() comes from the type', () {
      expect(_equip(type: TypeEquipement.oya).effet().modificateurBesoinEau, 0.4);
      expect(
        _equip(type: TypeEquipement.voileHivernage).effet().protectionGel,
        isTrue,
      );
    });
  });

  group('Equipement — lifecycle', () {
    test('condition can change', () {
      final e = _equip();
      e.changerEtat(EtatEquipement.aRemplacer);
      expect(e.etat, EtatEquipement.aRemplacer);
    });

    test('retirer records the date and ends service (kept for history)', () {
      final e = _equip();
      e.retirer(DateTime(2026, 10, 1));
      expect(e.estEnService, isFalse);
      expect(e.dateRetrait, DateTime(2026, 10, 1));
    });

    test('retirer rejects a date before installation', () {
      final e = _equip();
      expect(
        () => e.retirer(DateTime(2026, 3, 1)),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Equipement — identity', () {
    test('equality is by id', () {
      expect(_equip(id: 'a') == _equip(id: 'a'), isTrue);
      expect(_equip(id: 'a') == _equip(id: 'b'), isFalse);
    });
  });
}
