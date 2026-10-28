import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pot_a_gerer/app/historique_navigation.dart';
import 'package:pot_a_gerer/application/providers/service_providers.dart';
import 'package:pot_a_gerer/infrastructure/api/nominatim_client.dart';
import 'package:pot_a_gerer/infrastructure/api/open_meteo_client.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/services/geocodage_service_impl.dart';
import 'package:pot_a_gerer/infrastructure/repositories/meteo_service_impl.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/widgets/globe/globe_terrestre.dart';

import '../test/helpers/faux_services_natifs.dart';
import '../test/helpers/jeu_donnees_riche.dart';
import 'support/app_de_test.dart';

/// Fails every outgoing request and counts the attempts.
class _ReseauRefuse {
  int tentatives = 0;

  late final http.Client client = MockClient((_) async {
    tentatives++;
    throw const SocketException('network blocked in tests');
  });
}

/// Safety net: no socket may be opened outside the injected clients.
class _InterditSockets extends HttpOverrides {
  int tentatives = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    tentatives++;
    throw StateError('Real HTTP client created during the test');
  }
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Navigator).first))!;

Future<void> _taper(WidgetTester tester, String libelle) async {
  final cible = find.text(libelle).last;
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

/// Walks the onboarding: position by search (refused by the network) then by
/// tapping the globe, garden named [nomPotager], plus a zone when [nomZone] is set.
Future<void> _onboarding(
  WidgetTester tester,
  String nomPotager, {
  String? nomZone,
}) async {
  final l10n = _l10n(tester);
  await _taper(tester, l10n.onboardingCommencer);
  await _taper(tester, l10n.onboardingSuivant);

  await _taper(tester, l10n.captureCarteChoisir);
  final champ = find.byWidgetPredicate(
    (w) =>
        w is TextField &&
        w.decoration?.hintText == l10n.carteMondeRechercheIndice,
  );
  await tester.enterText(champ, 'Bruxelles');
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pumpAndSettle();
  expect(find.text(l10n.carteMondeRechercheIndisponible), findsOneWidget);

  final globe = find.byType(GlobeTerrestre);
  tester.widget<GlobeTerrestre>(globe).camera.viser(50.85, 4.35);
  await tester.pumpAndSettle();
  await tester.tapAt(tester.getCenter(globe));
  await tester.pump();
  await _taper(tester, l10n.carteMondeValider);

  await _taper(tester, l10n.onboardingSuivant);
  await _taper(tester, l10n.onboardingSuivant);
  await tester.enterText(find.byType(TextField).last, nomPotager);
  await tester.pump();
  if (nomZone != null) {
    await _taper(tester, l10n.onboardingPotagerAjouterZone);
    await tester.enterText(find.byType(TextFormField).first, nomZone);
    await _taper(tester, l10n.actionEnregistrer);
  }
  await _taper(tester, l10n.onboardingSuivant);
  await _taper(tester, l10n.onboardingTerminer);
}

Future<void> _ouvrirDonnees(WidgetTester tester) async {
  final l10n = _l10n(tester);
  await _taper(tester, l10n.navPlus);
  await _taper(tester, l10n.categDonnees);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onboarding to restore: nothing lost', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final reseau = _ReseauRefuse();
    final sockets = _InterditSockets();
    final precedent = HttpOverrides.current;
    HttpOverrides.global = sockets;
    addTearDown(() => HttpOverrides.global = precedent);

    final fichiers = FauxGestionnaireSauvegardeFichier();
    final base = AppDatabase(NativeDatabase.memory());
    final db = await lancerApp(
      tester,
      base: base,
      geoloc: FauxGeolocalisationService.refus(),
      fichiers: fichiers,
      surcharges: [
        geocodageServiceProvider.overrideWith(
          (ref) =>
              GeocodageServiceImpl(NominatimClient(httpClient: reseau.client)),
        ),
        meteoServiceProvider.overrideWith(
          (ref) => MeteoServiceImpl(
            base,
            OpenMeteoClient(httpClient: reseau.client),
          ),
        ),
      ],
    );
    final l10n = _l10n(tester);

    // Onboarding, then a plantation through the zone screen.
    await _onboarding(tester, 'Jardin E2E', nomZone: 'Zone E2E');
    expect(find.text('Zone E2E'), findsWidgets);
    await _taper(tester, 'Zone E2E');
    await _taper(tester, l10n.zoneDetailAjouterPlante);
    final carte = find
        .ancestor(
          of: find.byIcon(PhosphorIconsRegular.leaf).first,
          matching: find.byType(InkWell),
        )
        .first;
    final plante = tester
        .widget<Text>(
          find.descendant(of: carte, matching: find.byType(Text)).first,
        )
        .data!;
    await tester.tap(carte);
    await tester.pumpAndSettle();
    await _taper(tester, l10n.ficheAjouterAuPotager);
    await _taper(tester, l10n.actionEnregistrer);
    expect(find.text(plante), findsWidgets);
    expect((await db.select(db.plantations).get()), hasLength(1));

    // Export.
    await _ouvrirDonnees(tester);
    final avant = await instantane(db);
    await _taper(tester, l10n.donneesExportBouton);
    expect(fichiers.dernierPartage, isNotNull);

    // Reset: two confirmations, then the first-run gate comes back.
    await _taper(tester, l10n.donneesResetBouton);
    await _taper(tester, l10n.donneesResetConfirmer1);
    await _taper(tester, l10n.donneesResetConfirmer2);
    expect(find.text(l10n.onboardingBienvenueTitre), findsOneWidget);
    expect(find.text('Zone E2E'), findsNothing);
    final conteneur = ProviderScope.containerOf(
      tester.element(find.byType(Navigator).first),
    );
    expect(
      conteneur.read(pileNavigationProvider.notifier).peutRevenir,
      isFalse,
    );
    expect(await db.select(db.parcelles).get(), isEmpty);

    // A fresh onboarding is the only way to reach the settings; then import.
    await _onboarding(tester, 'Jardin provisoire');
    await _ouvrirDonnees(tester);
    fichiers.aLire = fichiers.dernierPartage;
    await _taper(tester, l10n.donneesImportBouton);
    await _taper(tester, l10n.donneesImportModeRemplacer);
    expect(find.text(l10n.donneesImportSucces), findsOneWidget);

    // Everything is back.
    await _taper(tester, l10n.navPotager);
    expect((await db.select(db.potagers).get()).map((p) => p.nom), [
      'Jardin E2E',
    ]);
    expect(find.text('Zone E2E'), findsWidgets);
    await _taper(tester, 'Zone E2E');
    expect(find.text(plante), findsWidgets);
    expect(await instantane(db), equals(avant));

    expect(reseau.tentatives, greaterThan(0));
    expect(sockets.tentatives, 0);
  });
}
