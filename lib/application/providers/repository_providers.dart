import 'package:riverpod/riverpod.dart';

import '../../domain/repositories/abstract_equipement_repository.dart';
import '../../domain/repositories/abstract_fiche_plante_repository.dart';
import '../../domain/repositories/abstract_observation_repository.dart';
import '../../domain/repositories/abstract_parcelle_repository.dart';
import '../../domain/repositories/abstract_plantation_repository.dart';
import '../../domain/repositories/abstract_potager_repository.dart';
import '../../domain/repositories/abstract_preferences_repository.dart';
import '../../domain/repositories/abstract_rappel_repository.dart';
import '../../domain/repositories/abstract_recolte_repository.dart';
import '../../domain/repositories/abstract_tache_repository.dart';
import '../../infrastructure/catalogue/catalogue_loader.dart';
import '../../infrastructure/catalogue/fiche_asset_source.dart';
import '../../infrastructure/catalogue/fiche_plante_cache.dart';
import '../../infrastructure/repositories/equipement_repository_impl.dart';
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

/// The in-memory plant-sheet cache, loaded once from the bundled assets.
final fichePlanteCacheProvider = FutureProvider<FichePlanteCache>(
  (ref) => ref.watch(catalogueLoaderProvider).charger(),
);

/// The plant-sheet repository. Async because it depends on the loaded cache.
final fichePlanteRepositoryProvider =
    FutureProvider<AbstractFichePlanteRepository>(
  (ref) async => FichePlanteRepositoryImpl(
    await ref.watch(fichePlanteCacheProvider.future),
  ),
);
