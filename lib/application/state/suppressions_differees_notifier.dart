import 'dart:async';
import 'dart:developer' as developer;

import 'package:riverpod/riverpod.dart';

/// Erases an item from the database once its deletion can no longer be undone,
/// resolving once the lists showing it have reloaded without it.
typedef Effacement = Future<void> Function(Ref ref);

/// Ids of the items deleted from a list whose erasure is still pending.
///
/// Nothing is erased before [delai] has passed, so cancelling only drops the
/// pending erasure.
class SuppressionsDiffereesNotifier extends Notifier<Set<String>> {
  /// How long a deletion stays undoable.
  static const Duration delaiParDefaut = Duration(seconds: 5);

  final Duration delai;
  final Map<String, (Timer, Effacement)> _attentes = {};

  SuppressionsDiffereesNotifier([this.delai = delaiParDefaut]);

  @override
  Set<String> build() {
    ref.onDispose(() {
      for (final (minuteur, _) in _attentes.values) {
        minuteur.cancel();
      }
      _attentes.clear();
    });
    return const {};
  }

  /// Hides [id] now and runs [effacer] once [delai] has passed; an id
  /// already pending or being erased is left as is.
  void programmer(String id, Effacement effacer) {
    if (state.contains(id)) return;
    _attentes[id] = (Timer(delai, () => unawaited(valider(id))), effacer);
    state = Set.unmodifiable({...state, id});
  }

  /// Drops the pending erasure of [id]; false once it has started.
  bool annuler(String id) {
    final attente = _attentes.remove(id);
    if (attente == null) return false;
    attente.$1.cancel();
    _retirer(id);
    return true;
  }

  /// Erases [id] now; a failure logs and brings the item back.
  Future<void> valider(String id) async {
    final attente = _attentes.remove(id);
    if (attente == null) return;
    attente.$1.cancel();
    try {
      await attente.$2(ref);
    } on Exception catch (e) {
      developer.log('Deferred deletion of $id failed',
          name: 'suppression', error: e);
    } finally {
      if (ref.mounted) _retirer(id);
    }
  }

  /// Erases every pending item now.
  Future<void> toutValider() =>
      Future.wait([for (final id in [..._attentes.keys]) valider(id)]);

  void _retirer(String id) =>
      state = Set.unmodifiable({...state}..remove(id));
}

/// Items deleted from a list, still restorable for a few seconds.
final suppressionsDiffereesProvider =
    NotifierProvider<SuppressionsDiffereesNotifier, Set<String>>(
        SuppressionsDiffereesNotifier.new);
