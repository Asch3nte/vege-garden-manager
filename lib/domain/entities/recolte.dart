import '../enums/destination_recolte.dart';
import '../enums/qualite_recolte.dart';
import '../value_objects/quantite.dart';

/// A single harvest event for a plantation. A plantation may have several
/// successive harvests.
///
/// `Recolte` is an **entity**: it has an identity ([id]) and is compared by that
/// identity, not by value. The [id] is a UUID v4 generated app-side (in the
/// application layer) and injected here, so the domain stays free of the `uuid`
/// dependency and tests remain deterministic.
///
/// [quantite], [date], [destination] and [plantationId] are fixed at creation;
/// [qualite] and [notes] can be filled in afterwards.
///
/// Domain names are kept in French; the code is documented in English.
/// See `docs/05-modele-de-domaine.md` §3.5.
class Recolte {
  final String _id;
  final String _plantationId;
  final DateTime _date;
  final Quantite _quantite;
  final DestinationRecolte _destination;
  QualiteRecolte? _qualite;
  String? _notes;

  Recolte._(
    this._id,
    this._plantationId,
    this._date,
    this._quantite,
    this._destination,
    this._qualite,
    this._notes,
  ) : assert(_id.isNotEmpty, 'id must not be empty');

  /// Records a harvest. [qualite] is optional (null = not yet assessed) and can
  /// be set later via [definirQualite].
  factory Recolte({
    required String id,
    required String plantationId,
    required DateTime date,
    required Quantite quantite,
    DestinationRecolte destination = DestinationRecolte.consommationFraiche,
    QualiteRecolte? qualite,
    String? notes,
  }) =>
      Recolte._(id, plantationId, date, quantite, destination, qualite, notes);

  String get id => _id;
  String get plantationId => _plantationId;
  DateTime get date => _date;
  Quantite get quantite => _quantite;
  DestinationRecolte get destination => _destination;

  /// Quality grade, or `null` when it has not been assessed yet.
  QualiteRecolte? get qualite => _qualite;
  String? get notes => _notes;

  /// Assesses (or revises) the quality of this harvest a posteriori.
  void definirQualite(QualiteRecolte qualite) => _qualite = qualite;

  /// Sets or clears the free-text notes.
  void modifierNotes(String? notes) => _notes = notes;

  @override
  bool operator ==(Object other) => other is Recolte && other._id == _id;

  @override
  int get hashCode => _id.hashCode;

  @override
  String toString() => 'Recolte($_id, plantation: $_plantationId, $_quantite)';
}
