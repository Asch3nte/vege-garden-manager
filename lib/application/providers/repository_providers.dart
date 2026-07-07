import 'package:riverpod/riverpod.dart';

import '../../domain/entities/fiche_plante.dart';
import '../../domain/repositories/abstract_bioagresseur_repository.dart';
import '../../domain/repositories/abstract_equipement_repository.dart';
import '../../domain/repositories/abstract_famille_botanique_repository.dart';
import '../../domain/repositories/abstract_fiche_plante_personnelle_repository.dart';
import '../../domain/repositories/abstract_fiche_plante_repository.dart';
import '../../domain/repositories/abstract_observation_repository.dart';
import '../../domain/repositories/abstract_parcelle_repository.dart';
import '../../domain/repositories/abstract_plantation_repository.dart';
import '../../domain/repositories/abstract_potager_repository.dart';
import '../../domain/repositories/abstract_preferences_repository.dart';
import '../../domain/repositories/abstract_rappel_repository.dart';
import '../../domain/repositories/abstract_recolte_repository.dart';
import '../../domain/repositories/abstract_tache_repository.dart';
import '../../infrastructure/catalogue/bioagresseur_asset_source.dart';
import '../../infrastructure/catalogue/bioagresseur_cache.dart';
import '../../infrastructure/catalogue/bioagresseurs_loader.dart';
import '../../infrastructure/catalogue/catalogue_loader.dart';
import '../../infrastructure/catalogue/famille_asset_source.dart';
import '../../infrastructure/catalogue/famille_botanique_cache.dart';
import '../../infrastructure/catalogue/familles_loader.dart';
import '../../infrastructure/catalogue/fiche_asset_source.dart';
import '../../infrastructure/catalogue/fiche_plante_cache.dart';
import '../../infrastructure/catalogue/fiches_personnelles_loader.dart';
import '../../infrastructure/repositories/bioagresseur_repository_impl.dart';
import '../../infrastructure/repositories/equipement_repository_impl.dart';
import '../../infrastructure/repositories/famille_botanique_repository_impl.dart';
import '../../infrastructure/repositories/fiche_plante_personnelle_repository_impl.dart';
import '../../infrastructure/repositories/fiche_plante_repository_impl.dart';
import '../../infrastructure/repositories/observation_repository_impl.dart';
import '../../infrastructure/repositories/parcelle_repository_impl.dart';
import '../../infrastructure/repositories/plantation_repository_impl.dart';
import '../../infrastructure/repositories/potager_repository_impl.dart';
import '../../infrastructure/repositories/preferences_repository_impl.dart';
import '../../infrastructure/repositories/rappel_repository_impl.dart';
import '../../infrastructure/repositories/recolte_repository_impl.dart';
import '../../infrastructure/repositories/tache_repository_impl.dart';
import 'database_providers.dart';

/// Dependency-injection providers for the domain repository interfaces.
///
/// Each provider exposes the **Domain abstraction**, backed by its drift
/// implementation. Tests override these with mocks (no Flutter, no real DB).

