import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import 'projection_orthographique.dart';

/// Point of view on the globe: centre, zoom, inertial spin and animated aim.
///
/// Time is driven from outside through [avancer], so the behaviour is
/// deterministic and testable.
class CameraGlobe extends ChangeNotifier {
  static const double latitudeMax = 80;
  static const double zoomMin = 1;
  static const double zoomMax = 30;
  static const double _friction = 2.2;
  static const double _vitesseArret = 0.01;
  static const double _dureeVisee = 0.9;

  double _latitude;
  double _longitude;
  double _zoom;

  // Inertial angular speed, in radians per second.
  double _vLon = 0;
  double _vLat = 0;

  _Visee? _visee;

  CameraGlobe({
    required double latitude,
    required double longitude,
    double zoom = zoomMin,
  })  : _latitude = latitude.clamp(-latitudeMax, latitudeMax),
        _longitude = ProjectionOrthographique.normaliserLongitude(longitude),
        _zoom = zoom.clamp(zoomMin, zoomMax);

  double get latitude => _latitude;

  double get longitude => _longitude;

  double get zoom => _zoom;

  /// Whether a spin or an aim is still running.
  bool get enMouvement => _visee != null || _vLon != 0 || _vLat != 0;

  ProjectionOrthographique get projection => ProjectionOrthographique(
      latitudeCentre: _latitude, longitudeCentre: _longitude);

  /// Turns the globe under a finger moving by [delta] pixels on a globe of
  /// [rayon] pixels; stops any spin or aim.
  void glisser(Offset delta, double rayon) {
    _arreter();
    _tourner(delta.dx / rayon, delta.dy / rayon);
    notifyListeners();
  }

  /// Releases the finger at [vitesse] pixels per second: the globe keeps
  /// spinning and slows down.
  void lacher(Offset vitesse, double rayon) {
    _visee = null;
    _vLon = vitesse.dx / rayon;
    _vLat = vitesse.dy / rayon;
    if (math.sqrt(_vLon * _vLon + _vLat * _vLat) < _vitesseArret) _arreter();
  }

  /// Multiplies the zoom by [facteur], within [zoomMin]..[zoomMax].
  void zoomer(double facteur) {
    _zoom = (_zoom * facteur).clamp(zoomMin, zoomMax);
    notifyListeners();
  }

  /// Animates the view towards ([latitude], [longitude]) and optionally
  /// [zoom], taking the shortest way round.
  void viser(double latitude, double longitude, {double? zoom}) {
    _arreter();
    final dLon = ProjectionOrthographique.normaliserLongitude(
        longitude - _longitude);
    _visee = _Visee(
      latDepart: _latitude,
      lonDepart: _longitude,
      zoomDepart: _zoom,
      latCible: latitude.clamp(-latitudeMax, latitudeMax),
      dLon: dLon,
      zoomCible: (zoom ?? _zoom).clamp(zoomMin, zoomMax),
    );
    notifyListeners();
  }

  /// Advances spin and aim by [dt] seconds. Returns [enMouvement].
  bool avancer(double dt) {
    if (dt <= 0) return enMouvement;
    final visee = _visee;
    if (visee != null) {
      visee.ecoule += dt;
      final t = Curves.easeInOutCubic
          .transform((visee.ecoule / _dureeVisee).clamp(0.0, 1.0));
      _latitude = lerpDouble(visee.latDepart, visee.latCible, t)!;
      _longitude = ProjectionOrthographique.normaliserLongitude(
          visee.lonDepart + visee.dLon * t);
      _zoom = lerpDouble(visee.zoomDepart, visee.zoomCible, t)!;
      if (visee.ecoule >= _dureeVisee) _visee = null;
      notifyListeners();
    } else if (_vLon != 0 || _vLat != 0) {
      _tourner(_vLon * dt, _vLat * dt);
      final f = math.exp(-_friction * dt);
      _vLon *= f;
      _vLat *= f;
      if (math.sqrt(_vLon * _vLon + _vLat * _vLat) < _vitesseArret) {
        _vLon = 0;
        _vLat = 0;
      }
      notifyListeners();
    }
    return enMouvement;
  }

  void _tourner(double dLonRad, double dLatRad) {
    _longitude = ProjectionOrthographique.normaliserLongitude(
        _longitude - dLonRad * 180 / math.pi);
    _latitude = (_latitude + dLatRad * 180 / math.pi)
        .clamp(-latitudeMax, latitudeMax);
  }

  void _arreter() {
    _visee = null;
    _vLon = 0;
    _vLat = 0;
  }
}

class _Visee {
  final double latDepart;
  final double lonDepart;
  final double zoomDepart;
  final double latCible;
  final double dLon;
  final double zoomCible;
  double ecoule = 0;

  _Visee({
    required this.latDepart,
    required this.lonDepart,
    required this.zoomDepart,
    required this.latCible,
    required this.dLon,
    required this.zoomCible,
  });
}
