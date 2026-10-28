@Tags(['dst'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/rappel.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/jour_semaine.dart';
import 'package:pot_a_gerer/domain/enums/type_recurrence.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';

typedef _Jour = (int, int, int);

/// Windows enclosing the 2026 switches: Europe (03-29, 10-25) and
/// Australia/Sydney (04-05, 10-04).
final _fenetres = <String, (DateTime, DateTime)>{
  'Europe spring': (DateTime(2026, 3, 25), DateTime(2026, 4, 2)),
  'Europe autumn': (DateTime(2026, 10, 21), DateTime(2026, 10, 29)),
  'Sydney autumn': (DateTime(2026, 4, 1), DateTime(2026, 4, 9)),
  'Sydney spring': (DateTime(2026, 9, 30), DateTime(2026, 10, 8)),
};

_Jour _cle(DateTime d) => (d.year, d.month, d.day);

/// Calendar days of [debut]..[fin] (inclusive) matching [garde], computed in
/// UTC so the expectation never depends on the process time zone.
List<_Jour> _attendus(
  DateTime debut,
  DateTime fin,
  bool Function(DateTime utc) garde,
) {
  final out = <_Jour>[];
  for (
    var d = DateTime.utc(debut.year, debut.month, debut.day);
    !d.isAfter(DateTime.utc(fin.year, fin.month, fin.day));
    d = DateTime.utc(d.year, d.month, d.day + 1)
  ) {
    if (garde(d)) out.add(_cle(d));
  }
  return out;
}

Rappel _rappel(
  TypeRecurrence type,
  DateTime debut, {
  DateTime? fin,
  int? intervalle,
  Set<JourSemaine>? jours,
  int? jourDuMois,
}) => Rappel(
  id: 'r',
  titre: 'T',
  typeTacheGeneree: TypeTache.arrosage,
  cible: CibleTache.potager,
  cibleId: 'p',
  dateDebut: debut,
  dateFin: fin,
  typeRecurrence: type,
  intervalleJours: intervalle,
  joursSemaine: jours,
  jourDuMois: jourDuMois,
);

/// Occurrences within [debut]..[fin], walking `prochaineRecurrence` from the
/// day before [debut]. Bounded so a regression cannot loop forever.
List<DateTime> _enumerer(Rappel r, DateTime debut, DateTime fin) {
  final out = <DateTime>[];
  var curseur = DateTime(debut.year, debut.month, debut.day - 1);
  final limite = DateTime(fin.year, fin.month, fin.day);
  for (var i = 0; i < 1000; i++) {
    final p = r.prochaineRecurrence(curseur);
    if (p == null || p.isAfter(limite)) return out;
    out.add(p);
    curseur = p;
  }
  fail('enumeration did not terminate');
}

void _verifier(Rappel r, DateTime debut, DateTime fin, List<_Jour> attendus) {
  final occ = _enumerer(r, debut, fin);
  expect(occ.map(_cle).toList(), attendus);
  expect(
    occ.every((d) => d.hour == 0 && d.minute == 0),
    isTrue,
    reason: 'occurrences are local midnights',
  );
}

void main() {
  const delai = Timeout(Duration(seconds: 5));

  for (final MapEntry(key: nom, value: (debut, fin)) in _fenetres.entries) {
    group('$nom window', () {
      test('daily: one occurrence per day, dateFin included', () {
        final r = _rappel(TypeRecurrence.quotidien, debut, fin: fin);
        _verifier(r, debut, fin, _attendus(debut, fin, (_) => true));
        expect(
          r.prochaineRecurrence(DateTime(fin.year, fin.month, fin.day - 1)),
          fin,
        );
        expect(r.prochaineRecurrence(fin), isNull);
      }, timeout: delai);

      test('daily from a time-of-day cursor still yields each day once', () {
        final r = _rappel(TypeRecurrence.quotidien, debut, fin: fin);
        final out = <DateTime>[];
        var curseur = DateTime(debut.year, debut.month, debut.day - 1, 23, 59);
        for (var i = 0; i < 100; i++) {
          final p = r.prochaineRecurrence(curseur);
          if (p == null) break;
          out.add(p);
          curseur = p.add(const Duration(hours: 12));
        }
        expect(out.map(_cle).toList(), _attendus(debut, fin, (_) => true));
      }, timeout: delai);

      test('weekly: Sunday and Monday occurrences, dateFin included', () {
        final jours = {JourSemaine.dimanche, JourSemaine.lundi};
        final r = _rappel(
          TypeRecurrence.hebdomadaire,
          debut,
          fin: fin,
          jours: jours,
        );
        _verifier(
          r,
          debut,
          fin,
          _attendus(
            debut,
            fin,
            (d) => d.weekday == DateTime.sunday || d.weekday == DateTime.monday,
          ),
        );
      }, timeout: delai);

      test('weekly ending on a Sunday includes that day', () {
        var dimanche = debut;
        while (dimanche.weekday != DateTime.sunday) {
          dimanche = DateTime(dimanche.year, dimanche.month, dimanche.day + 1);
        }
        final r = _rappel(
          TypeRecurrence.hebdomadaire,
          debut,
          fin: dimanche,
          jours: {JourSemaine.dimanche},
        );
        _verifier(r, debut, fin, [_cle(dimanche)]);
      }, timeout: delai);

      test('custom intervals 1, 2, 3 and 7: exact arithmetic across the switch', () {
        for (final n in [1, 2, 3, 7]) {
          final r = _rappel(
            TypeRecurrence.personnalise,
            debut,
            fin: fin,
            intervalle: n,
          );
          final base = DateTime.utc(debut.year, debut.month, debut.day);
          _verifier(
            r,
            debut,
            fin,
            _attendus(debut, fin, (d) => d.difference(base).inDays % n == 0),
          );
        }
      }, timeout: delai);

      test('custom interval started months earlier stays aligned', () {
        final depart = DateTime(2026, 1, 1);
        final base = DateTime.utc(2026, 1, 1);
        for (final n in [2, 5, 7]) {
          final r = _rappel(
            TypeRecurrence.personnalise,
            depart,
            fin: fin,
            intervalle: n,
          );
          _verifier(
            r,
            debut,
            fin,
            _attendus(debut, fin, (d) => d.difference(base).inDays % n == 0),
          );
        }
      }, timeout: delai);

      test('monthly: the switch day of month, then day 31', () {
        for (final jour in [debut.day, fin.day, 29, 25, 5, 4, 31]) {
          final r = _rappel(
            TypeRecurrence.mensuel,
            debut,
            fin: fin,
            jourDuMois: jour,
          );
          _verifier(
            r,
            debut,
            fin,
            _attendus(debut, fin, (d) {
              final dernier = DateTime.utc(d.year, d.month + 1, 0).day;
              return d.day == (jour > dernier ? dernier : jour);
            }),
          );
        }
      }, timeout: delai);

      test('one-off on each day of the window is returned once', () {
        for (final jour in _attendus(debut, fin, (_) => true)) {
          final d = DateTime(jour.$1, jour.$2, jour.$3);
          final r = _rappel(TypeRecurrence.ponctuel, d);
          _verifier(r, debut, fin, [jour]);
          expect(r.prochaineRecurrence(d), isNull);
        }
      }, timeout: delai);
    });
  }

  test('monthly day 31 over 2026 gives the last day of every month', () {
    final debut = DateTime(2026, 1, 1);
    final fin = DateTime(2026, 12, 31);
    final r = _rappel(TypeRecurrence.mensuel, debut, fin: fin, jourDuMois: 31);
    _verifier(r, debut, fin, [
      for (var m = 1; m <= 12; m++) (2026, m, DateTime.utc(2026, m + 1, 0).day),
    ]);
  }, timeout: delai);

  test('daily over the whole of 2026: 365 occurrences, none doubled', () {
    final debut = DateTime(2026, 1, 1);
    final fin = DateTime(2026, 12, 31);
    final r = _rappel(TypeRecurrence.quotidien, debut, fin: fin);
    final occ = _enumerer(r, debut, fin);
    expect(occ, hasLength(365));
    expect(occ.map(_cle).toSet(), hasLength(365));
  }, timeout: delai);
}
