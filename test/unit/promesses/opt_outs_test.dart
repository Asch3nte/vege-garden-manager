import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/horloge_provider.dart';
import 'package:pot_a_gerer/application/state/meteo_accueil_notifier.dart';
import 'package:pot_a_gerer/application/state/notifications_notifier.dart';
import 'package:pot_a_gerer/application/state/preferences_notifier.dart';
import 'package:pot_a_gerer/application/use_cases/calculer_besoin_arrosage.dart';
import 'package:pot_a_gerer/application/use_cases/generer_taches_arrosage.dart';
import 'package:pot_a_gerer/application/use_cases/suggerer_climat_position.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/mode_geolocalisation.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/enums/urgence_arrosage.dart';
import 'package:pot_a_gerer/domain/value_objects/conseil_arrosage.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/repositories/preferences_repository_impl.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_plus.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_potager.dart';
import 'package:pot_a_gerer/presentation/widgets/astuce_post_onboarding.dart';
import 'package:pot_a_gerer/infrastructure/repositories/parcelle_repository_impl.dart';
import 'package:pot_a_gerer/infrastructure/repositories/plantation_repository_impl.dart';

import '../../helpers/faux_services_natifs.dart';
import '../../helpers/garde_reseau.dart';
import '../../helpers/potager_actif.dart';

class _MockCalcul extends Mock implements CalculerBesoinArrosage {}

class _FakeLocalisation extends Fake implements Localisation {}

class _FakePlantation extends Fake implements Plantation {}

final _bruxelles = Localisation.manuelle(
  ville: 'Bruxelles',
  latitude: 50.85,
  longitude: 4.35,
);

/// App wiring on a seeded in-memory database with a plantation to water,
/// mocked native services and a clock pinned at 07:00 (before the 08:00 push).
class _Banc {
  final AppDatabase db;
  final NotificationsDeTest notifications;
  final GeolocalisationDeTest geoloc;
  final ProviderContainer container;

  _Banc._(this.db, this.notifications, this.geoloc, this.container);

