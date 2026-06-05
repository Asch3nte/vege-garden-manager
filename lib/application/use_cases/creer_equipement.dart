import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/equipement.dart';
import '../../domain/enums/etat_equipement.dart';
import '../../domain/enums/type_equipement.dart';
import '../../domain/repositories/abstract_equipement_repository.dart';
import '../providers/repository_providers.dart';

/// Use case: register an equipment in a potager (optionally on a parcelle).
///
/// Generates the UUID app-side (injectable for tests) and persists the entity.
class CreerEquipement {
  final AbstractEquipementRepository _repo;
  final String Function() _genererId;

  CreerEquipement(this._repo, {String Function()? genererId})
      : _genererId = genererId ?? _uuid;

  static String _uuid() => const Uuid().v4();

  Future<Equipement> executer({
    required String nom,
    required String potagerId,
    required TypeEquipement type,
    required DateTime dateInstallation,
    String? parcelleId,
    EtatEquipement etat = EtatEquipement.bon,
    String? marqueModele,
    DateTime? dateRemplacementPrevue,
    String? notes,
  }) async {
    final equipement = Equipement(
      id: _genererId(),
      nom: nom,
      potagerId: potagerId,
      type: type,
      dateInstallation: dateInstallation,
      parcelleId: parcelleId,
      etat: etat,
      marqueModele: marqueModele,
      dateRemplacementPrevue: dateRemplacementPrevue,
      notes: notes,
    );
    await _repo.sauvegarder(equipement);
    return equipement;
  }
}

/// DI provider for [CreerEquipement].
final creerEquipementProvider = Provider<CreerEquipement>(
  (ref) => CreerEquipement(ref.watch(equipementRepositoryProvider)),
);
