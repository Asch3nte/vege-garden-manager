// Unit tests for the (day, gesture) grouping shared by Accueil and Calendrier.
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/application/state/geste_groupe.dart';
import 'package:pot_a_gerer/domain/entities/tache.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/etat_tache.dart';
import 'package:pot_a_gerer/domain/enums/priorite_tache.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';

void main() {
  Tache uneTache(
    String id,
    DateTime quand, {
    TypeTache type = TypeTache.arrosage,
    bool faite = false,
    PrioriteTache priorite = PrioriteTache.normale,
    String cibleId = 'p-1',
  }) =>
      Tache(
        id: id,
        titre: 'Tâche $id',
        type: type,
        cible: CibleTache.plantation,
        cibleId: cibleId,
        datePrevue: quand,
        priorite: priorite,
        etat: faite ? EtatTache.terminee : EtatTache.aFaire,
        dateRealisation: faite ? quand : null,
      );

  test('same type + same day collapse into one group', () {
    final groupes = GesteGroupe.grouper([
      uneTache('a', DateTime(2026, 6, 8, 8)),
      uneTache('b', DateTime(2026, 6, 8, 9)),
      uneTache('c', DateTime(2026, 6, 8, 10)),
    ]);

    expect(groupes, hasLength(1));
    expect(groupes.single.type, TypeTache.arrosage);
    expect(groupes.single.nombre, 3);
    expect(groupes.single.jour, DateTime(2026, 6, 8));
    expect(groupes.single.estSeule, isFalse);
  });

  test('different types on the same day stay separate', () {
    final groupes = GesteGroupe.grouper([
      uneTache('a', DateTime(2026, 6, 8, 8)),
      uneTache('b', DateTime(2026, 6, 8, 9), type: TypeTache.semis),
    ]);

    expect(groupes, hasLength(2));
    expect(groupes.map((g) => g.type),
        containsAll([TypeTache.arrosage, TypeTache.semis]));
  });

  test('the same type on different days stays separate', () {
    final groupes = GesteGroupe.grouper([
      uneTache('a', DateTime(2026, 6, 8, 8)),
      uneTache('b', DateTime(2026, 6, 9, 8)),
    ]);

    expect(groupes, hasLength(2));
    expect(groupes.map((g) => g.jour),
        [DateTime(2026, 6, 8), DateTime(2026, 6, 9)]);
  });

  test('a lone task yields a single-task group', () {
    final groupes =
        GesteGroupe.grouper([uneTache('a', DateTime(2026, 6, 8, 8))]);

    expect(groupes.single.estSeule, isTrue);
    expect(groupes.single.tacheUnique.id, 'a');
  });

  test('tacheUnique refuses a multi-task group', () {
    final groupe = GesteGroupe.grouper([
      uneTache('a', DateTime(2026, 6, 8, 8)),
      uneTache('b', DateTime(2026, 6, 8, 9)),
    ]).single;

    expect(() => groupe.tacheUnique, throwsStateError);
  });

  test('completion state is aggregated', () {
    final groupe = GesteGroupe.grouper([
      uneTache('a', DateTime(2026, 6, 8, 8), faite: true),
      uneTache('b', DateTime(2026, 6, 8, 9)),
      uneTache('c', DateTime(2026, 6, 8, 10)),
    ]).single;

    expect(groupe.nombreFaites, 1);
    expect(groupe.toutesFaites, isFalse);
    expect(groupe.aucuneFaite, isFalse);
    expect(groupe.partiellementFaite, isTrue);
    expect(groupe.tachesAFaire.map((t) => t.id), ['b', 'c']);
  });

  test('a fully done group is neither partial nor untouched', () {
    final groupe = GesteGroupe.grouper([
      uneTache('a', DateTime(2026, 6, 8, 8), faite: true),
      uneTache('b', DateTime(2026, 6, 8, 9), faite: true),
    ]).single;

    expect(groupe.toutesFaites, isTrue);
    expect(groupe.partiellementFaite, isFalse);
    expect(groupe.tachesAFaire, isEmpty);
  });

  test('group priority is the highest of its tasks', () {
    final groupe = GesteGroupe.grouper([
      uneTache('a', DateTime(2026, 6, 8, 8), priorite: PrioriteTache.basse),
      uneTache('b', DateTime(2026, 6, 8, 9), priorite: PrioriteTache.urgente),
      uneTache('c', DateTime(2026, 6, 8, 10), priorite: PrioriteTache.normale),
    ]).single;

    expect(groupe.priorite, PrioriteTache.urgente);
  });

  test('inside a group, undone tasks come first then by time', () {
    final groupe = GesteGroupe.grouper([
      uneTache('done-early', DateTime(2026, 6, 8, 7), faite: true),
      uneTache('late', DateTime(2026, 6, 8, 18)),
      uneTache('early', DateTime(2026, 6, 8, 9)),
    ]).single;

    expect(groupe.taches.map((t) => t.id), ['early', 'late', 'done-early']);
    expect(groupe.premierInstant, DateTime(2026, 6, 8, 7));
  });

  test('groups with work left come before fully-done groups', () {
    final groupes = GesteGroupe.grouper([
      uneTache('eau', DateTime(2026, 6, 8, 7), faite: true),
      uneTache('semis', DateTime(2026, 6, 8, 15), type: TypeTache.semis),
    ]);

    expect(groupes.map((g) => g.type), [TypeTache.semis, TypeTache.arrosage]);
  });

  test('groups are ordered by day first', () {
    final groupes = GesteGroupe.grouper([
      uneTache('demain', DateTime(2026, 6, 9, 7)),
      uneTache('aujourdhui', DateTime(2026, 6, 8, 18)),
    ]);

    expect(groupes.map((g) => g.jour),
        [DateTime(2026, 6, 8), DateTime(2026, 6, 9)]);
  });

  test('exposed lists are unmodifiable', () {
    final groupe = GesteGroupe.grouper([
      uneTache('a', DateTime(2026, 6, 8, 8)),
      uneTache('b', DateTime(2026, 6, 8, 9)),
    ]).single;

    expect(() => groupe.taches.add(uneTache('c', DateTime(2026, 6, 8, 10))),
        throwsUnsupportedError);
    expect(() => groupe.tachesAFaire.clear(), throwsUnsupportedError);
  });

  test('grouping an empty list yields no group', () {
    expect(GesteGroupe.grouper(const []), isEmpty);
  });
}
