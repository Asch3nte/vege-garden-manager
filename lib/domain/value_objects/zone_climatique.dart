import '../enums/type_climat.dart';
import '../enums/zone_rusticite.dart';

/// Immutable value object describing a potager's climate along two dimensions:
/// the general [TypeClimat] and the cold tolerance [ZoneRusticite].
///
/// The rusticity drives frost reasoning (e.g. gating frost-sensitive plantings).
/// Climate is typically deduced from the [Localisation] (via Open-Meteo) or set
/// manually.
///
/// Domain names are kept in French; the code is documented in English.
/// See `docs/05-modele-de-domaine.md` §4.6.
///
/// Note: `compatibleAvec(...)` and `dateDernierGelEstimee(...)` are deliberately
/// not implemented here. Their precise rules depend on context the VO does not
/// hold (a plant's list of compatible zones, the hemisphere, a reference year)
/// and belong to the recommendation engine.
class ZoneClimatique {
  final TypeClimat _type;
  final ZoneRusticite _rusticite;

  const ZoneClimatique(this._type, this._rusticite);

  /// General climate classification.
  TypeClimat get type => _type;

  /// Cold-tolerance (hardiness) zone.
  ZoneRusticite get rusticite => _rusticite;

  /// Coldest average annual extreme-minimum temperature of this climate, in °C.
  double get temperatureExtremeMinC => _rusticite.temperatureExtremeMinC;

  /// Whether this climate normally experiences frost (annual minimums reach
  /// freezing). Frost-sensitive plants need protection here.
  bool get supporteGel => _rusticite.connaitLeGel;

  @override
  bool operator ==(Object other) =>
      other is ZoneClimatique &&
      other._type == _type &&
      other._rusticite == _rusticite;

  @override
  int get hashCode => Object.hash(_type, _rusticite);

  @override
  String toString() =>
      'ZoneClimatique(${_type.name}, ${_rusticite.name})';
}
