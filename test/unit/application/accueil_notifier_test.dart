import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/state/accueil_notifier.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/entities/tache.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/etat_tache.dart';
import 'package:pot_a_gerer/domain/enums/niveau_experience.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_preferences_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_tache_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';

class MockPotagers extends Mock implements AbstractPotagerRepository {}

class MockParcelles extends Mock implements AbstractParcelleRepository {}

class MockTaches extends Mock implements AbstractTacheRepository {}

class MockPreferences extends Mock implements AbstractPreferencesRepository {}

void main() {
  // Pinned "now" so the today-window is deterministic.
  final maintenant = DateTime(2026, 6, 9, 8, 24);

  late MockPotagers potagers;
  late MockParcelles parcelles;
  late MockTaches taches;
  late MockPreferences preferences;

  setUp(() {
    potagers = MockPotagers();
    parcelles = MockParcelles();
    taches = MockTaches();
    preferences = MockPreferences();
  });

  Potager unPotager() => Potager(
        id: 'pot-1',
        nom: 'Mon potager',
        zoneClimatique:
            const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
        dateCreation: DateTime(2026, 1, 1),
      );

  Parcelle uneParcelle(String id, String nom) => Parcelle(
        id: id,
        nom: nom,
        potagerId: 'pot-1',
        type: TypeParcelle.bacSureleve,
        surface: Surface.enMetresCarres(1),
        exposition: NiveauSoleil.pleinSoleil,
      );

  Tache uneTache(String id, String titre, EtatTache etat, DateTime quand) =>
      Tache(
        id: id,
        titre: titre,
        type: TypeTache.arrosage,
        cible: CibleTache.parcelle,
        cibleId: 'z-1',
        datePrevue: quand,
        etat: etat,
        // A completed task must carry a completion date (domain invariant).
        dateRealisation: etat == EtatTache.terminee ? quand : null,
      );

  /// Container with the four repos and the clock overridden.
  ProviderContainer conteneur() {
    final c = ProviderContainer(overrides: [
      potagerRepositoryProvider.overrideWithValue(potagers),
      parcelleRepositoryProvider.overrideWithValue(parcelles),
      tacheRepositoryProvider.overrideWithValue(taches),
      preferencesRepositoryProvider.overrideWithValue(preferences),
      horlogeProvider.overrideWithValue(() => maintenant),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('assembles garden name, zones, level and today\'s tasks', () async {
    when(() => preferences.charger()).thenAnswer(
      (_) async => PreferencesUtilisateur(
        niveauExperience: NiveauExperience.intermediaire,
      ),
    );
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => parcelles.obtenirParPotager('pot-1')).thenAnswer(
      (_) async => [uneParcelle('z-1', 'Carré nord'), uneParcelle('z-2', 'Serre')],
    );
    when(() => taches.obtenirEntreDates(any(), any())).thenAnswer(
      (_) async => [uneTache('t-1', 'Arroser', EtatTache.aFaire, maintenant)],
    );

    final vue = await conteneur().read(accueilProvider.future);

    expect(vue.nomPotager, 'Mon potager');
    expect(vue.niveau, NiveauExperience.intermediaire);
    expect(vue.zones.map((z) => z.nom), ['Carré nord', 'Serre']);
    expect(vue.nombreZones, 2);
    expect(vue.tachesDuJour, hasLength(1));
    expect(vue.nombreTachesAFaire, 1);
  });

  test('queries the task repo with today\'s [midnight, next midnight) window',
      () async {
    when(() => preferences.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => parcelles.obtenirParPotager(any())).thenAnswer((_) async => []);
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);

    await conteneur().read(accueilProvider.future);

    final captured =
        verify(() => taches.obtenirEntreDates(captureAny(), captureAny()))
            .captured;
    expect(captured[0], DateTime(2026, 6, 9));
    expect(captured[1], DateTime(2026, 6, 10));
  });

  test('orders tasks: undone before done, then by planned time', () async {
    when(() => preferences.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => parcelles.obtenirParPotager(any())).thenAnswer((_) async => []);
    when(() => taches.obtenirEntreDates(any(), any())).thenAnswer(
      (_) async => [
        uneTache('done', 'Fait', EtatTache.terminee, maintenant),
        uneTache('late', 'Tard', EtatTache.aFaire, DateTime(2026, 6, 9, 18)),
        uneTache('early', 'Tôt', EtatTache.aFaire, DateTime(2026, 6, 9, 7)),
      ],
    );

    final vue = await conteneur().read(accueilProvider.future);

    expect(vue.tachesDuJour.map((t) => t.id), ['early', 'late', 'done']);
  });

  test('season statistics are visible only at expert level', () async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => parcelles.obtenirParPotager(any())).thenAnswer((_) async => []);
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);

    for (final (niveau, attendu) in [
      (NiveauExperience.debutant, false),
      (NiveauExperience.intermediaire, false),
      (NiveauExperience.expert, true),
    ]) {
      when(() => preferences.charger()).thenAnswer(
        (_) async => PreferencesUtilisateur(niveauExperience: niveau),
      );
      final vue = await conteneur().read(accueilProvider.future);
      expect(vue.statistiquesVisibles, attendu, reason: niveau.name);
    }
  });

  test('no active garden → empty overview, null name', () async {
    when(() => preferences.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());
    when(() => potagers.obtenirPotagerActif()).thenAnswer((_) async => null);
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);

    final vue = await conteneur().read(accueilProvider.future);

    expect(vue.nomPotager, isNull);
    expect(vue.zones, isEmpty);
    expect(vue.potagerVide, isTrue);
    // The parcelle repo is never queried without an active garden.
    verifyNever(() => parcelles.obtenirParPotager(any()));
  });
}
