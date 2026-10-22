import 'dart:math' as math;
import 'dart:ui';

/// Orthographic projection of the globe seen from above
/// ([latitudeCentre], [longitudeCentre]), in degrees.
///
/// Disc points are expressed in units of the globe radius, origin at the disc
/// centre, x to the right and y downwards (screen axes).
class ProjectionOrthographique {
  final double _latitudeCentre;
  final double _longitudeCentre;

  const ProjectionOrthographique({
    required this._latitudeCentre,
    required this._longitudeCentre,
  });

  /// Geographic `(latitude, longitude)` under the disc point [p], or `null`
  /// outside the disc. Longitude is normalised to `[-180, 180]`.
  (double, double)? versCoords(Offset p) {
    final r2 = p.dx * p.dx + p.dy * p.dy;
    if (r2 > 1) return null;
    final x = p.dx;
    final y = -p.dy;
    final z = math.sqrt(1 - r2);
    final lat0 = _rad(_latitudeCentre);
    final cl = math.cos(lat0);
    final sl = math.sin(lat0);
    final lat = math.asin((y * cl + z * sl).clamp(-1.0, 1.0));
    final dLon = math.atan2(x, z * cl - y * sl);
    return (_deg(lat), normaliserLongitude(_longitudeCentre + _deg(dLon)));
  }

  /// Disc point of ([latitude], [longitude]), or `null` on the far side.
  Offset? versDisque(double latitude, double longitude) {
    final lat = _rad(latitude);
    final dLon = _rad(longitude - _longitudeCentre);
    final lat0 = _rad(_latitudeCentre);
    final cl = math.cos(lat0);
    final sl = math.sin(lat0);
    final z = sl * math.sin(lat) + cl * math.cos(lat) * math.cos(dLon);
    if (z < 0) return null;
    final x = math.cos(lat) * math.sin(dLon);
    final y = cl * math.sin(lat) - sl * math.cos(lat) * math.cos(dLon);
    return Offset(x, -y);
  }

  /// [longitude] brought back to `[-180, 180]`.
  static double normaliserLongitude(double longitude) {
    final l = (longitude + 180) % 360;
    return (l < 0 ? l + 360 : l) - 180;
  }

  static double _rad(double deg) => deg * math.pi / 180;

  static double _deg(double rad) => rad * 180 / math.pi;
}
