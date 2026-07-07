import '../value_objects/modele_fiche_personnelle.dart';

/// A plant sheet authored by the user (contribution feature, expert tier —
/// gated by `acces.fichesPerso`).
///
/// Identity is the storage [id] (a UUID generated app-side), distinct from the
/// logical [ModeleFichePersonnelle.idFiche] under which the sheet joins the
/// catalogue. The editable [contenu] is the source model; on persistence it is
/// serialized to YAML (`yaml_contenu`, the on-disk source of truth) and its key
/// fields are denormalized into columns for listing/querying.
///
/// See `docs/05-modele-de-domaine.md` and `docs/07-base-de-connaissances-yaml.md`
/// §7. Domain names stay in French; the code is documented in English.
class FichePlantePersonnelle {
  final String _id;
  final ModeleFichePersonnelle _contenu;
  final DateTime _dateCreation;
  final DateTime _dateModification;

  FichePlantePersonnelle._(
    this._id,
    this._contenu,
    this._dateCreation,
    this._dateModification,
  ) : assert(_id.isNotEmpty, 'id must not be empty');

  /// Creates a personal sheet. [dateModification] defaults to [dateCreation].
  factory FichePlantePersonnelle({
    required String id,
    required ModeleFichePersonnelle contenu,
    required DateTime dateCreation,
    DateTime? dateModification,
  }) =>
      FichePlantePersonnelle._(
        id,
        contenu,
        dateCreation,
        dateModification ?? dateCreation,
      );

  /// Storage identity (UUID), stable across edits.
  String get id => _id;

  /// Editable content of the sheet.
  ModeleFichePersonnelle get contenu => _contenu;

  /// Logical catalogue id under which this sheet is exposed.
  String get idFiche => _contenu.idFiche;

  /// French common name — the primary label shown in lists.
  String get nomCommunFr => _contenu.nomCommunFr;

  DateTime get dateCreation => _dateCreation;
  DateTime get dateModification => _dateModification;

  /// Returns a copy carrying updated [contenu], stamping [dateModification].
  FichePlantePersonnelle avecContenu(
    ModeleFichePersonnelle contenu,
    DateTime dateModification,
  ) =>
      FichePlantePersonnelle._(_id, contenu, _dateCreation, dateModification);

  @override
  bool operator ==(Object other) =>
      other is FichePlantePersonnelle && other._id == _id;

  @override
  int get hashCode => _id.hashCode;

  @override
  String toString() => 'FichePlantePersonnelle($_id, ${_contenu.idFiche})';
}
