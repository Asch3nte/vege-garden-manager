import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:pot_a_gerer/application/providers/horloge_provider.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/providers/service_providers.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/entities/tache.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/etat_tache.dart';
import 'package:pot_a_gerer/domain/enums/priorite_tache.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_meteo_service.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_plantation_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_preferences_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_tache_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';
import 'package:pot_a_gerer/presentation/providers/notifications_accueil_provider.dart';

class _MockTaches extends Mock implements AbstractTacheRepository {}

class _MockPotagers extends Mock implements AbstractPotagerRepository {}

class _MockPreferences extends Mock implements AbstractPreferencesRepository {}

class _MockParcelles extends Mock implements AbstractParcelleRepository {}

class _MockPlantations extends Mock implements AbstractPlantationRepository {}

class _MockMeteo extends Mock implements AbstractMeteoService {}

class _FakeLoc extends Fake implements Localisation {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeLoc()));

  late _MockTaches taches;
  late _MockPotagers potagers;
  late _MockPreferences preferences;
  late _MockParcelles parcelles;
  late _MockPlantations plantations;
  late _MockMeteo meteo;

  final maintenant = DateTime(2026, 6, 9, 8);

  setUp(() {
    taches = _MockTaches();
    potagers = _MockPotagers();
    preferences = _MockPreferences();
    parcelles = _MockParcelles();
    plantations = _MockPlantations();
    meteo = _MockMeteo();
    when(() => preferences.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());
    when(() => potagers.obtenirPotagerActif()).thenAnswer((_) async => null);
    when(() => parcelles.obtenirParPotager(any())).thenAnswer((_) async => []);
    when(() => plantations.obtenirParParcelle(any())).thenAnswer((_) async => []);
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);
  });

  Tache tache(String id, PrioriteTache priorite, {bool faite = false}) => Tache(
        id: id,
        titre: id,
        type: TypeTache.arrosage,
        cible: CibleTache.potager,
        cibleId: 'pot-1',
        datePrevue: maintenant,
        priorite: priorite,
        etat: faite ? EtatTache.terminee : EtatTache.aFaire,
        dateRealisation: faite ? maintenant : null,
      );

  ProviderContainer conteneur() {
    final c = ProviderContainer(overrides: [
      horlogeProvider.overrideWithValue(() => maintenant),
      tacheRepositoryProvider.overrideWithValue(taches),
      potagerRepositoryProvider.overrideWithValue(potagers),
      preferencesRepositoryProvider.overrideWithValue(preferences),
      parcelleRepositoryProvider.overrideWithValue(parcelles),
      plantationRepositoryProvider.overrideWithValue(plantations),
      meteoServiceProvider.overrideWithValue(meteo),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  Potager unPotager() => Potager(
        id: 'pot-1',
        nom: 'Mon potager',
        zoneClimatique:
            const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
        dateCreation: DateTime(2026, 1, 1),
        localisation: Localisation.gps(latitude: 48.85, longitude: 2.35),
      );

  test('keeps only today\'s undone urgent tasks', () async {
    when(() => taches.obtenirEntreDates(any(), any())).thenAnswer((_) async => [
          tache('urgente-a-faire', PrioriteTache.urgente),
          tache('normale', PrioriteTache.normale),
          tache('urgente-faite', PrioriteTache.urgente, faite: true),
        ]);

    final vue = await conteneur().read(notificationsAccueilProvider.future);

    expect(vue.tachesUrgentes.map((t) => t.id), ['urgente-a-faire']);
    expect(vue.alertes, isEmpty); // no active garden
  });

  test('automatic weather off → no alert and no forecast call', () async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => preferences.charger()).thenAnswer(
      (_) async => PreferencesUtilisateur(meteoAutoActive: false),
    );

    final vue = await conteneur().read(notificationsAccueilProvider.future);

    expect(vue.alertes, isEmpty);
    verifyNever(() => meteo.obtenirPrevisions(any(), any()));
  });
}
