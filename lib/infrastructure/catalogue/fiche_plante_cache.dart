import '../../domain/entities/fiche_plante.dart';
import '../../domain/enums/categorie_plante.dart';
import '../../domain/enums/usage_plante.dart';

/// In-memory store of the loaded plant sheets, indexed by id for instant access.
///
/// Pipeline step 5 (see `docs/07-base-de-connaissances-yaml.md` §6). On a
/// duplicate id the last sheet wins (personal sheets, loaded after the embedded
/// ones, take precedence — ADR-0002 A6).
class FichePlanteCache {
  final Map<String, FichePlante> _parId;

  FichePlanteCache(Iterable<FichePlante> fiches)
      : _parId = {for (final f in fiches) f.id: f};

  /// Number of cached sheets.
  int get nombre => _parId.length;

  /// All sheets (unmodifiable).
  List<FichePlante> toutes() => List.unmodifiable(_parId.values);

  /// Sheet with [id], or `null` if absent.
  FichePlante? parId(String id) => _parId[id];

  /// Sheets of a given [categorie].
  List<FichePlante> parCategorie(CategoriePlante categorie) =>
      _parId.values.where((f) => f.categorie == categorie).toList();

  /// Sheets carrying a given [usage].
  List<FichePlante> parUsage(UsagePlante usage) =>
      _parId.values.where((f) => f.aUsage(usage)).toList();

  /// Sheets whose localized name (in [locale]) or id contains [terme]
  /// (case-insensitive).
  List<FichePlante> rechercher(String terme, String locale) {
    final t = terme.trim().toLowerCase();
    if (t.isEmpty) return toutes();
    return _parId.values
        .where((f) =>
            f.nomLocalise(locale).toLowerCase().contains(t) ||
            f.id.toLowerCase().contains(t))
        .toList();
  }
}
