import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/presentation/widgets/globe/globe_terrestre.dart';

/// In the open position picker, turns the globe to ([latitude], [longitude]),
/// taps its centre and confirms.
Future<void> choisirSurGlobe(
    WidgetTester tester, double latitude, double longitude) async {
  final globe = find.byType(GlobeTerrestre);
  tester.widget<GlobeTerrestre>(globe).camera.viser(latitude, longitude);
  await tester.pumpAndSettle();
  await tester.tapAt(tester.getCenter(globe));
  await tester.pump();
  await tester.tap(find.text('Valider'));
  await tester.pumpAndSettle();
}
