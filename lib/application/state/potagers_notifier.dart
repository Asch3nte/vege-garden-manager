import 'package:riverpod/riverpod.dart';

import '../../domain/entities/potager.dart';
import '../../domain/enums/type_emplacement.dart';
import '../../domain/value_objects/localisation.dart';
import '../../domain/value_objects/zone_climatique.dart';
import '../providers/repository_providers.dart';
import '../use_cases/creer_potager.dart';

/// Exposes the list of potagers and the actions that mutate it to the UI.
///
/// State is the source of truth loaded from the repository; mutating actions
/// delegate to use cases, then reload the list so the UI reflects persistence.
class PotagersNotifier extends AsyncNotifier<List<Potager>> {
  @override
  Future<List<Potager>> build() {
    return ref.watch(potagerRepositoryProvider).obtenirTous();
  }

  /// Creates a potager and refreshes the list. Returns the created entity.
  Future<Potager> creer({
    required String nom,
    required ZoneClimatique zoneClimatique,
    TypeEmplacement emplacement = TypeEmplacement.jardin,
    Localisation localisation = const Localisation.nonDefinie(),
    String? notes,
  }) async {
    final potager = await ref.read(creerPotagerProvider).executer(
          nom: nom,
          zoneClimatique: zoneClimatique,
          emplacement: emplacement,
          localisation: localisation,
          notes: notes,
        );
    await _recharger();
    return potager;
  }

  /// Persists changes to an existing potager (upsert) and reloads the list.
  ///
  /// The caller mutates the entity through its domain methods first, then passes
  /// it here.
  Future<void> modifier(Potager potager) async {
    await ref.read(potagerRepositoryProvider).sauvegarder(potager);
    await _recharger();
  }

  /// Reloads the list from the repository, surfacing errors as an error state.
  Future<void> _recharger() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(potagerRepositoryProvider).obtenirTous(),
    );
  }
}

/// The potagers list provider.
final potagersProvider =
    AsyncNotifierProvider<PotagersNotifier, List<Potager>>(
  PotagersNotifier.new,
);
