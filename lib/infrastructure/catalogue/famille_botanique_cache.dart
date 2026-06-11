import '../../domain/entities/famille_botanique.dart';
import '../../domain/enums/categorie_plante.dart';

/// In-memory store of the loaded botanical families, indexed by id (the
/// normalized scientific name) for instant lookup (ADR-0006).
class FamilleBotaniqueCache {
  final Map<String, FamilleBotanique> _parId;

  FamilleBotaniqueCache(Iterable<FamilleBotanique> familles)
      : _parId = {for (final f in familles) f.id: f};

  /// Number of cached families.
  int get nombre => _parId.length;

  /// All families (unmodifiable).
  List<FamilleBotanique> toutes() => List.unmodifiable(_parId.values);

  /// Family with [id], or `null` if absent.
  FamilleBotanique? parId(String id) => _parId[id];

  /// Families declared relevant to [categorie].
  List<FamilleBotanique> parCategorie(CategoriePlante categorie) => _parId
      .values
      .where((f) => f.estPertinentePour(categorie))
      .toList();
}
