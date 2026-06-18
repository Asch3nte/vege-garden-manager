// Widget tests for the plant sheet's min–max display (ADR-0014, Lot 6).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/widgets/fiche_plante_detail.dart';

FichePlante _fiche() => FichePlante(
      id: 'laitue',
      nomScientifique: 'Lactuca sativa',
      familleBotanique: 'Asteraceae',
      categorie: CategoriePlante.legume,
      usages: const {UsagePlante.alimentaire},
      nomsLocalises: const {'fr': 'Laitue'},
      besoins: BesoinsCulture(
        eau: BesoinEau.modere,
        soleil: NiveauSoleil.pleinSoleil,
        soleilMin: NiveauSoleil.miOmbre,
        phMin: 6,
        phMax: 7,
      ),
      espacementCm: 30,
      dureeAvantRecolteJoursMin: 40,
      dureeAvantRecolteJoursMax: 60,
      hauteurAdulteCmMin: 15,
      hauteurAdulteCmMax: 30,
    );

void main() {
  testWidgets('the sheet shows sun as a range when a tolerance is set (ADR-0014)',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => afficherFichePlanteDetail(context, _fiche()),
                  child: const Text('ouvrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    // Range from the minimum tolerance to the optimum, plus height & pH ranges.
    expect(find.text('Mi-ombre à plein soleil'), findsOneWidget);
    expect(find.text('15–30 cm'), findsOneWidget);
    expect(find.text('6 à 7'), findsOneWidget);
  });
}
