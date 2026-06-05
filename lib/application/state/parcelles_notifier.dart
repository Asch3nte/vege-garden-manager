import 'package:riverpod/riverpod.dart';

import '../../domain/entities/parcelle.dart';
import '../../domain/enums/niveau_soleil.dart';
import '../../domain/enums/ph_sol.dart';
import '../../domain/enums/source_type_sol.dart';
import '../../domain/enums/technique_sol.dart';
import '../../domain/enums/texture_sol.dart';
import '../../domain/enums/type_parcelle.dart';
import '../../domain/value_objects/surface.dart';
import '../providers/repository_providers.dart';
import '../use_cases/creer_parcelle.dart';

/// Exposes the parcelles of a given potager and the actions that mutate them.
///
/// Family-scoped by `potagerId`. Mutating actions delegate to use cases, then
/// reload so the UI reflects persistence.
class ParcellesNotifier extends AsyncNotifier<List<Parcelle>> {
  ParcellesNotifier(this.potagerId);

  /// The potager whose parcelles this notifier exposes (family argument).
  final String potagerId;

  @override
  Future<List<Parcelle>> build() {
    return ref.watch(parcelleRepositoryProvider).obtenirParPotager(potagerId);
  }

  Future<Parcelle> creer({
    required String nom,
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
    final parcelle = await ref.read(creerParcelleProvider).executer(
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
    await _recharger();
    return parcelle;
  }

  Future<void> supprimer(String id) async {
    await ref.read(parcelleRepositoryProvider).supprimer(id);
    await _recharger();
  }

  Future<void> _recharger() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(parcelleRepositoryProvider).obtenirParPotager(potagerId),
    );
  }
}

/// Parcelles of a potager, keyed by `potagerId`.
final parcellesProvider =
    AsyncNotifierProvider.family<ParcellesNotifier, List<Parcelle>, String>(
  ParcellesNotifier.new,
);
