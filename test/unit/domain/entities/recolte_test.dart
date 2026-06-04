import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/recolte.dart';
import 'package:pot_a_gerer/domain/enums/destination_recolte.dart';
import 'package:pot_a_gerer/domain/enums/qualite_recolte.dart';
import 'package:pot_a_gerer/domain/enums/unite_quantite.dart';
import 'package:pot_a_gerer/domain/value_objects/quantite.dart';

Recolte _recolte({
  String id = 'r1',
  String plantationId = 'p1',
  DestinationRecolte destination = DestinationRecolte.consommationFraiche,
  QualiteRecolte? qualite,
}) =>
    Recolte(
      id: id,
      plantationId: plantationId,
      date: DateTime(2026, 7, 15),
      quantite: const Quantite(2, UniteQuantite.kg),
      destination: destination,
      qualite: qualite,
    );

void main() {
  group('Recolte — construction', () {
    test('exposes its fields with sensible defaults', () {
      final r = _recolte();
      expect(r.id, 'r1');
      expect(r.plantationId, 'p1');
      expect(r.date, DateTime(2026, 7, 15));
      expect(r.quantite, const Quantite(2, UniteQuantite.kg));
      expect(r.destination, DestinationRecolte.consommationFraiche);
      expect(r.qualite, isNull);
      expect(r.notes, isNull);
    });

    test('rejects an empty id', () {
      expect(() => _recolte(id: ''), throwsA(isA<AssertionError>()));
    });
  });

  group('Recolte — a posteriori updates', () {
    test('quality can be assessed after creation', () {
      final r = _recolte();
      expect(r.qualite, isNull);
      r.definirQualite(QualiteRecolte.bonne);
      expect(r.qualite, QualiteRecolte.bonne);
    });

    test('notes can be set and cleared', () {
      final r = _recolte();
      r.modifierNotes('belle récolte');
      expect(r.notes, 'belle récolte');
      r.modifierNotes(null);
      expect(r.notes, isNull);
    });
  });

  group('Recolte — identity', () {
    test('two harvests with the same id are equal (identity, not value)', () {
      final a = _recolte(destination: DestinationRecolte.don);
      final b = _recolte(destination: DestinationRecolte.compost);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different ids are not equal', () {
      expect(_recolte(id: 'r1') == _recolte(id: 'r2'), isFalse);
    });
  });
}
