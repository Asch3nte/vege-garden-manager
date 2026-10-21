/// Physical structure of a parcelle (cultivation techniques are orthogonal — see
/// `TechniqueSol`).
enum TypeParcelle {
  pleineTerre,
  bacSureleve,
  jardiniere,
  pot,
  serre,
  butte,
  autre;

  /// Container whose potting soil is routinely renewed: it resets the rotation
  /// clock and limits root depth.
  bool get solRenouvele => this == pot || this == jardiniere;
}
