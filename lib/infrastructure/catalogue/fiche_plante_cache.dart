import '../../domain/entities/fiche_plante.dart';
import '../../domain/enums/categorie_plante.dart';
import '../../domain/enums/usage_plante.dart';
import '../../domain/services/comparateur_noms.dart';

/// In-memory store of the loaded plant sheets, indexed by id for instant access.
///
/// Pipeline step 5. On a
/// duplicate id the last sheet wins (personal sheets, loaded after the embedded
/// ones, take precedence).
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

  /// Mother sheets only — species level, varieties excluded. The
  /// list and network catalogue views build on this.
  List<FichePlante> meres() =>
      List.unmodifiable(_parId.values.where((f) => f.estMere));

  /// Variety sheets whose parent species is [idMere].
  List<FichePlante> varietesDe(String idMere) =>
      List.unmodifiable(_parId.values.where((f) => f.parentId == idMere));

  /// Sheets of a given [categorie].
  List<FichePlante> parCategorie(CategoriePlante categorie) =>
      List.unmodifiable(_parId.values.where((f) => f.categorie == categorie));

  /// Sheets carrying a given [usage].
  List<FichePlante> parUsage(UsagePlante usage) =>
      List.unmodifiable(_parId.values.where((f) => f.aUsage(usage)));

  /// Sheets whose localized name (in [locale]) or id contains [terme]
  /// (case- and accent-insensitive).
  List<FichePlante> rechercher(String terme, String locale) {
    const comparateur = ComparateurNoms();
    final t = comparateur.replier(terme.trim());
    if (t.isEmpty) return toutes();
    return List.unmodifiable(_parId.values.where((f) =>
        comparateur.replier(f.nomLocalise(locale)).contains(t) ||
        f.id.toLowerCase().contains(t)));
  }
}
