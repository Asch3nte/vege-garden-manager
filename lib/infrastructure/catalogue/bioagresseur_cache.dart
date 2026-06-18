import '../../domain/entities/bioagresseur.dart';
import '../../domain/enums/type_bioagresseur.dart';

/// In-memory store of the loaded bioaggressors, indexed by id (the normalized
/// slug) for instant lookup (ADR-0006, Lot 4).
class BioagresseurCache {
  final Map<String, Bioagresseur> _parId;

  BioagresseurCache(Iterable<Bioagresseur> bioagresseurs)
      : _parId = {for (final b in bioagresseurs) b.id: b};

  /// Number of cached bioaggressors.
  int get nombre => _parId.length;

  /// All bioaggressors (unmodifiable).
  List<Bioagresseur> tous() => List.unmodifiable(_parId.values);

  /// Bioaggressor with [id], or `null` if absent.
  Bioagresseur? parId(String id) => _parId[id];

  /// Bioaggressors of the given [type].
  List<Bioagresseur> parType(TypeBioagresseur type) =>
      _parId.values.where((b) => b.type == type).toList();
}
