import '../enums/teinte_zone.dart';
import '../exceptions/invariant_domaine_exception.dart';

/// Colour of a zone: a palette [teinte], or a custom 24-bit [rgb] value.
class CouleurZone {
  final TeinteZone? _teinte;
  final int? _rgb;

  /// A palette tint.
  const CouleurZone.teinte(TeinteZone teinte) : _teinte = teinte, _rgb = null;

  const CouleurZone._personnalisee(int rgb) : _teinte = null, _rgb = rgb;

  /// A custom colour, [rgb] being `0xRRGGBB`.
  factory CouleurZone.personnalisee(int rgb) {
    InvariantDomaineException.verifier(
      rgb >= 0 && rgb <= 0xFFFFFF,
      'rgb must fit in 24 bits',
    );
    return CouleurZone._personnalisee(rgb);
  }

  /// The tint of the zone at [index] in its garden, cycling on the palette.
  factory CouleurZone.pourIndex(int index) =>
      CouleurZone.teinte(TeinteZone.values[index % TeinteZone.values.length]);

  /// Colour for a new zone beside [existantes]: the first unused tint, or the
  /// tint cycled on the zone count once all are taken.
  factory CouleurZone.suivante(Iterable<CouleurZone> existantes) {
    final utilisees = {for (final c in existantes) c._teinte};
    for (final t in TeinteZone.values) {
      if (!utilisees.contains(t)) return CouleurZone.teinte(t);
    }
    return CouleurZone.pourIndex(existantes.length);
  }

  /// Palette tint, or `null` for a custom colour.
  TeinteZone? get teinte => _teinte;

  /// Custom `0xRRGGBB` value, or `null` for a palette tint.
  int? get rgb => _rgb;

  bool get estPersonnalisee => _rgb != null;

  @override
  bool operator ==(Object other) =>
      other is CouleurZone && other._teinte == _teinte && other._rgb == _rgb;

  @override
  int get hashCode => Object.hash(_teinte, _rgb);

  @override
  String toString() => _rgb == null
      ? 'CouleurZone(${_teinte!.name})'
      : 'CouleurZone(#${_rgb.toRadixString(16).padLeft(6, '0')})';
}
