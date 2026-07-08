import 'package:riverpod/riverpod.dart';

import '../../domain/entities/fiche_plante_personnelle.dart';
import '../../domain/repositories/abstract_fiche_plante_personnelle_repository.dart';
import '../../domain/value_objects/modele_fiche_personnelle.dart';
import '../providers/repository_providers.dart';

/// Use case: update the content of an existing user-authored sheet.
///
/// The logical id ([FichePlantePersonnelle.idFiche]) is **preserved** across
/// edits so catalogue cross-references (and the sheet's identity in views) stay
/// stable — any `idFiche` carried by the incoming [contenu] is ignored. The
/// modification timestamp is stamped app-side (injectable for tests).
class ModifierFichePersonnelle {
  final AbstractFichePlantePersonnelleRepository _repo;
  final DateTime Function() _maintenant;

  ModifierFichePersonnelle(
    this._repo, {
    DateTime Function()? maintenant,
  }) : _maintenant = maintenant ?? DateTime.now;

  /// Persists [contenu] onto [existante] and returns the updated entity.
  Future<FichePlantePersonnelle> executer({
    required FichePlantePersonnelle existante,
    required ModeleFichePersonnelle contenu,
  }) async {
    final fige = contenu.idFiche == existante.idFiche
        ? contenu
        : contenu.copyWith(idFiche: existante.idFiche);
    final maj = existante.avecContenu(fige, _maintenant());
    await _repo.sauvegarder(maj);
    return maj;
  }
}

/// DI provider for [ModifierFichePersonnelle].
final modifierFichePersonnelleProvider = Provider<ModifierFichePersonnelle>(
  (ref) => ModifierFichePersonnelle(
      ref.watch(fichePlantePersonnelleRepositoryProvider)),
);
