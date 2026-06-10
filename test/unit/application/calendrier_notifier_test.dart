import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:pot_a_gerer/application/providers/horloge_provider.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/state/calendrier_notifier.dart';
import 'package:pot_a_gerer/application/state/calendrier_vue.dart';
import 'package:pot_a_gerer/domain/entities/tache.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/etat_tache.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_tache_repository.dart';

class MockTaches extends Mock implements AbstractTacheRepository {}

class _FakeTache extends Fake implements Tache {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeTache()));

  // Monday 8 June 2026, 08:24 (matches the mock-up's reference day).
  final maintenant = DateTime(2026, 6, 8, 8, 24);

  late MockTaches taches;

  setUp(() => taches = MockTaches());

  Tache uneTache(String id, DateTime quand, {EtatTache etat = EtatTache.aFaire}) =>
      Tache(
        id: id,
        titre: 'Tâche $id',
        type: TypeTache.arrosage,
        cible: CibleTache.parcelle,
        cibleId: 'z-1',
        datePrevue: quand,
        etat: etat,
        dateRealisation: etat == EtatTache.terminee ? quand : null,
      );

  ProviderContainer conteneur() {
    final c = ProviderContainer(overrides: [
      tacheRepositoryProvider.overrideWithValue(taches),
      horlogeProvider.overrideWithValue(() => maintenant),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('default scope is a 7-day window from today', () async {
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);

    await conteneur().read(calendrierProvider.future);

    final captured =
        verify(() => taches.obtenirEntreDates(captureAny(), captureAny()))
            .captured;
    expect(captured[0], DateTime(2026, 6, 8));
    expect(captured[1], DateTime(2026, 6, 15)); // +7 days, exclusive
  });

  test('groups tasks by day, ordered by day then undone-first', () async {
    when(() => taches.obtenirEntreDates(any(), any())).thenAnswer(
      (_) async => [
        uneTache('d9', DateTime(2026, 6, 9, 10)),
        uneTache('d8-done', DateTime(2026, 6, 8, 9), etat: EtatTache.terminee),
        uneTache('d8-late', DateTime(2026, 6, 8, 18)),
        uneTache('d8-early', DateTime(2026, 6, 8, 7)),
      ],
    );

    final vue = await conteneur().read(calendrierProvider.future);

    expect(vue.groupes, hasLength(2));
    expect(vue.groupes[0].jour, DateTime(2026, 6, 8));
    expect(
      vue.groupes[0].taches.map((t) => t.id),
      ['d8-early', 'd8-late', 'd8-done'],
    );
    expect(vue.groupes[1].jour, DateTime(2026, 6, 9));
    expect(vue.total, 4);
    expect(vue.faites, 1);
    expect(vue.restantes, 3);
  });

  test('switching to month scope widens the window to month end', () async {
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);
    final c = conteneur();
    await c.read(calendrierProvider.future);

    await c.read(calendrierProvider.notifier).definirPortee(PorteeAgenda.mois);

    final captured =
        verify(() => taches.obtenirEntreDates(captureAny(), captureAny()))
            .captured;
    // Each assemble reads two windows (agenda + month grid); in month scope the
    // agenda window itself runs [8 June, 1 July).
    final paires = [
      for (var i = 0; i < captured.length; i += 2)
        (captured[i], captured[i + 1]),
    ];
    expect(paires, contains((DateTime(2026, 6, 8), DateTime(2026, 7, 1))));
  });

  test('exposes the displayed month and navigates between months', () async {
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);
    final c = conteneur();
    final vue = await c.read(calendrierProvider.future);
    expect(vue.moisAffiche, DateTime(2026, 6, 1));

    await c.read(calendrierProvider.notifier).moisSuivant();
    expect(c.read(calendrierProvider).value!.moisAffiche, DateTime(2026, 7, 1));

    await c.read(calendrierProvider.notifier).moisPrecedent();
    await c.read(calendrierProvider.notifier).moisPrecedent();
    expect(c.read(calendrierProvider).value!.moisAffiche, DateTime(2026, 5, 1));

    await c.read(calendrierProvider.notifier).revenirMoisActuel();
    expect(c.read(calendrierProvider).value!.moisAffiche, DateTime(2026, 6, 1));
  });

  test('groupePourJour returns the displayed month tasks by day', () async {
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => [uneTache('m', DateTime(2026, 6, 20, 9))]);

    final vue = await conteneur().read(calendrierProvider.future);

    expect(vue.groupePourJour(DateTime(2026, 6, 20)), isNotNull);
    expect(vue.groupePourJour(DateTime(2026, 6, 21)), isNull);
  });

  test('filtering by type narrows both the agenda and the month', () async {
    Tache typee(String id, TypeTache type) => Tache(
          id: id,
          titre: 'Tâche $id',
          type: type,
          cible: CibleTache.parcelle,
          cibleId: 'z-1',
          datePrevue: DateTime(2026, 6, 8, 10),
        );
    when(() => taches.obtenirEntreDates(any(), any())).thenAnswer(
      (_) async => [
        typee('arr', TypeTache.arrosage),
        typee('tai', TypeTache.taille),
      ],
    );

    final c = conteneur();
    await c.read(calendrierProvider.future);

    await c
        .read(calendrierProvider.notifier)
        .definirFiltreType(TypeTache.taille);

    final vue = c.read(calendrierProvider).value!;
    expect(vue.groupes.single.taches.map((t) => t.id), ['tai']);
    expect(vue.groupePourJour(DateTime(2026, 6, 8))!.taches.map((t) => t.id),
        ['tai']);
  });

  test('ticking a task marks it done and persists it', () async {
    final tache = uneTache('t1', DateTime(2026, 6, 8, 10));
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => [tache]);
    when(() => taches.sauvegarder(any())).thenAnswer((_) async {});

    final c = conteneur();
    await c.read(calendrierProvider.future);

    await c.read(calendrierProvider.notifier).cocher(tache);

    expect(tache.estFaite, isTrue);
    expect(tache.dateRealisation, maintenant);
    verify(() => taches.sauvegarder(tache)).called(1);
  });

  test('ticking a done task reopens it and persists it', () async {
    final tache =
        uneTache('t1', DateTime(2026, 6, 8, 10), etat: EtatTache.terminee);
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => [tache]);
    when(() => taches.sauvegarder(any())).thenAnswer((_) async {});

    final c = conteneur();
    await c.read(calendrierProvider.future);

    await c.read(calendrierProvider.notifier).cocher(tache);

    expect(tache.estFaite, isFalse);
    expect(tache.dateRealisation, isNull);
    verify(() => taches.sauvegarder(tache)).called(1);
  });

  test('empty window is flagged', () async {
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);

    final vue = await conteneur().read(calendrierProvider.future);

    expect(vue.vide, isTrue);
    expect(vue.groupes, isEmpty);
  });
}
