import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/plantation.dart';
import '../../domain/enums/methode_mise_en_place.dart';
import '../../domain/repositories/abstract_plantation_repository.dart';
import '../../domain/value_objects/surface.dart';
import '../providers/repository_providers.dart';

/// Use case: plant a culture in a parcelle.
///
/// Generates the UUID app-side (injectable for tests) and persists the entity.
class CreerPlantation {
  final AbstractPlantationRepository _repo;
  final String Function() _genererId;

  CreerPlantation(this._repo, {String Function()? genererId})
      : _genererId = genererId ?? _uuid;

  static String _uuid() => const Uuid().v4();

  Future<Plantation> executer({
    required String planteId,
    required String parcelleId,
    required DateTime dateMiseEnPlace,
    required MethodeMiseEnPlace methode,
    required Surface surfaceOccupee,
    required int nombrePieds,
  }) async {
    final plantation = Plantation(
      id: _genererId(),
      planteId: planteId,
      parcelleId: parcelleId,
      dateMiseEnPlace: dateMiseEnPlace,
      methode: methode,
      surfaceOccupee: surfaceOccupee,
      nombrePieds: nombrePieds,
    );
    await _repo.sauvegarder(plantation);
    return plantation;
  }
}

/// DI provider for [CreerPlantation].
final creerPlantationProvider = Provider<CreerPlantation>(
  (ref) => CreerPlantation(ref.watch(plantationRepositoryProvider)),
);
