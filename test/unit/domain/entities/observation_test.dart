import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/observation.dart';
import 'package:pot_a_gerer/domain/enums/cible_observation.dart';
import 'package:pot_a_gerer/domain/enums/gravite_observation.dart';
import 'package:pot_a_gerer/domain/enums/type_observation.dart';

Observation _obs({
  String id = 'o1',
  String cibleId = 'pl1',
  String titre = 'Taches sur feuilles',
  bool resolu = false,
  DateTime? dateResolution,
}) =>
    Observation(
      id: id,
      cible: CibleObservation.plantation,
      cibleId: cibleId,
      date: DateTime(2026, 6, 10),
      type: TypeObservation.maladie,
      titre: titre,
      resolu: resolu,
      dateResolution: dateResolution,
    );

void main() {
  group('Observation — construction & defaults', () {
    test('targets a polymorphic entity, unresolved, info by default', () {
      final o = _obs();
      expect(o.cible, CibleObservation.plantation);
      expect(o.cibleId, 'pl1');
      expect(o.type, TypeObservation.maladie);
      expect(o.gravite, GraviteObservation.info);
      expect(o.resolu, isFalse);
      expect(o.dateResolution, isNull);
    });

    test('rejects empty id, cibleId or titre', () {
      expect(() => _obs(id: ''), throwsA(isA<AssertionError>()));
      expect(() => _obs(cibleId: ''), throwsA(isA<AssertionError>()));
      expect(() => _obs(titre: ''), throwsA(isA<AssertionError>()));
    });

    test('rejects an inconsistent resolved/date pair', () {
      // resolved without a date
      expect(() => _obs(resolu: true), throwsA(isA<AssertionError>()));
      // a date without being resolved
      expect(
        () => _obs(dateResolution: DateTime(2026, 6, 20)),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects a resolution date before the observation date', () {
      expect(
        () => _obs(resolu: true, dateResolution: DateTime(2026, 6, 1)),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Observation — severity', () {
    test('can be re-assessed', () {
      final o = _obs();
      o.changerGravite(GraviteObservation.critique);
      expect(o.gravite, GraviteObservation.critique);
    });
  });

  group('Observation — resolution lifecycle', () {
    test('resoudre marks resolved and records actions', () {
      final o = _obs();
      o.resoudre(DateTime(2026, 6, 20), actions: 'Retrait des feuilles atteintes');
      expect(o.resolu, isTrue);
      expect(o.dateResolution, DateTime(2026, 6, 20));
      expect(o.actionsRealisees, 'Retrait des feuilles atteintes');
    });

    test('resoudre rejects a date before the observation', () {
      final o = _obs();
      expect(
        () => o.resoudre(DateTime(2026, 6, 1)),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rouvrir clears the resolution data', () {
      final o = _obs();
      o.resoudre(DateTime(2026, 6, 20));
      o.rouvrir();
      expect(o.resolu, isFalse);
      expect(o.dateResolution, isNull);
      expect(o.actionsRealisees, isNull);
    });
  });

  group('Observation — identity', () {
    test('equality is by id', () {
      expect(_obs(id: 'a') == _obs(id: 'a'), isTrue);
      expect(_obs(id: 'a') == _obs(id: 'b'), isFalse);
    });
  });
}
