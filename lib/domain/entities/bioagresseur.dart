import '../enums/type_bioagresseur.dart';

/// A disease or pest shared at the **botanical-family** level, loaded from the
/// embedded reference and **not created by the user** (ADR-0006, Lot 4).
///
/// It normalizes the free-form slugs that family sheets list under
/// `maladies_communes` / `ravageurs_communs`: each such slug must resolve to a
/// `Bioagresseur` here (referential integrity, like a species' `rotation.famille`
/// must resolve to a family sheet).
///
/// Immutable catalogue **entity**, identity by [id] (the normalized slug, e.g.
/// `mildiou`). Domain names are kept in French; the code is documented in
/// English. See ADR-0006.
class Bioagresseur {
  final String _id;
  final TypeBioagresseur _type;
  final Map<String, String> _nomsLocalises;
  final Map<String, String> _descriptionsLocalisees;
  final String? _codeEppo;

  Bioagresseur._(
    this._id,
    this._type,
    this._nomsLocalises,
    this._descriptionsLocalisees,
    this._codeEppo,
  )   : assert(_id.isNotEmpty, 'id must not be empty'),
        assert(_id == _id.toLowerCase(), 'id must be a normalized slug'),
        assert(_nomsLocalises.containsKey('fr'), 'the French name is mandatory'),
        assert(_codeEppo == null || _codeEppo.isNotEmpty,
            'codeEppo, when set, must not be empty');

  /// Builds a bioaggressor entry. Maps are stored unmodifiable.
  factory Bioagresseur({
    required String id,
    required TypeBioagresseur type,
    required Map<String, String> nomsLocalises,
    Map<String, String>? descriptionsLocalisees,
    String? codeEppo,
  }) =>
      Bioagresseur._(
        id,
        type,
        Map<String, String>.unmodifiable(nomsLocalises),
        Map<String, String>.unmodifiable(
            descriptionsLocalisees ?? const <String, String>{}),
        codeEppo,
      );

  /// Canonical slug for a bioaggressor name: lowercased, accent-stripped, with
  /// spaces and hyphens turned into underscores and apostrophes dropped
  /// (`Mouche de la carotte` → `mouche_de_la_carotte`, `Œil de paon` →
  /// `oeil_de_paon`). This is the entry [id] and the key a family references
  /// through `maladies_communes` / `ravageurs_communs`.
  static String normaliserSlug(String nom) {
    const accents = 'àâäáãåçèêëéìîïíòôöóõùûüú';
    const sans = 'aaaaaaceeeeiiiiooooouuuu';
    final buffer = StringBuffer();
    for (final rune in nom.trim().toLowerCase().runes) {
      final c = String.fromCharCode(rune);
      if (c == ' ' || c == '-' || c == '_') {
        buffer.write('_');
        continue;
      }
      if (c == 'œ' || c == 'æ') {
        buffer.write(c == 'œ' ? 'oe' : 'ae');
        continue;
      }
      if (c == "'" || c == '’') continue;
      final i = accents.indexOf(c);
      buffer.write(i >= 0 ? sans[i] : c);
    }
    return buffer.toString();
  }

  /// Normalized slug id (e.g. `mildiou`).
  String get id => _id;

  /// Whether this is a disease or a pest.
  TypeBioagresseur get type => _type;

  /// Stable EPPO Global Database code in cross-reference, or `null` if unknown.
  String? get codeEppo => _codeEppo;

  /// Localized common names (`fr` always present, unmodifiable).
  Map<String, String> get nomsLocalises => _nomsLocalises;

  /// Common name for [locale], falling back to French (always present).
  String nomLocalise(String locale) =>
      _nomsLocalises[locale] ?? _nomsLocalises['fr']!;

  /// Short description for [locale] (falls back to French), or `null` if the
  /// reference carries none yet.
  String? descriptionLocalisee(String locale) =>
      _descriptionsLocalisees[locale] ?? _descriptionsLocalisees['fr'];

  @override
  bool operator ==(Object other) =>
      other is Bioagresseur && other._id == _id;

  @override
  int get hashCode => _id.hashCode;

  @override
  String toString() => 'Bioagresseur($_id, $_type)';
}
