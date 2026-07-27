import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/application/providers/database_providers.dart';
import 'package:pot_a_gerer/application/state/equipements_notifier.dart';
import 'package:pot_a_gerer/application/state/observations_notifier.dart';
import 'package:pot_a_gerer/application/state/parcelles_notifier.dart';
import 'package:pot_a_gerer/application/state/plantations_notifier.dart';
import 'package:pot_a_gerer/application/state/rappels_actifs_notifier.dart';
import 'package:pot_a_gerer/application/state/recoltes_notifier.dart';
import 'package:pot_a_gerer/application/state/taches_notifier.dart';
import 'package:pot_a_gerer/domain/enums/cible_observation.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/etat_equipement.dart';
import 'package:pot_a_gerer/domain/enums/jour_semaine.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/qualite_recolte.dart';
import 'package:pot_a_gerer/domain/enums/type_equipement.dart';
import 'package:pot_a_gerer/domain/enums/type_observation.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/enums/type_recurrence.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';
import 'package:pot_a_gerer/domain/enums/unite_quantite.dart';
import 'package:pot_a_gerer/domain/value_objects/quantite.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:riverpod/riverpod.dart';

/// End-to-end coverage of the Application CRUD slice: use case + notifier +
/// repository + mapper, exercised through an in-memory database.
void main() {
  late AppDatabase db;
  late ProviderContainer container;
  final seedDate = DateTime.utc(2026, 5, 1).toIso8601String();

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(() {
      container.dispose();
      db.close();
    });
    // FK parents: potager -> parcelle -> plantation.
    await db.into(db.potagers).insert(PotagersCompanion.insert(
        id: 'pot1',
        nom: 'J',
        climatType: 'oceanique',
        zoneRusticite: 'zone8',
        dateCreation: seedDate,
        createdAt: seedDate,
        updatedAt: seedDate));
    await db.into(db.parcelles).insert(ParcellesCompanion.insert(
        id: 'par1',
        nom: 'P',
        potagerId: 'pot1',
        type: 'bacSureleve',
        surfaceValeur: 4,
        surfaceUnite: 'm2',
        exposition: 'pleinSoleil',
        positionOrdre: 0,
        dateCreation: seedDate,
        createdAt: seedDate,
        updatedAt: seedDate));
    await db.into(db.plantations).insert(PlantationsCompanion.insert(
        id: 'pl1',
        parcelleId: 'par1',
        planteId: 'tomate',
        dateMiseEnPlace: seedDate,
        methode: 'repiquage',
        surfaceOccupeeValeur: 1,
        nombrePieds: 2,
        createdAt: seedDate,
        updatedAt: seedDate));
  });

  test('parcelles: create then delete, scoped by potager', () async {
    final notifier = container.read(parcellesProvider('pot1').notifier);
    // The seeded parcelle par1 already belongs to pot1.
    final depart =
        (await container.read(parcellesProvider('pot1').future)).length;

    final p = await notifier.creer(
      nom: 'Bac tomates',
      type: TypeParcelle.bacSureleve,
      surface: Surface.enMetresCarres(2),
      exposition: NiveauSoleil.pleinSoleil,
    );
    final apres = await container.read(parcellesProvider('pot1').future);
    expect(apres, hasLength(depart + 1));
    expect(apres.map((e) => e.id), contains(p.id));

    await notifier.supprimer(p.id);
    final apresSuppr = await container.read(parcellesProvider('pot1').future);
    expect(apresSuppr, hasLength(depart));
    expect(apresSuppr.map((e) => e.id), isNot(contains(p.id)));
  });

  test('plantations: create scoped by parcelle', () async {
    final notifier = container.read(plantationsProvider('par1').notifier);
    final pl = await notifier.creer(
      planteId: 'basilic',
      dateMiseEnPlace: DateTime.utc(2026, 5, 15),
      methode: MethodeMiseEnPlace.semisDirect,
      surfaceOccupee: Surface.enMetresCarres(1),
      nombrePieds: 3,
    );
    final list = await container.read(plantationsProvider('par1').future);
    expect(list.map((e) => e.id), contains(pl.id));
  });

  test('recoltes: create scoped by plantation (past date)', () async {
    final notifier = container.read(recoltesProvider('pl1').notifier);
    await notifier.creer(
      date: DateTime.utc(2026, 5, 20),
      quantite: const Quantite(800, UniteQuantite.g),
    );
    expect(await container.read(recoltesProvider('pl1').future), hasLength(1));
  });

  test('observations: create then delete, scoped by target', () async {
    const scope = (cible: CibleObservation.plantation, cibleId: 'pl1');
    final notifier = container.read(observationsProvider(scope).notifier);
    final o = await notifier.creer(
      date: DateTime.utc(2026, 5, 20),
      type: TypeObservation.maladie,
      titre: 'Mildiou',
    );
    expect(await container.read(observationsProvider(scope).future), hasLength(1));
    await notifier.supprimer(o.id);
    expect(await container.read(observationsProvider(scope).future), isEmpty);
  });

  test('equipements: create then delete, scoped by potager', () async {
    final notifier = container.read(equipementsProvider('pot1').notifier);
    final e = await notifier.creer(
      nom: 'Oya 5L',
      type: TypeEquipement.oya,
      dateInstallation: DateTime.utc(2026, 4, 10),
    );
    expect(await container.read(equipementsProvider('pot1').future), hasLength(1));
    await notifier.supprimer(e.id);
    expect(await container.read(equipementsProvider('pot1').future), isEmpty);
  });

  test('taches: create then delete, scoped by target', () async {
    const scope = (cible: CibleTache.parcelle, cibleId: 'par1');
    final notifier = container.read(tachesProvider(scope).notifier);
    final t = await notifier.creer(
      titre: 'Arroser',
      type: TypeTache.arrosage,
      datePrevue: DateTime.utc(2026, 6, 10),
    );
    expect(await container.read(tachesProvider(scope).future), hasLength(1));
    await notifier.supprimer(t.id);
    expect(await container.read(tachesProvider(scope).future), isEmpty);
  });

  test('taches: modify via a domain method then persist', () async {
    const scope = (cible: CibleTache.parcelle, cibleId: 'par1');
    final notifier = container.read(tachesProvider(scope).notifier);
    final t = await notifier.creer(
      titre: 'Arroser',
      type: TypeTache.arrosage,
      datePrevue: DateTime.utc(2026, 6, 10),
    );
    expect(t.estFaite, isFalse);

    t.marquerFaite(DateTime.utc(2026, 6, 11));
    await notifier.modifier(t);

    final reloaded = await container.read(tachesProvider(scope).future);
    expect(reloaded.single.estFaite, isTrue);
    // Dates come back in local time (see `DateIso`) — compare instants.
    expect(
        reloaded.single.dateRealisation!
            .isAtSameMomentAs(DateTime.utc(2026, 6, 11)),
        isTrue);
  });

  test('equipements: modify (changerEtat) then persist', () async {
    final notifier = container.read(equipementsProvider('pot1').notifier);
    final e = await notifier.creer(
      nom: 'Oya 5L',
      type: TypeEquipement.oya,
      dateInstallation: DateTime.utc(2026, 4, 10),
    );

    e.changerEtat(EtatEquipement.aRemplacer);
    await notifier.modifier(e);

    final reloaded = await container.read(equipementsProvider('pot1').future);
    expect(reloaded.single.etat, EtatEquipement.aRemplacer);
  });

  test('recoltes: modify (definirQualite) then persist', () async {
    final notifier = container.read(recoltesProvider('pl1').notifier);
    final r = await notifier.creer(
      date: DateTime.utc(2026, 5, 20),
      quantite: const Quantite(800, UniteQuantite.g),
    );

    r.definirQualite(QualiteRecolte.excellente);
    await notifier.modifier(r);

    final reloaded = await container.read(recoltesProvider('pl1').future);
    expect(reloaded.single.qualite, QualiteRecolte.excellente);
  });

  test('rappels actifs: create then delete', () async {
    final notifier = container.read(rappelsActifsProvider.notifier);
    expect(await container.read(rappelsActifsProvider.future), isEmpty);

    final r = await notifier.creer(
      titre: 'Visite hebdo',
      typeTacheGeneree: TypeTache.observation,
      cible: CibleTache.potager,
      cibleId: 'pot1',
      dateDebut: DateTime.utc(2026, 5, 4),
      typeRecurrence: TypeRecurrence.hebdomadaire,
      joursSemaine: {JourSemaine.lundi, JourSemaine.jeudi},
    );
    expect(await container.read(rappelsActifsProvider.future), hasLength(1));

    await notifier.supprimer(r.id);
    expect(await container.read(rappelsActifsProvider.future), isEmpty);
  });
}
