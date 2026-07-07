import 'chapitre_glossaire.dart';
import 'complement_terme.dart';
import 'type_terme_glossaire.dart';

/// One entry of the « Aide & lexique » glossary (ADR-0017, D1).
///
/// Immutable Presentation model with **already-localized** strings: instances
/// are built by `construireGlossaire` (registre) from the YAML references
/// (families, bioaggressors) and the static notion catalogue — never persisted,
/// never user-created.
///
/// [definition] and [conseils] may embed wiki links (`[[id]]` /
/// `[[id|texte]]`, D2) resolved at render time by `analyserLiensGlossaire`.
class TermeGlossaire {
  final String _id;
  final ChapitreGlossaire _chapitre;
  final TypeTermeGlossaire _type;
  final String _titre;
  final String _definition;
  final List<String> _conseils;
  final String? _astuce;
  final String? _illustration;
  final List<ComplementTerme> _complements;

  TermeGlossaire._(
    this._id,
    this._chapitre,
    this._type,
    this._titre,
    this._definition,
    this._conseils,
    this._astuce,
    this._illustration,
    this._complements,
  )   : assert(_id.isNotEmpty, 'id must not be empty'),
        assert(_id.contains('.'), 'id must be prefixed (e.g. "notion.<slug>")'),
        assert(_titre.isNotEmpty, 'titre must not be empty'),
        assert(_definition.isNotEmpty, 'definition must not be empty'),
        assert(_astuce == null || _astuce.isNotEmpty,
            'astuce, when set, must not be empty'),
        assert(_illustration == null || _illustration.isNotEmpty,
            'illustration, when set, must not be empty');

  /// Builds a glossary term. Collections are stored unmodifiable.
  factory TermeGlossaire({
    required String id,
    required ChapitreGlossaire chapitre,
    required TypeTermeGlossaire type,
    required String titre,
    required String definition,
    List<String>? conseils,
    String? astuce,
    String? illustration,
    List<ComplementTerme>? complements,
  }) =>
      TermeGlossaire._(
        id,
        chapitre,
        type,
        titre,
        definition,
        List<String>.unmodifiable(conseils ?? const <String>[]),
        astuce,
        illustration,
        List<ComplementTerme>.unmodifiable(
            complements ?? const <ComplementTerme>[]),
      );

  // --- Id scheme -----------------------------------------------------------
  //
  // Term ids are `<source>.<slug>` so ids from different references can never
  // collide and a wiki link `[[famille.solanaceae]]` reads unambiguously.

  /// Glossary id of a botanical family (`famille.<family slug>`).
  static String idFamille(String slug) => 'famille.$slug';

  /// Glossary id of a disease/pest (`bio.<bioaggressor slug>`).
  static String idBioagresseur(String slug) => 'bio.$slug';

  /// Glossary id of a tool page (`outil.<slug>`).
  static String idOutil(String slug) => 'outil.$slug';

  /// Glossary id of any other notion (`notion.<slug>`).
  static String idNotion(String slug) => 'notion.$slug';

  /// Unique prefixed id (e.g. `famille.solanaceae`, `outil.oya`).
  String get id => _id;

  /// The book chapter this term is filed under.
  ChapitreGlossaire get chapitre => _chapitre;

  /// The term kind — drives its colour everywhere (D5).
  TypeTermeGlossaire get type => _type;

  /// Localized display name.
  String get titre => _titre;

  /// Localized main paragraph (may embed wiki links).
  String get definition => _definition;

  /// Localized usage advice, possibly empty (unmodifiable; may embed wiki links).
  List<String> get conseils => _conseils;

  /// Localized « 💡 » one-liner, or `null` if the term carries none.
  String? get astuce => _astuce;

  /// Asset path of the illustration (`assets/images/glossaire/<id>.webp`), or
  /// `null` — an absent illustration renders no block (D4).
  String? get illustration => _illustration;

  /// Typed derived blocks the term page renders (unmodifiable, D3).
  List<ComplementTerme> get complements => _complements;

  /// Copy of this term carrying [illustration] (D4 / Lot 5): the registry
  /// (`construireGlossaire`) attaches the asset path of every term listed in
  /// `illustrations_glossaire.dart` — content builders never set it themselves.
  TermeGlossaire avecIllustration(String illustration) => TermeGlossaire._(
        _id,
        _chapitre,
        _type,
        _titre,
        _definition,
        _conseils,
        _astuce,
        illustration,
        _complements,
      );

  @override
  bool operator ==(Object other) => other is TermeGlossaire && other._id == _id;

  @override
  int get hashCode => _id.hashCode;

  @override
  String toString() => 'TermeGlossaire($_id)';
}
