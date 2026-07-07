import 'package:riverpod/riverpod.dart';

import '../../domain/entities/fiche_plante_personnelle.dart';
import '../../domain/value_objects/modele_fiche_personnelle.dart';
import '../providers/repository_providers.dart';
import '../use_cases/creer_fiche_personnelle.dart';
import '../use_cases/modifier_fiche_personnelle.dart';

/// Exposes the user's own plant sheets and the actions that mutate them.
///
/// After every write the notifier reloads its own list **and** invalidates the
/// catalogue's personal-sheet load ([fichesPersonnellesChargeesProvider]), so a
/// create/edit/delete is reflected immediately in the catalogue and its badges.
class FichesPersonnellesNotifier
    extends AsyncNotifier<List<FichePlantePersonnelle>> {
  @override
  Future<List<FichePlantePersonnelle>> build() =>
      ref.watch(fichePlantePersonnelleRepositoryProvider).obtenirToutes();

  /// Creates a sheet from [contenu] and returns the stored entity.
  Future<FichePlantePersonnelle> creer(ModeleFichePersonnelle contenu) async {
    final fiche = await ref
        .read(creerFichePersonnelleProvider)
        .executer(contenu: contenu);
    await _rafraichir();
    return fiche;
  }

  /// Updates [existante] with [contenu] and returns the updated entity.
  Future<FichePlantePersonnelle> modifier({
    required FichePlantePersonnelle existante,
    required ModeleFichePersonnelle contenu,
  }) async {
    final maj = await ref
        .read(modifierFichePersonnelleProvider)
        .executer(existante: existante, contenu: contenu);
    await _rafraichir();
    return maj;
  }

  /// Soft-deletes the sheet with storage [id].
  Future<void> supprimer(String id) async {
    await ref.read(fichePlantePersonnelleRepositoryProvider).supprimer(id);
    await _rafraichir();
  }

  Future<void> _rafraichir() async {
    ref.invalidate(fichesPersonnellesChargeesProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(fichePlantePersonnelleRepositoryProvider).obtenirToutes(),
    );
  }
}

/// The user's own plant sheets, most recently modified first.
final fichesPersonnellesProvider = AsyncNotifierProvider<
    FichesPersonnellesNotifier, List<FichePlantePersonnelle>>(
  FichesPersonnellesNotifier.new,
);
