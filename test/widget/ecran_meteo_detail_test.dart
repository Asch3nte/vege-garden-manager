// Widget tests for the refactored weather detail screen.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/horloge_provider.dart';
import 'package:pot_a_gerer/application/state/meteo_accueil_vue.dart';
import 'package:pot_a_gerer/application/state/meteo_detail_notifier.dart';
import 'package:pot_a_gerer/application/state/meteo_detail_vue.dart';
import 'package:pot_a_gerer/application/state/jour_meteo_vue.dart';
import 'package:pot_a_gerer/domain/value_objects/prevision_horaire.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_meteo_detail.dart';
import 'package:pot_a_gerer/application/providers/unites_provider.dart';
import 'package:pot_a_gerer/domain/enums/systeme_unites.dart';
import 'package:pot_a_gerer/domain/value_objects/preferences_unites.dart';

void main() {
  final maintenant = DateTime(2026, 6, 9, 8, 24);

  // ── Test fixtures ─────────────────────────────────────────────────────────

  JourMeteoVue jourAujourdhui() => JourMeteoVue(
        date: DateTime(2026, 6, 9),
        tempMin: 18,
        tempMax: 26,
        precipitationsMm: 0,
        probabilitePluie: 0.0,
        weathercode: 0,
        risqueGel: false,
        risqueCanicule: false,
        ventMaxKmh: 10,
        heures: [
          PrevisionHoraire(
              heure: DateTime(2026, 6, 9, 8),
              temperature: 21,
              precipitationsMm: 0),
          PrevisionHoraire(
              heure: DateTime(2026, 6, 9, 14),
              temperature: 26,
              precipitationsMm: 0),
        ],
      );

  JourMeteoVue jourDemain() => JourMeteoVue(
        date: DateTime(2026, 6, 10),
        tempMin: 15,
        tempMax: 22,
        precipitationsMm: 2,
        probabilitePluie: 0.8,
        weathercode: 61,
        risqueGel: false,
        risqueCanicule: false,
        ventMaxKmh: 8,
        heures: [
          PrevisionHoraire(
              heure: DateTime(2026, 6, 10, 9),
              temperature: 18,
              precipitationsMm: 2,
              probabilitePluie: 0.8),
        ],
      );

  MeteoDetailVue uneVue({
    bool disponible = true,
    VerdictMeteo verdict = VerdictMeteo.clement,
  }) =>
      disponible
          ? MeteoDetailVue.disponible(
              nomPotager: 'Mon potager',
              nomStation: 'Bruxelles',
              elevation: 65.0,
              derniereMaj: DateTime(2026, 6, 9, 15, 45),
              jours: [jourAujourdhui(), jourDemain()],
              verdictArrosage: verdict,
            )
          : MeteoDetailVue.indisponible(nomPotager: '');

  Future<void> monter(WidgetTester tester, MeteoDetailVue vue,
      {PreferencesUnites unites = const PreferencesUnites()}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          horlogeProvider.overrideWithValue(() => maintenant),
          meteoDetailProvider.overrideWith((_) async => vue),
          unitesProvider.overrideWithValue(unites),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const EcranMeteoDetail(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // ── No position ───────────────────────────────────────────────────────────

  testWidgets('indisponible → shows "sans position" message', (tester) async {
    await monter(tester, uneVue(disponible: false));

    expect(find.textContaining('position'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('drizzle, rain and snow hours get weather icons', (tester) async {
    PrevisionHoraire heure(int h, int code) => PrevisionHoraire(
        heure: DateTime(2026, 6, 9, h),
        temperature: 12,
        precipitationsMm: 0,
        weathercode: code);
    final jour = JourMeteoVue(
      date: DateTime(2026, 6, 9),
      tempMin: 8,
      tempMax: 14,
      precipitationsMm: 3,
      probabilitePluie: 0.8,
      weathercode: 3,
      risqueGel: false,
      risqueCanicule: false,
      ventMaxKmh: 10,
      heures: [heure(8, 53), heure(9, 63), heure(10, 73)],
    );
    await monter(
        tester,
        MeteoDetailVue.disponible(
          nomPotager: 'Mon potager',
          nomStation: null,
          elevation: null,
          derniereMaj: DateTime(2026, 6, 9, 7),
          jours: [jour],
          verdictArrosage: VerdictMeteo.clement,
        ));

    expect(find.byIcon(PhosphorIconsRegular.grains), findsNothing);
    expect(find.byIcon(PhosphorIconsRegular.drop), findsWidgets);
    expect(find.byIcon(PhosphorIconsRegular.cloudRain), findsOneWidget);
    expect(find.byIcon(PhosphorIconsRegular.cloudSnow), findsOneWidget);
  });

  testWidgets('desactivee → shows the opt-out message', (tester) async {
    await monter(tester, MeteoDetailVue.desactivee(nomPotager: 'Mon potager'));

    expect(find.textContaining('Météo automatique désactivée'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
  });

  // ── Happy path ────────────────────────────────────────────────────────────

  testWidgets('shows potager name in AppBar', (tester) async {
    await monter(tester, uneVue());

    expect(find.text('Mon potager'), findsOneWidget);
  });

  testWidgets('imperial units convert temperatures, wind and elevation',
      (tester) async {
    await monter(tester, uneVue(),
        unites: const PreferencesUnites.uniforme(SystemeUnites.imperial));

    expect(find.text('64° – 79°'), findsWidgets);
    expect(find.text('6 mph'), findsWidgets);
    expect(find.textContaining('213 ft'), findsOneWidget);
    expect(find.textContaining('km/h'), findsNothing);
  });

  testWidgets('shows station info in header', (tester) async {
    await monter(tester, uneVue());

    expect(find.textContaining('Bruxelles'), findsOneWidget);
    expect(find.textContaining('65 m'), findsOneWidget);
    expect(find.textContaining('15h45'), findsOneWidget);
  });

  testWidgets('shows day cards for today and tomorrow', (tester) async {
    await monter(tester, uneVue());

    // "Aujourd'hui" appears in the day card AND as the résumé section title.
    expect(find.text("Aujourd'hui"), findsAtLeastNWidgets(1));
    expect(find.text('Demain'), findsWidgets);
  });

  testWidgets('today hourly columns are shown by default', (tester) async {
    await monter(tester, uneVue());

    expect(find.text('8h'), findsOneWidget);
    expect(find.text('21°'), findsOneWidget);
  });

  testWidgets('tapping Demain card switches to tomorrow hourly data',
      (tester) async {
    await monter(tester, uneVue());

    expect(find.text('18°'), findsNothing);

    // Tap the day card labelled 'Demain' (the first one in the selector).
    await tester.tap(find.text('Demain').first);
    await tester.pumpAndSettle();

    expect(find.text('9h'), findsOneWidget);
    expect(find.text('18°'), findsOneWidget);
  });

  testWidgets('resume text for today is visible', (tester) async {
    await monter(tester, uneVue());

    expect(find.textContaining('Temps ensoleillé'), findsOneWidget);
  });

  testWidgets('résumé Demain paragraph is visible when today selected',
      (tester) async {
    await monter(tester, uneVue());

    expect(find.textContaining('Pluvieux, max 22°'), findsOneWidget);
  });

  testWidgets('shows "Pourquoi ces tâches ?" section', (tester) async {
    await monter(tester, uneVue());

    expect(find.textContaining('Pourquoi ces tâches'), findsOneWidget);
    expect(find.textContaining('Conditions clémentes'), findsOneWidget);
  });

  // ── Verdict variants ──────────────────────────────────────────────────────

  testWidgets('pluieAVenir verdict shows explication', (tester) async {
    final vue = MeteoDetailVue.disponible(
      nomPotager: 'Mon potager',
      nomStation: null,
      elevation: null,
      derniereMaj: DateTime(2026, 6, 9, 10),
      jours: [jourAujourdhui()],
      verdictArrosage: VerdictMeteo.pluieAVenir,
    );
    await monter(tester, vue);

    expect(find.textContaining('différé'), findsOneWidget);
  });
}
