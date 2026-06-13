// Widget tests for the zoomable world-map position picker (Lot 2).
//
// The picker is opened via [choisirSurCarteMonde]; these tests drive the
// region-shortcut + confirm flow and a direct tap, asserting the returned
// [Localisation]. The map image decode is irrelevant here (taps hit the
// gesture layer, not the pixels), so it is left to load lazily.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pot_a_gerer/domain/enums/source_localisation.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/widgets/selecteur_carte_monde.dart';

void main() {
  /// A one-slot holder the host writes the picker's result into.
  late List<Localisation?> capture;

  /// Mounts a host with a button that opens the picker and records its result.
  /// Defaults to a wide surface so the whole horizontal region band fits
  /// without scrolling (the presets are what most tests tap).
  Future<void> monter(WidgetTester tester,
      {Size taille = const Size(1600, 800)}) async {
    tester.view.physicalSize = taille;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    capture = <Localisation?>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async =>
                    capture.add(await choisirSurCarteMonde(context)),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('a region shortcut drops the pin and confirming returns its '
      'coordinates', (tester) async {
    await monter(tester);

    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    // No selection yet: no pin, confirm is disabled.
    expect(find.byIcon(Icons.location_on), findsNothing);

    await tester.ensureVisible(find.text('Zone tropicale'));
    await tester.tap(find.text('Zone tropicale'));
    await tester.pumpAndSettle();

    // The pin is now shown.
    expect(find.byIcon(Icons.location_on), findsOneWidget);

    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    final loc = capture.single;
    expect(loc, isNotNull);
    expect(loc!.estDefinie, isTrue);
    expect(loc.source, SourceLocalisation.manuelle);
    // Tropical preset latitude (5°), rounded to ~1 km by the value object.
    expect(loc.latitude, closeTo(5, 0.01));
  });

  testWidgets('the interactive zone fills the available height, not just the '
      '2:1 band', (tester) async {
    // Tall portrait surface: the zoom/pan canvas should span the whole free
    // height (so zooming uses every pixel), well beyond the contained image
    // band (width / 2).
    await monter(tester, taille: const Size(400, 900));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    final zone = tester.getSize(find.byType(InteractiveViewer));
    final hauteurBande = zone.width / (2058 / 1036);
    expect(zone.height, greaterThan(hauteurBande * 2),
        reason: 'the interactive zone must fill far more than the image band');
  });

  testWidgets('a direct tap on the map drops the pin', (tester) async {
    await monter(tester);

    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.location_on), findsNothing);

    // Tap somewhere inside the map image.
    await tester.tap(find.byType(Image));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.location_on), findsOneWidget);
    expect(find.text('Valider'), findsOneWidget);
  });
}
