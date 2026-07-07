import '../../domain/entities/bioagresseur.dart';
import '../../domain/entities/famille_botanique.dart';

/// A typed additional block a term page renders below the definition
/// (ADR-0017, D3). Blocks carry **derived data only** — the page never invents
/// content: an absent block simply doesn't render.
///
/// Sealed so the term page can switch exhaustively; adding a block kind is a
/// compile error until every renderer handles it.
sealed class ComplementTerme {
  const ComplementTerme();
}

/// Family block: the full [FamilleBotanique] entity (same source as the plant
/// sheet's `_SectionFamille` — single source, never copied) plus the glossary
/// term ids of its shared diseases/pests, resolved so the page can render
/// **clickable** chips.
class ComplementFamille extends ComplementTerme {
  final FamilleBotanique _famille;
  final List<String> _idsMaladies;
  final List<String> _idsRavageurs;

  ComplementFamille._(this._famille, this._idsMaladies, this._idsRavageurs);

  /// Builds the block; id lists are stored unmodifiable.
  factory ComplementFamille({
    required FamilleBotanique famille,
    required List<String> idsMaladies,
    required List<String> idsRavageurs,
  }) =>
      ComplementFamille._(
        famille,
        List<String>.unmodifiable(idsMaladies),
        List<String>.unmodifiable(idsRavageurs),
      );

  /// The family entity (identity, editorial notes, rotation delay…).
  FamilleBotanique get famille => _famille;

  /// Glossary term ids of the family's shared diseases (unmodifiable).
  List<String> get idsMaladies => _idsMaladies;

  /// Glossary term ids of the family's shared pests (unmodifiable).
  List<String> get idsRavageurs => _idsRavageurs;
}

/// Bioaggressor block: the [Bioagresseur] entity plus the glossary term ids of
/// the **families that reference it** (inverse derivation), so the page can
/// link back to every concerned family.
class ComplementBioagresseur extends ComplementTerme {
  final Bioagresseur _bioagresseur;
  final List<String> _idsFamilles;

  ComplementBioagresseur._(this._bioagresseur, this._idsFamilles);

  /// Builds the block; the family id list is stored unmodifiable.
  factory ComplementBioagresseur({
    required Bioagresseur bioagresseur,
    required List<String> idsFamilles,
  }) =>
      ComplementBioagresseur._(
        bioagresseur,
        List<String>.unmodifiable(idsFamilles),
      );

  /// The bioaggressor entity (type, EPPO code…).
  Bioagresseur get bioagresseur => _bioagresseur;

  /// Glossary term ids of the families sharing this bioaggressor (unmodifiable).
  List<String> get idsFamilles => _idsFamilles;
}

/// One described value of an enum-backed notion (label + optional description,
/// both already localized).
typedef ValeurDecrite = ({String libelle, String? description});

/// Enum-values block: the list of an enum's values with their existing
/// descriptions (reuses `LibellesEnums.*Description` — D3), for notion pages
/// that explain a scale (soil pH, water needs…).
class ComplementValeursEnum extends ComplementTerme {
  final List<ValeurDecrite> _valeurs;

  /// Builds the block; the value list is stored unmodifiable and non-empty.
  ComplementValeursEnum({required List<ValeurDecrite> valeurs})
      : assert(valeurs.isNotEmpty, 'an enum block must carry >= 1 value'),
        _valeurs = List<ValeurDecrite>.unmodifiable(valeurs);

  /// The described values, in display order (unmodifiable).
  List<ValeurDecrite> get valeurs => _valeurs;
}

/// Provenance block of an association-mechanism page (ADR-0017, annexe A):
/// whether the mechanism can be **computed by the engine** (a derivation rule
/// exists in `MoteurDerivationAssociations`) or is only **documented by the
/// permaculture community** (curated pairs from the YAML sheets).
///
/// The flag is always derived from the engine's own rule inventory
/// (`beneficesDerivables` / `conflitsDerivables`) — never set by hand.
class ComplementProvenanceMecanisme extends ComplementTerme {
  final bool _calculeParMoteur;

  const ComplementProvenanceMecanisme._(this._calculeParMoteur);

  /// Builds the block from the engine-derived flag.
  factory ComplementProvenanceMecanisme({required bool calculeParMoteur}) =>
      ComplementProvenanceMecanisme._(calculeParMoteur);

  /// `true` when a derivation rule exists for this mechanism.
  bool get calculeParMoteur => _calculeParMoteur;
}

/// « Voir aussi » block: explicit cross-references to related terms.
class ComplementVoirAussi extends ComplementTerme {
  final List<String> _ids;

  /// Builds the block; the id list is stored unmodifiable and non-empty.
  ComplementVoirAussi({required List<String> ids})
      : assert(ids.isNotEmpty, 'a see-also block must carry >= 1 id'),
        _ids = List<String>.unmodifiable(ids);

  /// Glossary term ids to link to (unmodifiable).
  List<String> get ids => _ids;
}
