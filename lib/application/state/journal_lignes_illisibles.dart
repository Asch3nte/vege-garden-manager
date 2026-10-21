import 'package:riverpod/riverpod.dart';

/// Database rows set aside because they no longer form a valid entity; they
/// are kept untouched in the database.
class JournalLignesIllisibles {
  final Set<String> _lignes = {};

  /// Number of distinct unreadable rows met so far.
  int get nombre => _lignes.length;

  /// Records the unreadable row [id] of [table].
  void signaler(String table, String id, Object erreur) =>
      _lignes.add('$table/$id');
}

/// The journal shared by every repository.
final journalLignesIllisiblesProvider =
    Provider<JournalLignesIllisibles>((ref) => JournalLignesIllisibles());
