import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/rappel.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/etat_rappel.dart';
import 'package:pot_a_gerer/domain/enums/jour_semaine.dart';
import 'package:pot_a_gerer/domain/enums/priorite_tache.dart';
import 'package:pot_a_gerer/domain/enums/type_recurrence.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';

Rappel _rappel({
  required TypeRecurrence recurrence,
  DateTime? dateDebut,
  DateTime? dateFin,
  int? intervalleJours,
  Set<JourSemaine>? joursSemaine,
  int? jourDuMois,
  EtatRappel etat = EtatRappel.actif,
}) =>
    Rappel(
      id: 'rap1',
      titre: 'Arrosage',
      typeTacheGeneree: TypeTache.arrosage,
      cible: CibleTache.plantation,
      cibleId: 'pl1',
      dateDebut: dateDebut ?? DateTime(2026, 6, 10),
      typeRecurrence: recurrence,
      dateFin: dateFin,
      intervalleJours: intervalleJours,
      joursSemaine: joursSemaine,
      jourDuMois: jourDuMois,
      etat: etat,
    );

void main() {
  group('Rappel — recurrence invariants', () {
    test('custom needs a positive interval', () {
      expect(
        () => _rappel(recurrence: TypeRecurrence.personnalise),
        throwsA(isA<AssertionError>()),
      );
    });
    test('weekly needs at least one weekday', () {
      expect(
        () => _rappel(recurrence: TypeRecurrence.hebdomadaire),
        throwsA(isA<AssertionError>()),
      );
    });
    test('monthly needs a valid day of month', () {
      expect(
        () => _rappel(recurrence: TypeRecurrence.mensuel),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => _rappel(recurrence: TypeRecurrence.mensuel, jourDuMois: 32),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Rappel — prochaineRecurrence', () {
    test('ponctuel: only the start date, once', () {
      final r = _rappel(recurrence: TypeRecurrence.ponctuel);
      expect(r.prochaineRecurrence(DateTime(2026, 6, 5)), DateTime(2026, 6, 10));
      expect(r.prochaineRecurrence(DateTime(2026, 6, 10)), isNull);
      expect(r.prochaineRecurrence(DateTime(2026, 6, 20)), isNull);
    });

    test('quotidien: the next day (or the start)', () {
      final r = _rappel(recurrence: TypeRecurrence.quotidien);
      expect(r.prochaineRecurrence(DateTime(2026, 6, 5)), DateTime(2026, 6, 10));
      expect(
          r.prochaineRecurrence(DateTime(2026, 6, 12)), DateTime(2026, 6, 13));
    });

    test('personnalise: start + k*interval', () {
      final r = _rappel(
          recurrence: TypeRecurrence.personnalise, intervalleJours: 3);
      expect(
          r.prochaineRecurrence(DateTime(2026, 6, 5)), DateTime(2026, 6, 10));
      expect(
          r.prochaineRecurrence(DateTime(2026, 6, 10)), DateTime(2026, 6, 13));
      expect(
          r.prochaineRecurrence(DateTime(2026, 6, 13)), DateTime(2026, 6, 16));
    });

    test('hebdomadaire: same weekday, +7 days', () {
      final debut = DateTime(2026, 6, 10);
      final r = _rappel(
        recurrence: TypeRecurrence.hebdomadaire,
        dateDebut: debut,
        joursSemaine: {debut.jourSemaine},
      );
      expect(r.prochaineRecurrence(DateTime(2026, 6, 8)), debut);
      expect(r.prochaineRecurrence(debut), DateTime(2026, 6, 17));
    });

    test('mensuel: same day each month, skipping short months', () {
      final r = _rappel(
        recurrence: TypeRecurrence.mensuel,
        dateDebut: DateTime(2026, 1, 1),
        jourDuMois: 31,
      );
      expect(
          r.prochaineRecurrence(DateTime(2026, 1, 1)), DateTime(2026, 1, 31));
      // February has no 31st -> next is March 31st.
      expect(
          r.prochaineRecurrence(DateTime(2026, 2, 1)), DateTime(2026, 3, 31));
    });

    test('respects dateFin', () {
      final r = _rappel(
        recurrence: TypeRecurrence.quotidien,
        dateFin: DateTime(2026, 6, 11),
      );
      expect(
          r.prochaineRecurrence(DateTime(2026, 6, 10)), DateTime(2026, 6, 11));
      expect(r.prochaineRecurrence(DateTime(2026, 6, 11)), isNull);
    });

    test('a paused reminder yields nothing', () {
      final r = _rappel(
          recurrence: TypeRecurrence.quotidien, etat: EtatRappel.enPause);
      expect(r.prochaineRecurrence(DateTime(2026, 6, 5)), isNull);
    });
  });

  group('Rappel — genererTache', () {
    test('produces a task carrying the reminder context', () {
      final r = _rappel(recurrence: TypeRecurrence.quotidien);
      final t = r.genererTache(id: 't1', datePrevue: DateTime(2026, 6, 11));
      expect(t.id, 't1');
      expect(t.datePrevue, DateTime(2026, 6, 11));
      expect(t.type, TypeTache.arrosage);
      expect(t.cible, CibleTache.plantation);
      expect(t.cibleId, 'pl1');
      expect(t.priorite, PrioriteTache.normale);
      expect(t.rappelOrigineId, 'rap1');
    });
  });

  group('Rappel — lifecycle & identity', () {
    test('pause/reactivate/terminate', () {
      final r = _rappel(recurrence: TypeRecurrence.quotidien);
      r.mettreEnPause();
      expect(r.etat, EtatRappel.enPause);
      r.reactiver();
      expect(r.etat, EtatRappel.actif);
      r.terminer();
      expect(r.etat, EtatRappel.termine);
    });

    test('equality is by id', () {
      final a = _rappel(recurrence: TypeRecurrence.quotidien);
      final b = _rappel(recurrence: TypeRecurrence.mensuel, jourDuMois: 1);
      expect(a, b); // same id 'rap1'
    });
  });
}
