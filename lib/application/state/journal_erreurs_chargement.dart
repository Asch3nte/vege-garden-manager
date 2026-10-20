import 'dart:developer' as developer;

import 'package:riverpod/riverpod.dart';

/// A file that failed to load, with the reason.
typedef ErreurChargement = ({String source, Object erreur});

/// Collects the catalogue files (plant, family and bioaggressor sheets) that
/// failed to load, so none is skipped silently.
class JournalErreursChargement {
  final List<ErreurChargement> _erreurs = [];

  /// Failures recorded so far (unmodifiable).
  List<ErreurChargement> get erreurs => List.unmodifiable(_erreurs);

  /// Records that [source] could not be loaded because of [erreur]; a reload
  /// replaces the previous entry of the same source.
  void signaler(String source, Object erreur) {
    _erreurs
      ..removeWhere((e) => e.source == source)
      ..add((source: source, erreur: erreur));
    developer.log('Skipped $source', name: 'catalogue', error: erreur);
  }
}

/// The load-error journal shared by every catalogue loader.
final journalErreursChargementProvider =
    Provider<JournalErreursChargement>((ref) => JournalErreursChargement());
