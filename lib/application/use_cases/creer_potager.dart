import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/potager.dart';
import '../../domain/enums/type_emplacement.dart';
import '../../domain/repositories/abstract_potager_repository.dart';
import '../../domain/value_objects/localisation.dart';
import '../../domain/value_objects/zone_climatique.dart';
import '../providers/repository_providers.dart';

/// Use case: create a new potager.
///
/// Generates the entity's UUID app-side (IDs are never assigned by the
/// database) and persists it. The id generator is injectable so creation is
/// deterministic under test.
class CreerPotager {
  final AbstractPotagerRepository _repo;
  final String Function() _genererId;

  CreerPotager(this._repo, {String Function()? genererId})
      : _genererId = genererId ?? _uuid;

  static String _uuid() => const Uuid().v4();

  /// Builds, persists and returns the new potager.
  Future<Potager> executer({
    required String nom,
    required ZoneClimatique zoneClimatique,
    TypeEmplacement emplacement = TypeEmplacement.jardin,
    Localisation localisation = const Localisation.nonDefinie(),
    String? notes,
  }) async {
    final potager = Potager(
      id: _genererId(),
      nom: nom,
      zoneClimatique: zoneClimatique,
      dateCreation: DateTime.now(),
      emplacement: emplacement,
      localisation: localisation,
      notes: notes,
    );
    await _repo.sauvegarder(potager);
    return potager;
  }
}

/// DI provider for [CreerPotager], wired to the potager repository.
final creerPotagerProvider = Provider<CreerPotager>(
  (ref) => CreerPotager(ref.watch(potagerRepositoryProvider)),
);
