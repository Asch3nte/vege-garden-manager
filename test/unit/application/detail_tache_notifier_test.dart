import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:pot_a_gerer/application/providers/horloge_provider.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/state/detail_tache_notifier.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/entities/tache.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/etat_tache.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/priorite_tache.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_tache_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';

class MockTaches extends Mock implements AbstractTacheRepository {}

class MockParcelles extends Mock implements AbstractParcelleRepository {}

class _FakeTache extends Fake implements Tache {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeTache()));

  final maintenant = DateTime(2026, 6, 9, 10);

  late MockTaches taches;
  late MockParcelles parcelles;

  setUp(() {
    taches = MockTaches();
    parcelles = MockParcelles();
    when(() => taches.sauvegarder(any())).thenAnswer((_) async {});
    when(() => taches.supprimer(any())).thenAnswer((_) async {});
  });

  Tache uneTache({
    String id = 't-1',
    EtatTache etat = EtatTache.aFaire,
    PrioriteTache priorite = PrioriteTache.normale,
    String? notes,
  }) =>
      Tache(
        id: id,
        titre: 'Arroser',
        type: TypeTache.arrosage,
        cible: CibleTache.parcelle,
        cibleId: 'z-1',
        datePrevue: DateTime(2026, 6, 9),
        etat: etat,
        priorite: priorite,
        notes: notes,
        dateRealisation: etat == EtatTache.terminee ? DateTime(2026, 6, 9) : null,
      );

  Parcelle uneParcelle() => Parcelle(
        id: 'z-1',
        nom: 'Carré nord',
        potagerId: 'pot-1',
        type: TypeParcelle.bacSureleve,
        surface: Surface.enMetresCarres(1),
        exposition: NiveauSoleil.pleinSoleil,
      );

  ProviderContainer conteneur() {
    final c = ProviderContainer(overrides: [
      tacheRepositoryProvider.overrideWithValue(taches),
      parcelleRepositoryProvider.overrideWithValue(parcelles),
      horlogeProvider.overrideWithValue(() => maintenant),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('loads the task and resolves a parcelle target (name + route)', () async {
    when(() => taches.obtenirParId('t-1'))
        .thenAnswer((_) async => uneTache());
    when(() => parcelles.obtenirParId('z-1'))
        .thenAnswer((_) async => uneParcelle());

    final vue = await conteneur().read(detailTacheProvider('t-1').future);

    expect(vue, isNotNull);
    expect(vue!.tache.id, 't-1');
    expect(vue.cibleNom, 'Carré nord');
    expect(vue.cibleRoute, '/potager/zone/z-1');
  });

  test('returns null when the task does not exist', () async {
    when(() => taches.obtenirParId('missing')).thenAnswer((_) async => null);

    final vue = await conteneur().read(detailTacheProvider('missing').future);

    expect(vue, isNull);
  });

  test('basculerFait marks the task done and persists it', () async {
    when(() => taches.obtenirParId('t-1'))
        .thenAnswer((_) async => uneTache());
    when(() => parcelles.obtenirParId(any()))
        .thenAnswer((_) async => uneParcelle());

    final c = conteneur();
    await c.read(detailTacheProvider('t-1').future);
    await c.read(detailTacheProvider('t-1').notifier).basculerFait();

    final saved =
        verify(() => taches.sauvegarder(captureAny())).captured.last as Tache;
    expect(saved.estFaite, isTrue);
  });

  test('changerPriorite updates and persists the priority', () async {
    when(() => taches.obtenirParId('t-1'))
        .thenAnswer((_) async => uneTache());
    when(() => parcelles.obtenirParId(any()))
        .thenAnswer((_) async => uneParcelle());

    final c = conteneur();
    await c.read(detailTacheProvider('t-1').future);
    await c
        .read(detailTacheProvider('t-1').notifier)
        .changerPriorite(PrioriteTache.urgente);

    final saved =
        verify(() => taches.sauvegarder(captureAny())).captured.last as Tache;
    expect(saved.priorite, PrioriteTache.urgente);
  });

  test('modifierNotes trims, and blanks are stored as null', () async {
    when(() => taches.obtenirParId('t-1'))
        .thenAnswer((_) async => uneTache());
    when(() => parcelles.obtenirParId(any()))
        .thenAnswer((_) async => uneParcelle());

    final c = conteneur();
    await c.read(detailTacheProvider('t-1').future);
    final notifier = c.read(detailTacheProvider('t-1').notifier);

    await notifier.modifierNotes('  arroser au pied  ');
    var saved =
        verify(() => taches.sauvegarder(captureAny())).captured.last as Tache;
    expect(saved.notes, 'arroser au pied');

    await notifier.modifierNotes('   ');
    saved = verify(() => taches.sauvegarder(captureAny())).captured.last as Tache;
    expect(saved.notes, isNull);
  });

  test('reporter reschedules the task to the chosen date', () async {
    when(() => taches.obtenirParId('t-1'))
        .thenAnswer((_) async => uneTache(etat: EtatTache.terminee));
    when(() => parcelles.obtenirParId(any()))
        .thenAnswer((_) async => uneParcelle());

    final c = conteneur();
    await c.read(detailTacheProvider('t-1').future);
    await c
        .read(detailTacheProvider('t-1').notifier)
        .reporter(DateTime(2026, 6, 20));

    final saved =
        verify(() => taches.sauvegarder(captureAny())).captured.last as Tache;
    expect(saved.datePrevue, DateTime(2026, 6, 20));
    expect(saved.estFaite, isFalse); // reporter resets to to-do
  });

  test('annuler cancels the task', () async {
    when(() => taches.obtenirParId('t-1'))
        .thenAnswer((_) async => uneTache());
    when(() => parcelles.obtenirParId(any()))
        .thenAnswer((_) async => uneParcelle());

    final c = conteneur();
    await c.read(detailTacheProvider('t-1').future);
    await c.read(detailTacheProvider('t-1').notifier).annuler();

    final saved =
        verify(() => taches.sauvegarder(captureAny())).captured.last as Tache;
    expect(saved.etat, EtatTache.annulee);
  });

  test('supprimerTache deletes via the repository', () async {
    when(() => taches.obtenirParId('t-1'))
        .thenAnswer((_) async => uneTache());
    when(() => parcelles.obtenirParId(any()))
        .thenAnswer((_) async => uneParcelle());

    final c = conteneur();
    await c.read(detailTacheProvider('t-1').future);
    await c.read(detailTacheProvider('t-1').notifier).supprimerTache();

    verify(() => taches.supprimer('t-1')).called(1);
  });
}
