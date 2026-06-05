import 'package:riverpod/riverpod.dart';

import '../../domain/entities/equipement.dart';
import '../../domain/enums/etat_equipement.dart';
import '../../domain/enums/type_equipement.dart';
import '../providers/repository_providers.dart';
import '../use_cases/creer_equipement.dart';

/// Exposes the equipment of a given potager and the actions that mutate it.
///
/// Family-scoped by `potagerId`.
class EquipementsNotifier extends AsyncNotifier<List<Equipement>> {
  EquipementsNotifier(this.potagerId);

  /// The potager whose equipment this notifier exposes (family argument).
  final String potagerId;

  @override
  Future<List<Equipement>> build() {
    return ref.watch(equipementRepositoryProvider).obtenirParPotager(potagerId);
  }

  Future<Equipement> creer({
    required String nom,
    required TypeEquipement type,
    required DateTime dateInstallation,
    String? parcelleId,
    EtatEquipement etat = EtatEquipement.bon,
    String? marqueModele,
    DateTime? dateRemplacementPrevue,
    String? notes,
  }) async {
    final equipement = await ref.read(creerEquipementProvider).executer(
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
    await _recharger();
    return equipement;
  }

  Future<void> supprimer(String id) async {
    await ref.read(equipementRepositoryProvider).supprimer(id);
    await _recharger();
  }

  /// Persists changes to an existing equipment (upsert) and reloads the list.
  /// The caller mutates the entity through its domain methods first
  /// (e.g. `changerEtat`, `retirer`).
  Future<void> modifier(Equipement equipement) async {
    await ref.read(equipementRepositoryProvider).sauvegarder(equipement);
    await _recharger();
  }

  Future<void> _recharger() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () =>
          ref.read(equipementRepositoryProvider).obtenirParPotager(potagerId),
    );
  }
}

/// Equipment of a potager, keyed by `potagerId`.
final equipementsProvider = AsyncNotifierProvider.family<EquipementsNotifier,
    List<Equipement>, String>(
  EquipementsNotifier.new,
);
