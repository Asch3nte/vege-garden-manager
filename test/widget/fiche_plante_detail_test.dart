// Widget tests for the plant sheet's min–max display (ADR-0014, Lot 6).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/application/state/acces_niveau_provider.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/niveau_experience.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/phase_sensible_eau.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/services/acces_niveau.dart';
import 'package:pot_a_gerer/domain/value_objects/arrosage_detaille.dart';
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

FichePlante _ficheAvecDetail() => FichePlante(
      id: 'laitue',
      nomScientifique: 'Lactuca sativa',
      familleBotanique: 'Asteraceae',
      categorie: CategoriePlante.legume,
      usages: const {UsagePlante.alimentaire},
      nomsLocalises: const {'fr': 'Laitue'},
      besoins: BesoinsCulture(
        eau: BesoinEau.eleve,
        soleil: NiveauSoleil.pleinSoleil,
        phMin: 6,
        phMax: 7,
        arrosageDetaille: ArrosageDetaille(
          frequenceJoursMin: 2,
          frequenceJoursMax: 3,
          volumeLitresM2Min: 3,
          volumeLitresM2Max: 5,
          phasesSensibles: {
            PhaseSensibleEau.floraison,
            PhaseSensibleEau.fructification,
          },
          noteI18n: const {'fr': 'Gardez le sol frais en permanence.'},
        ),
      ),
      espacementCm: 30,
      dureeAvantRecolteJoursMin: 40,
      dureeAvantRecolteJoursMax: 60,
    );

Future<void> _ouvrir(
  WidgetTester tester,
  FichePlante fiche, {
  required NiveauExperience niveau,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        accesNiveauProvider.overrideWithValue(AccesNiveau(niveau)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => afficherFichePlanteDetail(context, fiche),
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
}

void main() {
  testWidgets('the sheet shows sun as a range when a tolerance is set (ADR-0014)',
      (tester) async {
    await _ouvrir(tester, _fiche(), niveau: NiveauExperience.debutant);

    // Range from the minimum tolerance to the optimum, plus height & pH ranges.
    expect(find.text('Mi-ombre à plein soleil'), findsOneWidget);
    expect(find.text('15–30 cm'), findsOneWidget);
    expect(find.text('6 à 7'), findsOneWidget);
  });

  group('detailed watering section (ADR-0009 acces.eauDetaillee)', () {
    testWidgets('an expert sees the full detail', (tester) async {
      await _ouvrir(tester, _ficheAvecDetail(),
          niveau: NiveauExperience.expert);

      expect(find.text('Arrosage détaillé'), findsOneWidget);
      expect(find.text('Tous les 2 à 3 jours'), findsOneWidget);
      expect(find.text('3 à 5 L/m²'), findsOneWidget);
      expect(find.text('Floraison'), findsOneWidget);
      expect(find.text('Fructification'), findsOneWidget);
      expect(
          find.text('Gardez le sol frais en permanence.'), findsOneWidget);
      // The coarse fact stays visible for everyone.
      expect(find.text('Arrosage'), findsOneWidget);
    });

    testWidgets('a beginner does not see the detailed section', (tester) async {
      await _ouvrir(tester, _ficheAvecDetail(),
          niveau: NiveauExperience.debutant);

      expect(find.text('Arrosage détaillé'), findsNothing);
      expect(find.text('Tous les 2 à 3 jours'), findsNothing);
      // …but the coarse fact is still there.
      expect(find.text('Arrosage'), findsOneWidget);
    });

    testWidgets('no section when the fiche carries no detail', (tester) async {
      // _fiche() has no arrosageDetaille.
      await _ouvrir(tester, _fiche(), niveau: NiveauExperience.expert);
      expect(find.text('Arrosage détaillé'), findsNothing);
    });
  });
}
