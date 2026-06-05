import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/tache.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/etat_tache.dart';
import 'package:pot_a_gerer/domain/enums/priorite_tache.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';

Tache _tache({
  String id = 't1',
  String titre = 'Arroser les tomates',
  EtatTache etat = EtatTache.aFaire,
  DateTime? dateRealisation,
}) =>
    Tache(
      id: id,
      titre: titre,
      type: TypeTache.arrosage,
      cible: CibleTache.plantation,
      cibleId: 'pl1',
      datePrevue: DateTime(2026, 6, 20),
      etat: etat,
      dateRealisation: dateRealisation,
    );

void main() {
  group('Tache — construction', () {
    test('defaults: to-do, normal priority', () {
      final t = _tache();
      expect(t.etat, EtatTache.aFaire);
      expect(t.priorite, PrioriteTache.normale);
      expect(t.estFaite, isFalse);
    });

    test('rejects empty id/titre/cibleId', () {
      expect(() => _tache(id: ''), throwsA(isA<AssertionError>()));
      expect(() => _tache(titre: ''), throwsA(isA<AssertionError>()));
    });

    test('a completed task requires a completion date', () {
      expect(
        () => _tache(etat: EtatTache.terminee),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Tache — lifecycle', () {
    test('demarrer sets in progress', () {
      final t = _tache()..demarrer();
      expect(t.etat, EtatTache.enCours);
    });

    test('marquerFaite completes with date and duration', () {
      final t = _tache();
      t.marquerFaite(DateTime(2026, 6, 20), dureeMinutes: 15);
      expect(t.estFaite, isTrue);
      expect(t.dateRealisation, DateTime(2026, 6, 20));
      expect(t.dureeReelleMinutes, 15);
    });

    test('marquerFaite rejects a non-positive duration', () {
      final t = _tache();
      expect(
        () => t.marquerFaite(DateTime(2026, 6, 20), dureeMinutes: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('reporter reschedules and resets to-do', () {
      final t = _tache();
      t.marquerFaite(DateTime(2026, 6, 20));
      t.reporter(DateTime(2026, 6, 25));
      expect(t.datePrevue, DateTime(2026, 6, 25));
      expect(t.etat, EtatTache.aFaire);
      expect(t.dateRealisation, isNull);
    });

    test('annuler cancels the task', () {
      final t = _tache()..annuler();
      expect(t.etat, EtatTache.annulee);
    });
  });

  group('Tache — identity', () {
    test('equality is by id', () {
      expect(_tache(id: 'a') == _tache(id: 'a'), isTrue);
      expect(_tache(id: 'a') == _tache(id: 'b'), isFalse);
    });
  });
}
