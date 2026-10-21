import 'package:riverpod/riverpod.dart';

import '../../domain/entities/bioagresseur.dart';
import '../../domain/entities/famille_botanique.dart';
import '../../domain/entities/fiche_plante.dart';
import '../../domain/repositories/abstract_bioagresseur_repository.dart';
import '../../domain/repositories/abstract_equipement_repository.dart';
import '../../domain/repositories/abstract_famille_botanique_repository.dart';
import '../../domain/repositories/abstract_favori_repository.dart';
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
import 'non_branche.dart';

/// Domain repository ports. Their implementations are bound by the
/// composition root; tests override them with doubles.

final potagerRepositoryProvider = Provider<AbstractPotagerRepository>(
  (ref) => nonBranche('potagerRepositoryProvider'),
);

final parcelleRepositoryProvider = Provider<AbstractParcelleRepository>(
  (ref) => nonBranche('parcelleRepositoryProvider'),
);

final plantationRepositoryProvider = Provider<AbstractPlantationRepository>(
  (ref) => nonBranche('plantationRepositoryProvider'),
);

final recolteRepositoryProvider = Provider<AbstractRecolteRepository>(
  (ref) => nonBranche('recolteRepositoryProvider'),
);

final observationRepositoryProvider = Provider<AbstractObservationRepository>(
  (ref) => nonBranche('observationRepositoryProvider'),
);

final equipementRepositoryProvider = Provider<AbstractEquipementRepository>(
  (ref) => nonBranche('equipementRepositoryProvider'),
);

final tacheRepositoryProvider = Provider<AbstractTacheRepository>(
  (ref) => nonBranche('tacheRepositoryProvider'),
);

/// User-authored plant sheets (contribution feature, expert tier).
final fichePlantePersonnelleRepositoryProvider =
    Provider<AbstractFichePlantePersonnelleRepository>(
  (ref) => nonBranche('fichePlantePersonnelleRepositoryProvider'),
);

final rappelRepositoryProvider = Provider<AbstractRappelRepository>(
  (ref) => nonBranche('rappelRepositoryProvider'),
);

final preferencesRepositoryProvider = Provider<AbstractPreferencesRepository>(
  (ref) => nonBranche('preferencesRepositoryProvider'),
);

final favoriRepositoryProvider = Provider<AbstractFavoriRepository>(
  (ref) => nonBranche('favoriRepositoryProvider'),
);

// --- Plant catalogue ---------------------------------------------------------

/// The user-authored sheets, parsed as catalogue entities. Invalidate this to
/// refresh the catalogue after a personal sheet is created/edited/deleted.
final fichesPersonnellesChargeesProvider = FutureProvider<List<FichePlante>>(
  (ref) => nonBranche('fichesPersonnellesChargeesProvider'),
);

/// Logical ids of the loaded personal sheets — used to badge them in the
/// catalogue and to tell a personal sheet from a built-in one at a glance.
final idsFichesPersonnellesProvider = FutureProvider<Set<String>>(
  (ref) async => (await ref.watch(fichesPersonnellesChargeesProvider.future))
      .map((f) => f.id)
      .toSet(),
);

/// The plant-sheet repository: the bundled catalogue plus the user's sheets.
final fichePlanteRepositoryProvider =
    FutureProvider<AbstractFichePlanteRepository>(
  (ref) => nonBranche('fichePlanteRepositoryProvider'),
);

// --- Botanical families and bioaggressors -----------------------------------

final familleBotaniqueRepositoryProvider =
    FutureProvider<AbstractFamilleBotaniqueRepository>(
  (ref) => nonBranche('familleBotaniqueRepositoryProvider'),
);

/// Every botanical family by id, for synchronous lookups.
final famillesParIdProvider = FutureProvider<Map<String, FamilleBotanique>>(
  (ref) async => {
    for (final f in await (await ref.watch(
      familleBotaniqueRepositoryProvider.future,
    ))
        .obtenirToutes())
      f.id: f,
  },
);

final bioagresseurRepositoryProvider =
    FutureProvider<AbstractBioagresseurRepository>(
  (ref) => nonBranche('bioagresseurRepositoryProvider'),
);

/// Every bioaggressor by id, for synchronous lookups.
final bioagresseursParIdProvider = FutureProvider<Map<String, Bioagresseur>>(
  (ref) async => {
    for (final b in await (await ref.watch(
      bioagresseurRepositoryProvider.future,
    ))
        .obtenirTous())
      b.id: b,
  },
);
