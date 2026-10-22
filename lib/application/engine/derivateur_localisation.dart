import '../../domain/enums/hemisphere.dart';
import '../../domain/enums/type_climat.dart';
import '../../domain/enums/zone_rusticite.dart';
import '../../domain/value_objects/localisation.dart';

/// A climate context **suggested** from a position: a reliable [hemisphere] and
/// coarse [climat] / [rusticite] guesses to pre-fill (and let the user confirm).
class SuggestionClimat {
  final Hemisphere _hemisphere;
  final TypeClimat _climat;
  final ZoneRusticite _rusticite;

  const SuggestionClimat._(this._hemisphere, this._climat, this._rusticite);

  Hemisphere get hemisphere => _hemisphere;
  TypeClimat get climat => _climat;
  ZoneRusticite get rusticite => _rusticite;
}

/// Derives a climate context from a position's latitude and, when known, its
/// altitude.
///
/// The [Hemisphere] is exact (sign of the latitude). The climate type and the
/// hardiness zone are **coarse heuristics** (latitude bands, corrected for
/// altitude): they ignore longitude, oceanic influence and local
/// microclimates, so they are only meant to *pre-fill* a form for the user to
/// confirm or adjust — never presented as precise. Aridity cannot be inferred
/// and is left to the user.
class DerivateurLocalisation {
  const DerivateurLocalisation();

  /// Altitude lowering the hardiness by one zone: about 0.65 °C per 100 m
  /// against about 5.6 °C per USDA zone.
  static const double metresParZone = 800;

  /// Altitude from which a mountain climate is suggested.
  static const double altitudeMontagnardM = 1200;

  /// Suggests a climate context for [localisation], refined by [altitudeM]
  /// (metres) when known. The position must be defined
  /// ([Localisation.estDefinie]); callers obtain it from GPS or a map pick.
  SuggestionClimat deriver(Localisation localisation, {double? altitudeM}) {
    final latitude = localisation.latitude;
    if (latitude == null) {
      throw ArgumentError('a defined position is required to derive a climate');
    }
    final hemisphere = localisation.hemisphere!;
    final abs = latitude.abs();
    final altitude = altitudeM == null || altitudeM < 0 ? 0.0 : altitudeM;
    var climat = _climat(abs);
    if (altitude >= altitudeMontagnardM && climat != TypeClimat.polaire) {
      climat = TypeClimat.montagnard;
    }
    final crans = (altitude / metresParZone).floor();
    final zone = ZoneRusticite.values[
        (_rusticite(abs).index - crans).clamp(0, ZoneRusticite.values.length - 1)];
    return SuggestionClimat._(hemisphere, climat, zone);
  }

  /// Climate type by absolute latitude band (suggestion only).
  TypeClimat _climat(double absLat) {
    if (absLat < 23.5) return TypeClimat.tropical;
    if (absLat < 35) return TypeClimat.subtropical;
    if (absLat < 45) return TypeClimat.mediterraneen;
    if (absLat < 55) return TypeClimat.oceanique;
    if (absLat < 66.5) return TypeClimat.continental;
    return TypeClimat.polaire;
  }

  /// USDA hardiness zone by absolute latitude band (suggestion only): higher
  /// latitudes are colder, hence lower zones.
  ZoneRusticite _rusticite(double absLat) {
    if (absLat < 25) return ZoneRusticite.zone11;
    if (absLat < 30) return ZoneRusticite.zone10;
    if (absLat < 35) return ZoneRusticite.zone9;
    if (absLat < 40) return ZoneRusticite.zone8;
    if (absLat < 45) return ZoneRusticite.zone7;
    if (absLat < 50) return ZoneRusticite.zone6;
    if (absLat < 55) return ZoneRusticite.zone5;
    if (absLat < 60) return ZoneRusticite.zone4;
    if (absLat < 66.5) return ZoneRusticite.zone3;
    return ZoneRusticite.zone2;
  }
}
