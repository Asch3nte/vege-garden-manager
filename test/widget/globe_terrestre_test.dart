import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:pot_a_gerer/presentation/widgets/globe/camera_globe.dart';
import 'package:pot_a_gerer/presentation/widgets/globe/globe_terrestre.dart';

void main() {
  late CameraGlobe camera;
  late List<(double, double)> taps;

  Future<void> monter(WidgetTester tester, {(double, double)? pin}) async {
    tester.view.physicalSize = const Size(400, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: GlobeTerrestre(
        camera: camera,
        pin: pin,
        libelle: 'Globe',
        onTap: (lat, lon) => taps.add((lat, lon)),
      ),
    ));
  }

  setUp(() {
    camera = CameraGlobe(latitude: 50, longitude: 4);
    taps = [];
  });

  tearDown(() => camera.dispose());

  testWidgets('a tap at the centre picks the view centre', (tester) async {
    await monter(tester);
    await tester.tapAt(const Offset(200, 200));
    final (lat, lon) = taps.single;
    expect(lat, closeTo(50, 1e-6));
    expect(lon, closeTo(4, 1e-6));
  });

  testWidgets('a tap beside the globe picks nothing', (tester) async {
    await monter(tester);
    await tester.tapAt(const Offset(2, 2));
    expect(taps, isEmpty);
  });

  testWidgets('a fling turns the globe, which then comes to rest',
      (tester) async {
    await monter(tester);
    await tester.fling(
        find.byType(GlobeTerrestre), const Offset(-120, 0), 800);
    await tester.pump(const Duration(milliseconds: 100));
    final enVol = camera.longitude;
    expect(camera.enMouvement, isTrue);
    await tester.pumpAndSettle();
    expect(camera.enMouvement, isFalse);
    expect(camera.longitude, greaterThan(enVol));
    expect(taps, isEmpty);
  });

  testWidgets('the mouse wheel zooms', (tester) async {
    await monter(tester);
    final souris = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(souris.hover(const Offset(200, 200)));
    await tester.sendEventToBinding(souris.scroll(const Offset(0, -200)));
    await tester.pump();
    expect(camera.zoom, greaterThan(1));
  });

  testWidgets('the pin shows on the visible side only', (tester) async {
    await monter(tester, pin: (50, 4));
    expect(find.byIcon(PhosphorIconsBold.mapPin), findsOneWidget);
    await monter(tester, pin: (-50, -176));
    expect(find.byIcon(PhosphorIconsBold.mapPin), findsNothing);
  });

  testWidgets('the globe follows camera changes', (tester) async {
    await monter(tester, pin: (-50, -176));
    camera.viser(-50, -176);
    await tester.pumpAndSettle();
    expect(find.byIcon(PhosphorIconsBold.mapPin), findsOneWidget);
  });

  testWidgets('the globe is labelled for assistive technologies',
      (tester) async {
    await monter(tester);
    expect(find.bySemanticsLabel('Globe'), findsOneWidget);
  });
}
