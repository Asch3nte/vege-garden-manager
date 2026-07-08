import '../entities/famille_botanique.dart';
import '../enums/groupe_cultural.dart';

/// A cultural precedent referenced by a plant's `rotation` block: what was
/// grown *before* on a plot, expressed as either a botanical **family** (by its
/// normalized slug, e.g. `solanaceae`) or a functional **[GroupeCultural]**
/// (legumes, green manures) that does not reduce to a single family.
///
/// A precedent is *exactly one* of the two — never both, never neither.
///
/// ## Normalization (ADR — rotation avancée, Lot 1)
///
/// The sheet corpus carries spelling drift under `precedents_favorables` /
/// `precedents_defavorables`. [PrecedentCultural.analyser] absorbs it so the
/// rest of the model only ever sees canonical values:
///
/// | Raw token(s) | Parsed as |
/// |---|---|
/// | `legumineuses` | [GroupeCultural.legumineuses] |
/// | `engrais_verts`, `engrais_vert` | [GroupeCultural.engraisVerts] |
/// | `graminées` / `graminees` | family `poaceae` |
/// | `cucurbitacees` | family `cucurbitaceae` |
/// | `brassicacees` | family `brassicaceae` |
/// | `ail` | family `amaryllidaceae` |
/// | anything else | family (via [FamilleBotanique.normaliserCle]) |
///
/// Whether a family slug actually resolves to a loaded `_familles/*.yaml` sheet
/// is a **referential-integrity** concern checked in the infrastructure layer,
/// not here: [analyser] only normalizes the *shape* of the token.
///
/// UI labels are resolved by the presentation layer (i18n); this value object
/// exposes the raw slug / [GroupeCultural] only.
class PrecedentCultural {
  /// Non-null iff this precedent designates a botanical family.
  final String? _familleSlug;

  /// Non-null iff this precedent designates a functional group.
  final GroupeCultural? _groupe;

  const PrecedentCultural._(this._familleSlug, this._groupe)
      : assert((_familleSlug == null) != (_groupe == null),
            'a precedent is exactly one of family | group');

  /// A family precedent from an already-normalized [slug] (e.g. `solanaceae`).
  ///
  /// Prefer [analyser] for raw YAML tokens; this factory assumes [slug] is a
  /// clean lowercase family slug and only guards emptiness.
  factory PrecedentCultural.famille(String slug) {
    assert(slug.isNotEmpty, 'family slug must not be empty');
    return PrecedentCultural._(slug, null);
  }

  /// A functional-group precedent.
  const PrecedentCultural.groupe(GroupeCultural groupe)
      : this._(null, groupe);

  /// Functional tokens that map to a [GroupeCultural] rather than a family.
  static const Map<String, GroupeCultural> _groupes = {
    'legumineuses': GroupeCultural.legumineuses,
    'engrais_verts': GroupeCultural.engraisVerts,
    'engrais_vert': GroupeCultural.engraisVerts,
  };

  /// Known misspellings / common names mapped to a canonical family slug.
  static const Map<String, String> _aliasFamilles = {
    'graminees': 'poaceae',
    'cucurbitacees': 'cucurbitaceae',
    'brassicacees': 'brassicaceae',
    'ail': 'amaryllidaceae',
  };

  /// Parses a raw YAML precedent [token] into a typed precedent, absorbing the
  /// known spelling drift (see class doc). Returns `null` for a blank token so
  /// callers can silently skip empty list entries.
  static PrecedentCultural? analyser(String token) {
    // Compact form for lookups: lowercase, accent-free, separators unified to
    // a single underscore. Keeps underscores so `engrais_verts` stays intact.
    final compact = _compacter(token);
    if (compact.isEmpty) return null;

    final groupe = _groupes[compact];
    if (groupe != null) return PrecedentCultural.groupe(groupe);

    final alias = _aliasFamilles[compact];
    if (alias != null) return PrecedentCultural.famille(alias);

    return PrecedentCultural.famille(FamilleBotanique.normaliserCle(token));
  }

  /// Lowercases, strips accents, and collapses whitespace/hyphens into single
  /// underscores (trimming leading/trailing ones).
  static String _compacter(String token) {
    const accents = 'àâäáãåçèêëéìîïíòôöóõùûüú';
    const sans = 'aaaaaaceeeeiiiiooooouuuu';
    final buffer = StringBuffer();
    for (final rune in token.trim().toLowerCase().runes) {
      final c = String.fromCharCode(rune);
      if (c == ' ' || c == '-' || c == '_') {
        // Fold any run of separators into a single underscore.
        if (buffer.isNotEmpty &&
            buffer.toString().codeUnitAt(buffer.length - 1) != 0x5f) {
          buffer.write('_');
        }
        continue;
      }
      final i = accents.indexOf(c);
      buffer.write(i >= 0 ? sans[i] : c);
    }
    var out = buffer.toString();
    if (out.endsWith('_')) out = out.substring(0, out.length - 1);
    return out;
  }

  /// Whether this precedent designates a botanical family.
  bool get estFamille => _familleSlug != null;

  /// Whether this precedent designates a functional [GroupeCultural].
  bool get estGroupe => _groupe != null;

  /// The family slug when [estFamille], else `null`.
  String? get familleSlug => _familleSlug;

  /// The functional group when [estGroupe], else `null`.
  GroupeCultural? get groupe => _groupe;

  @override
  bool operator ==(Object other) =>
      other is PrecedentCultural &&
      other._familleSlug == _familleSlug &&
      other._groupe == _groupe;

  @override
  int get hashCode => Object.hash(_familleSlug, _groupe);

  @override
  String toString() => estFamille
      ? 'PrecedentCultural.famille($_familleSlug)'
      : 'PrecedentCultural.groupe(${_groupe!.name})';
}
