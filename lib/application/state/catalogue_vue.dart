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
  final List<FichePlante> _toutes;

  CatalogueVue._(
    this._requete,
    this._categorie,
    List<FichePlante> fiches,
    List<FichePlante> toutes,
  )   : _fiches = List.unmodifiable(fiches),
        _toutes = List.unmodifiable(toutes);

  /// Builds a catalogue view. [toutes] is the unfiltered catalogue (used for the
  /// header count and the network view); [fiches] is the filtered, ordered result.
  factory CatalogueVue({
    required String requete,
    required CategoriePlante? categorie,
    required List<FichePlante> fiches,
    required List<FichePlante> toutes,
  }) =>
      CatalogueVue._(requete, categorie, fiches, toutes);

  /// Current free-text query (trimmed-or-not as typed).
  String get requete => _requete;

  /// Selected category filter, or `null` for "Tout".
  CategoriePlante? get categorie => _categorie;

  /// Filtered plant sheets, in display order (immutable).
  List<FichePlante> get fiches => _fiches;

  /// The whole catalogue, unfiltered (immutable) — drives the network view.
  List<FichePlante> get toutes => _toutes;

  /// Total number of sheets in the catalogue (before filtering).
  int get total => _toutes.length;

  /// Number of sheets after filtering.
  int get nombreResultats => _fiches.length;

  /// Whether the current filters yield no result (drives the empty state).
  bool get sansResultat => _fiches.isEmpty;

  /// Whether any filter is active (query or category).
  bool get filtreActif => _requete.trim().isNotEmpty || _categorie != null;
}
