import '../enums/categorie_plante.dart';

/// Botanical family reference, loaded from the YAML catalogue and **not created
/// by the user**. A *sibling* type of [FichePlante] — **not** a grand-mother in
/// the species/variety inheritance chain (ADR-0006): a family carries neither
/// growing needs nor cycle nor periods, only its identity and family-level
/// editorial/agronomic notes.
///
/// Serves two purposes: catalogue filtering (a category reveals its families)
/// and education (shared rotation/pests/companion rationale).
///
/// `FamilleBotanique` is an immutable catalogue **entity** (identity by [id],
/// the normalized scientific family name, e.g. `solanaceae`). Domain names are
/// kept in French; the code is documented in English. See ADR-0006.
class FamilleBotanique {
  final String _id;
  final String _nomScientifique;
  final Set<CategoriePlante> _categories;
  final Map<String, String> _nomsLocalises;
  final Map<String, String> _descriptionsLocalisees;
  final Map<String, String> _pourquoiRotationLocalise;
  final Map<String, String> _ennemisCommunsNoteLocalisee;
  final Map<String, String> _associationsNoteLocalisee;
  final Set<String> _maladiesCommunes;
  final Set<String> _ravageursCommuns;
  final int? _delaiRetourAnnees;

  FamilleBotanique._(
    this._id,
    this._nomScientifique,
    this._categories,
    this._nomsLocalises,
    this._descriptionsLocalisees,
    this._pourquoiRotationLocalise,
    this._ennemisCommunsNoteLocalisee,
    this._associationsNoteLocalisee,
    this._maladiesCommunes,
    this._ravageursCommuns,
    this._delaiRetourAnnees,
  )   : assert(_id.isNotEmpty, 'id must not be empty'),
        assert(_id == _id.toLowerCase(), 'id must be a normalized slug'),
        assert(_nomScientifique.isNotEmpty, 'nomScientifique must not be empty'),
        assert(_categories.isNotEmpty, 'a family must belong to ≥ 1 category'),
        assert(_nomsLocalises.containsKey('fr'), 'the French name is mandatory'),
        assert(
          _delaiRetourAnnees == null || _delaiRetourAnnees > 0,
          'delaiRetourAnnees, when set, must be > 0',
        );

  /// Builds a family sheet. Collections are stored unmodifiable; the structured
  /// agronomic fields default to empty/`null`.
  factory FamilleBotanique({
    required String id,
    required String nomScientifique,
    required Set<CategoriePlante> categories,
    required Map<String, String> nomsLocalises,
    Map<String, String>? descriptionsLocalisees,
    Map<String, String>? pourquoiRotationLocalise,
    Map<String, String>? ennemisCommunsNoteLocalisee,
    Map<String, String>? associationsNoteLocalisee,
    Set<String>? maladiesCommunes,
    Set<String>? ravageursCommuns,
    int? delaiRetourAnnees,
  }) =>
      FamilleBotanique._(
        id,
        nomScientifique,
        Set<CategoriePlante>.unmodifiable(categories),
        Map<String, String>.unmodifiable(nomsLocalises),
        Map<String, String>.unmodifiable(
            descriptionsLocalisees ?? const <String, String>{}),
        Map<String, String>.unmodifiable(
            pourquoiRotationLocalise ?? const <String, String>{}),
        Map<String, String>.unmodifiable(
            ennemisCommunsNoteLocalisee ?? const <String, String>{}),
        Map<String, String>.unmodifiable(
            associationsNoteLocalisee ?? const <String, String>{}),
        Set<String>.unmodifiable(maladiesCommunes ?? const <String>{}),
        Set<String>.unmodifiable(ravageursCommuns ?? const <String>{}),
        delaiRetourAnnees,
      );

  /// Canonical link key for a family: the scientific family name lowercased,
  /// stripped of accents and whitespace (`Solanaceae` → `solanaceae`,
  /// `Amaryllidaceae ` → `amaryllidaceae`). This is the family [id] and the key
  /// a species references through its `rotation.famille` (ADR-0006).
  static String normaliserCle(String nomFamille) {
    const accents = 'àâäáãåçèêëéìîïíòôöóõùûüú';
    const sans = 'aaaaaaceeeeiiiiooooouuuu';
    final buffer = StringBuffer();
    for (final rune in nomFamille.trim().toLowerCase().runes) {
      final c = String.fromCharCode(rune);
      if (c == ' ' || c == '-' || c == '_') continue;
      final i = accents.indexOf(c);
      buffer.write(i >= 0 ? sans[i] : c);
    }
    return buffer.toString();
  }

  /// Normalized slug id (e.g. `solanaceae`).
  String get id => _id;

  /// Latin family name (e.g. `Solanaceae`).
  String get nomScientifique => _nomScientifique;

  /// Project categories where this family is relevant (immutable, non-empty).
  Set<CategoriePlante> get categories => _categories;

  /// Localized common names (`fr` always present, unmodifiable).
  Map<String, String> get nomsLocalises => _nomsLocalises;

  /// Diseases commonly shared across the family (slugs, unmodifiable).
  Set<String> get maladiesCommunes => _maladiesCommunes;

  /// Pests commonly shared across the family (slugs, unmodifiable).
  Set<String> get ravageursCommuns => _ravageursCommuns;

  /// Family-level crop-rotation return delay in years, or `null` if unspecified.
  int? get delaiRetourAnnees => _delaiRetourAnnees;

  /// Common name for [locale], falling back to French (always present).
  String nomLocalise(String locale) =>
      _nomsLocalises[locale] ?? _nomsLocalises['fr']!;

  /// Short description for [locale] (falls back to French), or `null` if the
  /// sheet carries none.
  String? descriptionLocalisee(String locale) =>
      _descriptionsLocalisees[locale] ?? _descriptionsLocalisees['fr'];

  /// Educational note explaining *why* this family demands its crop rotation
  /// (ADR-0006 Lot 4) for [locale] (falls back to French), or `null` if absent.
  String? pourquoiRotation(String locale) =>
      _pourquoiRotationLocalise[locale] ?? _pourquoiRotationLocalise['fr'];

  /// Educational note on the diseases/pests shared across the family for
  /// [locale] (falls back to French), or `null` if absent.
  String? ennemisCommunsNote(String locale) =>
      _ennemisCommunsNoteLocalisee[locale] ?? _ennemisCommunsNoteLocalisee['fr'];

  /// Educational note on why some associations work at the family level for
  /// [locale] (falls back to French), or `null` if absent.
  String? associationsNote(String locale) =>
      _associationsNoteLocalisee[locale] ?? _associationsNoteLocalisee['fr'];

  /// Whether this family is relevant to [categorie] (drives the catalogue
  /// family filter row).
  bool estPertinentePour(CategoriePlante categorie) =>
      _categories.contains(categorie);

  @override
  bool operator ==(Object other) =>
      other is FamilleBotanique && other._id == _id;

  @override
  int get hashCode => _id.hashCode;

  @override
  String toString() => 'FamilleBotanique($_id)';
}
