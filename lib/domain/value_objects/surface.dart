/// Immutable value object representing a physical area.
///
/// The area is stored internally in **square metres** (m²) and can never be
/// negative — the invariant is enforced by an assertion at construction time.
/// Two surfaces are equal when they describe the same area (equality by value).
///
/// Domain names are kept in French (inherited from the specification); the code
/// and its documentation are written in English.
///
/// See `docs/05-modele-de-domaine.md` §4.1.
class Surface implements Comparable<Surface> {
  /// Number of square metres represented by this surface. Always `>= 0`.
  final double _metresCarres;

  /// Number of square centimetres in one square metre.
  static const double _cm2ParM2 = 10000;

  const Surface._(this._metresCarres)
      : assert(_metresCarres >= 0, 'A surface cannot be negative.');

  /// Creates a surface from a value expressed in square metres (m²).
  factory Surface.enMetresCarres(double valeur) => Surface._(valeur);

  /// Creates a surface from a value expressed in square centimetres (cm²).
  factory Surface.enCentimetresCarres(double valeur) =>
      Surface._(valeur / _cm2ParM2);

  /// A surface of zero area, useful as a neutral element for sums.
  static const Surface zero = Surface._(0);

  /// The area expressed in square metres (m²).
  double get enMetresCarres => _metresCarres;

  /// The area expressed in square centimetres (cm²).
  double get enCentimetresCarres => _metresCarres * _cm2ParM2;

  /// Returns the sum of this surface and [autre].
  Surface operator +(Surface autre) =>
      Surface._(_metresCarres + autre._metresCarres);

  /// Returns the difference between this surface and [autre].
  ///
  /// The result must stay `>= 0`: subtracting a larger surface violates the
  /// non-negativity invariant and triggers an assertion. Callers must check
  /// availability beforehand (see `surfaceLibre()` at the entity level).
  Surface operator -(Surface autre) =>
      Surface._(_metresCarres - autre._metresCarres);

  bool operator >=(Surface autre) => _metresCarres >= autre._metresCarres;
  bool operator <=(Surface autre) => _metresCarres <= autre._metresCarres;
  bool operator >(Surface autre) => _metresCarres > autre._metresCarres;
  bool operator <(Surface autre) => _metresCarres < autre._metresCarres;

  @override
  int compareTo(Surface autre) =>
      _metresCarres.compareTo(autre._metresCarres);

  @override
  bool operator ==(Object other) =>
      other is Surface && other._metresCarres == _metresCarres;

  @override
  int get hashCode => _metresCarres.hashCode;

  @override
  String toString() => 'Surface(${_metresCarres}m²)';
}
