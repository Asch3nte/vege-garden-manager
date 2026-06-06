// Smoke test for the application's root widget.
//
// Exercises [PotAGererApp] directly (not [main]), so it needs no platform
// bootstrap (database, timezone, notifications). It just checks the app mounts
// and shows the landing screen.
import 'package:flutter_test/flutter_test.dart';

import 'package:pot_a_gerer/main.dart';

void main() {
  testWidgets('boots and shows the landing screen', (tester) async {
    await tester.pumpWidget(const PotAGererApp());

    expect(find.text("Pot'à Gérer"), findsOneWidget);
  });
}
