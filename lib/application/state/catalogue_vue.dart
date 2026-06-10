import '../../domain/entities/fiche_plante.dart';
import '../../domain/enums/categorie_plante.dart';

/// A species (mother sheet) with its varieties (daughter sheets), as shown in
/// the catalogue list — the mother is the row, its varieties expand below it
/// (ADR-0005).
class GroupeFiche {
  final FichePlante _mere;
  final List<FichePlante> _varietes;

  GroupeFiche._(this._mere, this._varietes);

  /// Builds a group; [varietes] is stored unmodifiable.
  factory GroupeFiche({
    required FichePlante mere,
    required List<FichePlante> varietes,
  }) =>
      GroupeFiche._(mere, List.unmodifiable(varietes));

  /// The species sheet.
  FichePlante get mere => _mere;

  /// The species' varieties shown under it (immutable, may be empty).
  List<FichePlante> get varietes => _varietes;

  /// Whether the species has any variety to expand.
  bool get aVarietes => _varietes.isNotEmpty;
}

/// Immutable view-model for the **Catalogue** screen.
///
/// Holds the user's current filters (free-text [requete] and optional
/// [categorie]) and the already-filtered, display-ordered species [groupes]
/// (each mother sheet with its varieties). Entities are carried directly — the
/// screen reads their real fields; no lossy projection is needed.
class CatalogueVue {
  final String _requete;
  final CategoriePlante? _categorie;
  final List<GroupeFiche> _groupes;
  final List<FichePlante> _toutesMeres;

  CatalogueVue._(
    this._requete,
    this._categorie,
    List<GroupeFiche> groupes,
    List<FichePlante> toutesMeres,
  )   : _groupes = List.unmodifiable(groupes),
        _toutesMeres = List.unmodifiable(toutesMeres);

  /// Builds a catalogue view. [toutesMeres] is every species (unfiltered, drives
  /// the count and the network view); [groupes] is the filtered, ordered result.
  factory CatalogueVue({
    required String requete,
    required CategoriePlante? categorie,
    required List<GroupeFiche> groupes,
    required List<FichePlante> toutesMeres,
  }) =>
      CatalogueVue._(requete, categorie, groupes, toutesMeres);

  /// Current free-text query (as typed).
  String get requete => _requete;

  /// Selected category filter, or `null` for "Tout".
  CategoriePlante? get categorie => _categorie;

  /// Filtered species groups, in display order (immutable).
  List<GroupeFiche> get groupes => _groupes;

  /// Filtered species (mother sheets), flat and in display order (immutable).
  List<FichePlante> get fiches =>
      List.unmodifiable([for (final g in _groupes) g.mere]);

  /// Every species (mother sheets only), unfiltered — drives the network view.
  List<FichePlante> get toutesMeres => _toutesMeres;

  /// Total number of species in the catalogue (before filtering).
  int get total => _toutesMeres.length;

  /// Number of species after filtering.
  int get nombreResultats => _groupes.length;

  /// Whether the current filters yield no result (drives the empty state).
  bool get sansResultat => _groupes.isEmpty;

  /// Whether any filter is active (query or category).
  bool get filtreActif => _requete.trim().isNotEmpty || _categorie != null;
}
