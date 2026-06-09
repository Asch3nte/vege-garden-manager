import '../../domain/entities/fiche_plante.dart';
import '../../domain/enums/categorie_plante.dart';

/// Immutable view-model for the **Catalogue** screen.
///
/// Holds the user's current filters (free-text [requete] and optional
/// [categorie]) and the already-filtered, display-ordered [fiches]. The list
/// carries the domain [FichePlante] entities directly — the screen reads their
/// real fields (name, category, water/sun needs, spacing, periods, companions);
/// no lossy projection is needed here.
class CatalogueVue {
  final String _requete;
  final CategoriePlante? _categorie;
  final List<FichePlante> _fiches;
  final int _total;

  CatalogueVue._(
    this._requete,
    this._categorie,
    List<FichePlante> fiches,
    this._total,
  ) : _fiches = List.unmodifiable(fiches);

  /// Builds a catalogue view. [total] is the unfiltered catalogue size (shown
  /// in the header); [fiches] is the filtered, ordered result.
  factory CatalogueVue({
    required String requete,
    required CategoriePlante? categorie,
    required List<FichePlante> fiches,
    required int total,
  }) =>
      CatalogueVue._(requete, categorie, fiches, total);

  /// Current free-text query (trimmed-or-not as typed).
  String get requete => _requete;

  /// Selected category filter, or `null` for "Tout".
  CategoriePlante? get categorie => _categorie;

  /// Filtered plant sheets, in display order (immutable).
  List<FichePlante> get fiches => _fiches;

  /// Total number of sheets in the catalogue (before filtering).
  int get total => _total;

  /// Number of sheets after filtering.
  int get nombreResultats => _fiches.length;

  /// Whether the current filters yield no result (drives the empty state).
  bool get sansResultat => _fiches.isEmpty;

  /// Whether any filter is active (query or category).
  bool get filtreActif => _requete.trim().isNotEmpty || _categorie != null;
}
