import 'package:riverpod/riverpod.dart';

import '../providers/repository_providers.dart';

/// The user's favourite plant sheet ids, and the action that toggles one.
class FavorisNotifier extends AsyncNotifier<Set<String>> {
  final Set<String> _enCours = {};

  @override
  Future<Set<String>> build() =>
      ref.watch(favoriRepositoryProvider).obtenirIds();

  /// Adds [ficheId] to the favourites, or removes it if already there.
  ///
  /// A toggle of the same sheet still in flight is ignored, so a double tap
  /// does not cancel itself out. On a failed write the state is reloaded from
  /// the base, then the error is rethrown for the caller to report.
  Future<void> basculer(String ficheId) async {
    if (!_enCours.add(ficheId)) return;
    final repo = ref.read(favoriRepositoryProvider);
    try {
      final actuels = await future;
      if (actuels.contains(ficheId)) {
        await repo.retirer(ficheId);
      } else {
        await repo.ajouter(ficheId);
      }
    } finally {
      _enCours.remove(ficheId);
      state = await AsyncValue.guard(repo.obtenirIds);
    }
  }
}

/// Favourite plant sheet ids.
final favorisProvider = AsyncNotifierProvider<FavorisNotifier, Set<String>>(
  FavorisNotifier.new,
);
