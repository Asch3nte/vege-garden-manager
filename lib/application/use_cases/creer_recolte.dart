import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/recolte.dart';
import '../../domain/enums/destination_recolte.dart';
import '../../domain/enums/qualite_recolte.dart';
import '../../domain/repositories/abstract_recolte_repository.dart';
import '../../domain/value_objects/quantite.dart';
import '../providers/repository_providers.dart';

/// Use case: record a harvest on a plantation.
///
/// Generates the UUID app-side (injectable for tests) and persists the entity.
class CreerRecolte {
  final AbstractRecolteRepository _repo;
  final String Function() _genererId;

  CreerRecolte(this._repo, {String Function()? genererId})
      : _genererId = genererId ?? _uuid;

  static String _uuid() => const Uuid().v4();

  Future<Recolte> executer({
    required String plantationId,
    required DateTime date,
    required Quantite quantite,
    DestinationRecolte destination = DestinationRecolte.consommationFraiche,
    QualiteRecolte? qualite,
    String? notes,
  }) async {
    final recolte = Recolte(
      id: _genererId(),
      plantationId: plantationId,
      date: date,
      quantite: quantite,
      destination: destination,
      qualite: qualite,
      notes: notes,
    );
    await _repo.sauvegarder(recolte);
    return recolte;
  }
}

/// DI provider for [CreerRecolte].
final creerRecolteProvider = Provider<CreerRecolte>(
  (ref) => CreerRecolte(ref.watch(recolteRepositoryProvider)),
);
