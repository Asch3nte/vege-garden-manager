// Widget test for the reusable "option + description" dropdown.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/presentation/widgets/champ_deroulant_decrit.dart';

void main() {
  Future<String?> monter(WidgetTester tester) async {
    String? choisi;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChampDeroulantDecrit<String>(
            value: 'a',
            options: const ['a', 'b'],
            libelle: (o) => 'Option $o',
            description: (o) => 'Description de $o',
            labelText: 'Champ',
            onChanged: (v) => choisi = v,
          ),
        ),
      ),
    );
    return choisi;
  }

  testWidgets('closed field shows the label only, no descriptions',
      (tester) async {
    await monter(tester);

    expect(find.text('Option a'), findsOneWidget);
    expect(find.text('Description de a'), findsNothing);
    expect(find.text('Description de b'), findsNothing);
  });

  testWidgets('open menu shows a description under each option',
      (tester) async {
    await monter(tester);

    await tester.tap(find.text('Option a'));
    await tester.pumpAndSettle();

    expect(find.text('Description de a'), findsOneWidget);
    expect(find.text('Description de b'), findsOneWidget);
  });

  testWidgets('picking an option reports it through onChanged', (tester) async {
    String? choisi;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChampDeroulantDecrit<String>(
            value: 'a',
            options: const ['a', 'b'],
            libelle: (o) => 'Option $o',
            description: (o) => 'Description de $o',
            labelText: 'Champ',
            onChanged: (v) => choisi = v,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Option a'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Description de b'));
    await tester.pumpAndSettle();

    expect(choisi, 'b');
  });
}
