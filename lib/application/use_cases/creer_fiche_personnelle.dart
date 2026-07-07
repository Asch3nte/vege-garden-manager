import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/fiche_plante_personnelle.dart';
import '../../domain/repositories/abstract_fiche_plante_personnelle_repository.dart';
import '../../domain/value_objects/modele_fiche_personnelle.dart';
import '../providers/repository_providers.dart';

/// Use case: persist a new user-authored plant sheet.
///
/// Assigns the storage UUID app-side and guarantees the logical id
/// ([ModeleFichePersonnelle.idFiche]) is unique among personal sheets, appending
/// a numeric suffix on collision. Both the id generator and the clock are
/// injectable for tests.
class CreerFichePersonnelle {
  final AbstractFichePlantePersonnelleRepository _repo;
  final String Function() _genererId;
  final DateTime Function() _maintenant;

  CreerFichePersonnelle(
    this._repo, {
    String Function()? genererId,
    DateTime Function()? maintenant,
  })  : _genererId = genererId ?? _uuid,
        _maintenant = maintenant ?? DateTime.now;

  static String _uuid() => const Uuid().v4();

  /// Creates and persists the sheet described by [contenu], returning the stored
  /// entity (with its final, collision-free logical id).
  Future<FichePlantePersonnelle> executer({
    required ModeleFichePersonnelle contenu,
  }) async {
    final idUnique = await _idFicheUnique(contenu.idFiche);
    final maintenant = _maintenant();
    final fiche = FichePlantePersonnelle(
      id: _genererId(),
      contenu: idUnique == contenu.idFiche
          ? contenu
          : contenu.copyWith(idFiche: idUnique),
      dateCreation: maintenant,
    );
    await _repo.sauvegarder(fiche);
    return fiche;
  }

  /// Returns [base] if free, otherwise `base_2`, `base_3`… until unused.
  Future<String> _idFicheUnique(String base) async {
    var candidat = base;
    var n = 2;
    while (await _repo.obtenirParIdFiche(candidat) != null) {
      candidat = '${base}_${n++}';
    }
    return candidat;
  }
}

/// DI provider for [CreerFichePersonnelle].
final creerFichePersonnelleProvider = Provider<CreerFichePersonnelle>(
  (ref) =>
      CreerFichePersonnelle(ref.watch(fichePlantePersonnelleRepositoryProvider)),
);