  static Future<_Banc> creer({
    bool meteoAuto = true,
    Localisation? position,
  }) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await peuplerPotagerActif(
      db,
      meteoAuto: meteoAuto,
      position: position ?? const Localisation.nonDefinie(),
    );
    await ParcelleRepositoryImpl(db).sauvegarder(
      Parcelle(
        id: 'z-1',
        nom: 'Zone',
        potagerId: 'pot-1',
        type: TypeParcelle.pleineTerre,
        surface: Surface.enMetresCarres(2),
        exposition: NiveauSoleil.pleinSoleil,
      ),
    );
    await PlantationRepositoryImpl(db).sauvegarder(
      Plantation(
        id: 'p-1',
        planteId: 'tomate',
        parcelleId: 'z-1',
        dateMiseEnPlace: DateTime(2026, 4, 1),
        methode: MethodeMiseEnPlace.semisDirect,
        surfaceOccupee: Surface.enMetresCarres(0.5),
        nombrePieds: 2,
      ),
    );
    final n = DateTime.now();
    final matin = DateTime(n.year, n.month, n.day, 7);
    final notifications = NotificationsDeTest();
    final geoloc = GeolocalisationDeTest.refus();
    registerFallbackValue(_FakeLocalisation());
    registerFallbackValue(_FakePlantation());
    final calcul = _MockCalcul();
    when(
      () => calcul.chargerFenetre(
        any(),
        meteoAutoActive: any(named: 'meteoAutoActive'),
      ),
    ).thenAnswer((_) async => const []);
    when(
      () => calcul.executer(
        plantation: any(named: 'plantation'),
        localisation: any(named: 'localisation'),
        meteoAutoActive: any(named: 'meteoAutoActive'),
        fenetre: any(named: 'fenetre'),
      ),
    ).thenAnswer(
      (_) async => ConseilArrosage(
        urgence: UrgenceArrosage.arroserMaintenant,
        joursAvantArrosage: 0,
        indiceBesoin: 0.9,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        ...surchargesDeTest(db, notifications: notifications, geoloc: geoloc),
        horlogeProvider.overrideWithValue(() => matin),
        calculerBesoinArrosageProvider.overrideWith((ref) async => calcul),
      ],
    );
    addTearDown(container.dispose);
    await container.read(preferencesProvider.future);
    return _Banc._(db, notifications, geoloc, container);
  }

  PreferencesNotifier get reglages =>
      container.read(preferencesProvider.notifier);

  Future<void> genererTachesArrosage() async {
    final cas = await container.read(genererTachesArrosageProvider.future);
    await cas.executer();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('watering generation schedules one notification by default', () async {
    final banc = await _Banc.creer();
    await banc.genererTachesArrosage();

    expect(banc.notifications.programmees, hasLength(1));
    expect(banc.notifications.programmees.single.categorie, 'arrosage');
  });

  test('opt-out global notifications is effective', () async {
    final banc = await _Banc.creer();
    await banc.genererTachesArrosage();
    expect(banc.notifications.programmees, isNotEmpty);

    await banc.reglages.definirNotificationsGlobales(false);
    await banc.genererTachesArrosage();

    expect(banc.notifications.programmees, isEmpty);
  });

  test('opt-out notification category arrosage is effective', () async {
    final banc = await _Banc.creer();
    await banc.genererTachesArrosage();
    expect(banc.notifications.programmees, isNotEmpty);

    await banc.reglages.definirNotificationCategorie('arrosage', false);
    await banc.genererTachesArrosage();

    expect(
      banc.notifications.programmees.where((n) => n.categorie == 'arrosage'),
      isEmpty,
    );
  });

  test(
    'muting another notification category keeps watering notified',
    () async {
      final banc = await _Banc.creer();
      await banc.reglages.definirNotificationCategorie('semis', false);
      await banc.genererTachesArrosage();

      expect(banc.notifications.programmees, hasLength(1));
    },
  );

  test('opt-out do-not-disturb window is effective', () async {
    final banc = await _Banc.creer();
    await banc.reglages.definirNePasDeranger('07:00', '09:00');
    await banc.genererTachesArrosage();
    expect(banc.notifications.programmees, isEmpty);

    await banc.reglages.desactiverNePasDeranger();
    await banc.genererTachesArrosage();
    expect(banc.notifications.programmees, hasLength(1));
  });

  test('opt-out auto weather is effective', () {
    return avecGardeReseau((garde) async {
      final banc = await _Banc.creer(meteoAuto: false, position: _bruxelles);

      final carte = await banc.container.read(meteoAccueilProvider.future);
      final alertes = await banc.container.read(alertesMeteoProvider.future);
      await banc.genererTachesArrosage();
      final suggestion = await banc.container
          .read(suggererClimatPositionProvider)
          .executer(_bruxelles);

      expect(carte.meteoDesactivee, isTrue);
      expect(alertes, isEmpty);
      expect(suggestion, isNull);
      expect(garde.requetes, isEmpty);
    });
  });

  test('opt-out geolocation is effective', () {
    return avecGardeReseau((garde) async {
      final banc = await _Banc.creer();
      final prefs = await banc.container.read(preferencesProvider.future);
      expect(prefs.modeGeolocalisation, ModeGeolocalisation.desactivee);

      final carte = await banc.container.read(meteoAccueilProvider.future);
      final alertes = await banc.container.read(alertesMeteoProvider.future);
      await banc.genererTachesArrosage();

      expect(carte.disponible, isFalse);
      expect(alertes, isEmpty);
      expect(garde.requetes, isEmpty);
      verifyNever(() => banc.geoloc.service.positionActuelle());
      verifyNever(() => banc.geoloc.service.demanderPermission());
    });
  });

  group('features absent from V1', () {
    final lecteursAutorises = {
      'lib/domain/entities/preferences_utilisateur.dart',
      'lib/infrastructure/mappers/preferences_mapper.dart',
      'lib/application/state/preferences_notifier.dart',
      'lib/presentation/screens/parametres/panneau_confidentialite.dart',
    };

    Set<String> lecteurs(String champ) => {
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('.dart') &&
            !f.path.endsWith('.g.dart') &&
            !f.path.contains('lib/infrastructure/database/') &&
            f.readAsStringSync().contains(champ))
          f.path,
    };

    test('opt-out local sync is effective', () {
      return avecGardeReseau((garde) async {
        final banc = await _Banc.creer();
        final defaut = await banc.container.read(preferencesProvider.future);
        expect(defaut.syncLocaleActive, isFalse);

        await banc.reglages.definirSyncLocale(true);
        await banc.genererTachesArrosage();

        expect(garde.requetes, isEmpty);
        expect(lecteurs('syncLocaleActive'), lecteursAutorises);
        for (final f in Directory('lib').listSync(recursive: true)) {
          if (f is! File || !f.path.endsWith('.dart')) continue;
          expect(
            f.readAsStringSync(),
            isNot(matches(r'ServerSocket|HttpServer|RawDatagramSocket')),
            reason: '${f.path} opens a listening socket',
          );
        }
      });
    });

    test('opt-out community is effective', () {
      return avecGardeReseau((garde) async {
        final banc = await _Banc.creer();
        final defaut = await banc.container.read(preferencesProvider.future);
        expect(defaut.communauteOptIn, isFalse);

        await banc.genererTachesArrosage();

        expect(garde.requetes, isEmpty);
        expect(lecteurs('communauteOptIn'), {
          'lib/domain/entities/preferences_utilisateur.dart',
          'lib/infrastructure/mappers/preferences_mapper.dart',
        });
      });
    });

    test('opt-out lunar calendar is effective', () async {
      final banc = await _Banc.creer();
      final defaut = await banc.container.read(preferencesProvider.future);
      expect(defaut.calendrierLunaireOptIn, isFalse);

      expect(lecteurs('calendrierLunaireOptIn'), lecteursAutorises);
    });
  });

  /// Pumps [ecran] on the real app wiring with a seeded garden, the given help
  /// settings and the post-onboarding hint raised.
  Future<void> monterAvecAide(
    WidgetTester tester,
    Widget ecran, {
    bool contextuelle = true,
    bool docComplete = true,
  }) async {
    final banc = (await tester.runAsync(_Banc.creer))!;
    final repo = PreferencesRepositoryImpl(banc.db);
    await tester.runAsync(() async {
      final prefs = await repo.charger();
      await repo.sauvegarder(
        prefs.copierAvec(
          aideContextuelleActive: contextuelle,
          aideDocCompleteActive: docComplete,
        ),
      );
    });
    banc.container.read(astucePotagerZonesProvider.notifier).afficher();
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: banc.container,
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: ecran,
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  // Contextual help is not gated by its setting: the post-onboarding hint on
  // the garden screen is still shown with the setting off. Asserts the
  // behaviour; should pass once `aideContextuelleActive` is wired.
  testWidgets('opt-out contextual help is effective', (tester) async {
    const astuce = 'Touchez une zone pour y ajouter vos plantes.';
    await monterAvecAide(tester, const EcranPotager());
    expect(find.text(astuce), findsOneWidget);

    await monterAvecAide(tester, const EcranPotager(), contextuelle: false);
    expect(find.text(astuce), findsNothing);
  }, skip: true);

  // The « Aide & lexique » entry is not gated by its setting: it is still
  // listed with the setting off. Asserts the behaviour; should pass once
  // `aideDocCompleteActive` is wired.
  testWidgets('opt-out full documentation help is effective', (tester) async {
    await monterAvecAide(tester, const EcranPlus());
    expect(find.text('Aide & lexique'), findsOneWidget);

    await monterAvecAide(tester, const EcranPlus(), docComplete: false);
    expect(find.text('Aide & lexique'), findsNothing);
  }, skip: true);
}
