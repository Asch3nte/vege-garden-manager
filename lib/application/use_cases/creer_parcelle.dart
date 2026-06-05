import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/parcelle.dart';
import '../../domain/enums/niveau_soleil.dart';
import '../../domain/enums/ph_sol.dart';
import '../../domain/enums/source_type_sol.dart';
import '../../domain/enums/technique_sol.dart';
import '../../domain/enums/texture_sol.dart';
import '../../domain/enums/type_parcelle.dart';
import '../../domain/repositories/abstract_parcelle_repository.dart';
import '../../domain/value_objects/surface.dart';
import '../providers/repository_providers.dart';

/// Use case: create a parcelle in a potager.
///
/// Generates the UUID app-side (injectable for tests) and persists the entity.
class CreerParcelle {
  final AbstractParcelleRepository _repo;
  final String Function() _genererId;

  CreerParcelle(this._repo, {String Function()? genererId})
      : _genererId = genererId ?? _uuid;

  static String _uuid() => const Uuid().v4();

  Future<Parcelle> executer({
    required String nom,
    required String potagerId,
    required TypeParcelle type,
    required Surface surface,
    required NiveauSoleil exposition,
    int ordre = 0,
    TextureSol? texture,
    SourceTypeSol textureSource = SourceTypeSol.manuelle,
    PhSol? ph,
    Set<TechniqueSol>? techniquesSol,
    bool cultureVerticale = false,
    String? notes,
  }) async {
    final parcelle = Parcelle(
      id: _genererId(),
      nom: nom,
      potagerId: potagerId,
      type: type,
      surface: surface,
      exposition: exposition,
      ordre: ordre,
      texture: texture,
      textureSource: textureSource,
      ph: ph,
      techniquesSol: techniquesSol,
      cultureVerticale: cultureVerticale,
      notes: notes,
    );
    await _repo.sauvegarder(parcelle);
    return parcelle;
  }
}

/// DI provider for [CreerParcelle].
final creerParcelleProvider = Provider<CreerParcelle>(
  (ref) => CreerParcelle(ref.watch(parcelleRepositoryProvider)),
);
