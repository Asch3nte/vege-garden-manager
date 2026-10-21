import 'package:riverpod/riverpod.dart';

import '../providers/repository_providers.dart';

/// The user's favourite plant sheet ids, and the action that toggles one.
class FavorisNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() =>
      ref.watch(favoriRepositoryProvider).obtenirIds();

  /// Adds [ficheId] to the favourites, or removes it if already there.
  Future<void> basculer(String ficheId) async {
    final repo = ref.read(favoriRepositoryProvider);
    final actuels = await future;
    if (actuels.contains(ficheId)) {
      await repo.retirer(ficheId);
    } else {
      await repo.ajouter(ficheId);
    }
    state = AsyncData(await repo.obtenirIds());
  }
}

/// Favourite plant sheet ids.
final favorisProvider = AsyncNotifierProvider<FavorisNotifier, Set<String>>(
  FavorisNotifier.new,
);
