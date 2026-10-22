import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/presentation/widgets/globe/camera_globe.dart';

void main() {
  const rayon = 100.0;
  late CameraGlobe camera;

  setUp(() => camera = CameraGlobe(latitude: 0, longitude: 0));

  /// Advances the camera by [secondes] in 1/60 s steps.
  void avancer(double secondes) {
    for (var t = 0.0; t < secondes; t += 1 / 60) {
      camera.avancer(1 / 60);
    }
  }

  test('dragging right turns the view west, dragging down shows the north',
      () {
    camera.glisser(const Offset(10, 20), rayon);
    expect(camera.longitude, closeTo(-0.1 * 57.29578, 1e-3));
    expect(camera.latitude, closeTo(0.2 * 57.29578, 1e-3));
  });

  test('the latitude stays away from the poles', () {
    camera.glisser(const Offset(0, 10000), rayon);
    expect(camera.latitude, CameraGlobe.latitudeMax);
  });

  test('the longitude stays within [-180, 180]', () {
    camera.glisser(const Offset(-400, 0), rayon);
    expect(camera.longitude, inInclusiveRange(-180, 180));
  });

  test('released with speed, the globe keeps turning then stops', () {
    camera.lacher(const Offset(-300, 0), rayon);
    expect(camera.enMouvement, isTrue);
    avancer(0.2);
    final apres = camera.longitude;
    expect(apres, greaterThan(0));
    avancer(5);
    expect(camera.enMouvement, isFalse);
    expect(camera.longitude, greaterThan(apres));
  });

  test('a new drag stops the inertia', () {
    camera.lacher(const Offset(-300, 0), rayon);
    camera.glisser(Offset.zero, rayon);
    expect(camera.enMouvement, isFalse);
  });

  test('zoom is bounded', () {
    camera.zoomer(1000);
    expect(camera.zoom, CameraGlobe.zoomMax);
    camera.zoomer(0.0001);
    expect(camera.zoom, CameraGlobe.zoomMin);
  });

  test('aiming animates to the target, then stops', () {
    camera.viser(48, 2, zoom: 6);
    expect(camera.enMouvement, isTrue);
    avancer(0.2);
    expect(camera.latitude, inExclusiveRange(0, 48));
    avancer(2);
    expect(camera.enMouvement, isFalse);
    expect(camera.latitude, closeTo(48, 1e-9));
    expect(camera.longitude, closeTo(2, 1e-9));
    expect(camera.zoom, closeTo(6, 1e-9));
  });

  test('aiming takes the short way across the antimeridian', () {
    camera = CameraGlobe(latitude: 0, longitude: 170);
    camera.viser(0, -170);
    avancer(0.4);
    expect(camera.longitude.abs(), greaterThan(170));
  });

  test('changes are notified', () {
    var notifs = 0;
    camera.addListener(() => notifs++);
    camera.glisser(const Offset(1, 0), rayon);
    camera.zoomer(2);
    camera.viser(1, 1);
    expect(notifs, 3);
  });
}