final potagerRepositoryProvider = Provider<AbstractPotagerRepository>(
  (ref) => PotagerRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final parcelleRepositoryProvider = Provider<AbstractParcelleRepository>(
  (ref) => ParcelleRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final plantationRepositoryProvider = Provider<AbstractPlantationRepository>(
  (ref) => PlantationRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final recolteRepositoryProvider = Provider<AbstractRecolteRepository>(
  (ref) => RecolteRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final observationRepositoryProvider = Provider<AbstractObservationRepository>(
  (ref) => ObservationRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final equipementRepositoryProvider = Provider<AbstractEquipementRepository>(
  (ref) => EquipementRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final tacheRepositoryProvider = Provider<AbstractTacheRepository>(
  (ref) => TacheRepositoryImpl(ref.watch(appDatabaseProvider)),
);

/// User-authored plant sheets (contribution feature, expert tier).
final fichePlantePersonnelleRepositoryProvider =
    Provider<AbstractFichePlantePersonnelleRepository>(
  (ref) =>
      FichePlantePersonnelleRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final rappelRepositoryProvider = Provider<AbstractRappelRepository>(
  (ref) => RappelRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final preferencesRepositoryProvider = Provider<AbstractPreferencesRepository>(
  (ref) => PreferencesRepositoryImpl(ref.watch(appDatabaseProvider)),
);

// --- Plant catalogue (YAML assets, loaded asynchronously) -------------------

/// Pipeline that lists/reads/parses/validates the embedded YAML plant sheets.
final catalogueLoaderProvider = Provider<CatalogueLoader>(
  (ref) => CatalogueLoader(BundleFicheAssetSource()),
);

/// Pipeline that loads user-authored sheets from the database (ADR-0002 A6).
final fichesPersonnellesLoaderProvider = Provider<FichesPersonnellesLoader>(
  (ref) => FichesPersonnellesLoader(
    ref.watch(fichePlantePersonnelleRepositoryProvider),
  ),
);

/// The user-authored sheets, parsed as catalogue entities. Invalidate this to
/// refresh the catalogue after a personal sheet is created/edited/deleted.
final fichesPersonnellesChargeesProvider = FutureProvider<List<FichePlante>>(
  (ref) => ref.watch(fichesPersonnellesLoaderProvider).charger(),
);

/// Logical ids of the loaded personal sheets — used to badge them in the
/// catalogue and to tell a personal sheet from a built-in one at a glance.
final idsFichesPersonnellesProvider = FutureProvider<Set<String>>(
  (ref) async => (await ref.watch(fichesPersonnellesChargeesProvider.future))
      .map((f) => f.id)
      .toSet(),
);

/// The in-memory plant-sheet cache: the bundled catalogue plus the user's own
/// sheets. Personal sheets are added last, so on an id collision they win
/// (ADR-0002 A6).
final fichePlanteCacheProvider = FutureProvider<FichePlanteCache>(
  (ref) async {
    final embarquees = await ref.watch(catalogueLoaderProvider).charger();
    final personnelles =
        await ref.watch(fichesPersonnellesChargeesProvider.future);
    return FichePlanteCache([...embarquees.toutes(), ...personnelles]);
  },
);

/// The plant-sheet repository. Async because it depends on the loaded cache.
final fichePlanteRepositoryProvider =
    FutureProvider<AbstractFichePlanteRepository>(
  (ref) async => FichePlanteRepositoryImpl(
    await ref.watch(fichePlanteCacheProvider.future),
  ),
);

// --- Botanical families (YAML assets, loaded asynchronously) — ADR-0006 ------

/// Pipeline that lists/reads/parses/validates the embedded YAML family sheets.
final famillesLoaderProvider = Provider<FamillesLoader>(
  (ref) => FamillesLoader(BundleFamilleAssetSource()),
);

/// The in-memory family cache, loaded once from the bundled assets.
final familleBotaniqueCacheProvider = FutureProvider<FamilleBotaniqueCache>(
  (ref) => ref.watch(famillesLoaderProvider).charger(),
);

/// The family repository. Async because it depends on the loaded cache.
final familleBotaniqueRepositoryProvider =
    FutureProvider<AbstractFamilleBotaniqueRepository>(
  (ref) async => FamilleBotaniqueRepositoryImpl(
    await ref.watch(familleBotaniqueCacheProvider.future),
  ),
);

/// Pipeline that reads/parses/validates the embedded bioaggressor reference
/// (diseases & pests shared at family level, ADR-0006 Lot 4).
final bioagresseursLoaderProvider = Provider<BioagresseursLoader>(
  (ref) => BioagresseursLoader(BundleBioagresseurAssetSource()),
);

/// The in-memory bioaggressor cache, loaded once from the bundled reference.
final bioagresseurCacheProvider = FutureProvider<BioagresseurCache>(
  (ref) => ref.watch(bioagresseursLoaderProvider).charger(),
);

/// The bioaggressor repository. Async because it depends on the loaded cache.
final bioagresseurRepositoryProvider =
    FutureProvider<AbstractBioagresseurRepository>(
  (ref) async => BioagresseurRepositoryImpl(
    await ref.watch(bioagresseurCacheProvider.future),
  ),
);
