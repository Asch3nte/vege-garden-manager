import '../../domain/entities/famille_botanique.dart';
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
  final String? _familleSelectionnee;
  final List<FamilleBotanique> _familles;
  final List<GroupeFiche> _groupes;
  final List<FichePlante> _toutesMeres;
  final List<FichePlante> _toutesVarietes;

  CatalogueVue._(
    this._requete,
    this._categorie,
    this._familleSelectionnee,
    List<FamilleBotanique> familles,
    List<GroupeFiche> groupes,
    List<FichePlante> toutesMeres,
    List<FichePlante> toutesVarietes,
  )   : _familles = List.unmodifiable(familles),
        _groupes = List.unmodifiable(groupes),
        _toutesMeres = List.unmodifiable(toutesMeres),
        _toutesVarietes = List.unmodifiable(toutesVarietes);

  /// Builds a catalogue view. [toutesMeres] is every species (unfiltered, drives
  /// the count and the network view); [groupes] is the filtered, ordered result.
  /// [toutesVarietes] is every variety sheet, unfiltered (drives the in-sheet
  /// variety switcher). [familles] are the family chips for the selected
  /// category (empty under "Tout"); [familleSelectionnee] is the active family
  /// id, or `null`.
  factory CatalogueVue({
    required String requete,
    required CategoriePlante? categorie,
    required List<GroupeFiche> groupes,
    required List<FichePlante> toutesMeres,
    List<FichePlante> toutesVarietes = const [],
    String? familleSelectionnee,
    List<FamilleBotanique> familles = const [],
  }) =>
      CatalogueVue._(requete, categorie, familleSelectionnee, familles, groupes,
          toutesMeres, toutesVarietes);

  /// Current free-text query (as typed).
  String get requete => _requete;

  /// Selected category filter, or `null` for "Tout".
  CategoriePlante? get categorie => _categorie;

  /// Family chips to show under the selected category — the botanical families
  /// present among that category's species, ordered by localized name (ADR-0006).
  /// Empty when no category is selected.
  List<FamilleBotanique> get familles => _familles;

  /// Active family filter (a family id), or `null` for "Toutes les familles".
  String? get familleSelectionnee => _familleSelectionnee;

  /// Filtered species groups, in display order (immutable).
  List<GroupeFiche> get groupes => _groupes;

  /// Filtered species (mother sheets), flat and in display order (immutable).
  List<FichePlante> get fiches =>
      List.unmodifiable([for (final g in _groupes) g.mere]);

  /// Every species (mother sheets only), unfiltered — drives the network view.
  List<FichePlante> get toutesMeres => _toutesMeres;

  /// The varieties of the species [mereId], unfiltered and ordered by localized
  /// name — drives the in-sheet variety switcher (immutable, may be empty).
  List<FichePlante> varietesDe(String mereId) => List.unmodifiable([
        for (final v in _toutesVarietes)
          if (v.parentId == mereId) v,
      ]);

  /// The species (mother sheet) of [fiche]: itself when it is a species, else
  /// the mother it descends from, or `null` if the mother is unknown.
  FichePlante? mereDe(FichePlante fiche) {
    if (fiche.estMere) return fiche;
    for (final m in _toutesMeres) {
      if (m.id == fiche.parentId) return m;
    }
    return null;
  }

  /// Total number of species in the catalogue (before filtering).
  int get total => _toutesMeres.length;

  /// Number of species after filtering.
  int get nombreResultats => _groupes.length;

  /// Whether the current filters yield no result (drives the empty state).
  bool get sansResultat => _groupes.isEmpty;

  /// Whether any filter is active (query, category or family).
  bool get filtreActif =>
      _requete.trim().isNotEmpty ||
      _categorie != null ||
      _familleSelectionnee != null;
}
