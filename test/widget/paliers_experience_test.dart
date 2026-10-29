// Experience-tier matrix: what each level sees on the real screens.
//
// The level is injected through the stored preferences, so the whole chain
// (preferences -> accesNiveauProvider -> widget) is exercised.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/horloge_provider.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/providers/service_providers.dart';
import 'package:pot_a_gerer/application/use_cases/generer_taches_arrosage.dart';
import 'package:pot_a_gerer/domain/entities/bioagresseur.dart';
import 'package:pot_a_gerer/domain/entities/famille_botanique.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/niveau_experience.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/enums/type_releve_meteo.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_equipement_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_famille_botanique_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_favori_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_geolocalisation_service.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_meteo_service.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_plantation_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_preferences_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_recolte_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_tache_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/arrosage_detaille.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/domain/value_objects/prevision_meteo.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/forms/formulaire_zone.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_accueil.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_calendrier.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_catalogue.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_potager.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_zone_detail.dart';
import 'package:pot_a_gerer/presentation/screens/parametres/panneau_confidentialite.dart';
import 'package:pot_a_gerer/presentation/screens/parametres/panneau_notifications.dart';
import 'package:pot_a_gerer/presentation/widgets/carte_teaser_palier.dart';
import 'package:pot_a_gerer/presentation/widgets/fiche_plante_detail.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class _MockPotagers extends Mock implements AbstractPotagerRepository {}

class _MockParcelles extends Mock implements AbstractParcelleRepository {}

class _MockPlantations extends Mock implements AbstractPlantationRepository {}

class _MockFiches extends Mock implements AbstractFichePlanteRepository {}

class _MockTaches extends Mock implements AbstractTacheRepository {}

class _MockPreferences extends Mock implements AbstractPreferencesRepository {}

class _MockEquipements extends Mock implements AbstractEquipementRepository {}

class _MockRecoltes extends Mock implements AbstractRecolteRepository {}

class _MockMeteo extends Mock implements AbstractMeteoService {}

class _MockGeoloc extends Mock implements AbstractGeolocalisationService {}

class _MockFavoris extends Mock implements AbstractFavoriRepository {}

class _MockFamilles extends Mock
    implements AbstractFamilleBotaniqueRepository {}

class _FakePrefs extends Fake implements PreferencesUtilisateur {}

class _StubGenererTachesArrosage implements GenererTachesArrosage {
  @override
  Future<void> executer() async {}
}

const _tous = {...NiveauExperience.values};
const _intermediairePlus = {
  NiveauExperience.intermediaire,
  NiveauExperience.expert,
};
const _expertSeul = {NiveauExperience.expert};

void main() {
  setUpAll(() {
    registerFallbackValue(_FakePrefs());
    registerFallbackValue(CibleTache.parcelle);
    registerFallbackValue(const Localisation.nonDefinie());
  });

  final maintenant = DateTime(2026, 6, 9, 8, 24);

  late _MockPotagers potagers;
  late _MockParcelles parcelles;
  late _MockPlantations plantations;
  late _MockFiches fiches;
  late _MockTaches taches;
  late _MockPreferences preferences;
  late _MockEquipements equipements;
  late _MockRecoltes recoltes;
  late _MockMeteo meteo;
  late _MockGeoloc geoloc;
  late _MockFavoris favoris;
  late _MockFamilles familles;

  FichePlante fiche({bool arrosageDetaille = false}) => FichePlante(
    id: 'tomate',
    nomScientifique: 'Solanum lycopersicum',
    familleBotanique: 'solanaceae',
    rotationFamille: 'solanaceae',
    categorie: CategoriePlante.legume,
    usages: const {UsagePlante.alimentaire},
    nomsLocalises: const {'fr': 'Tomate'},
    besoins: BesoinsCulture(
      eau: BesoinEau.eleve,
      soleil: NiveauSoleil.pleinSoleil,
      phMin: 6,
      phMax: 7,
      arrosageDetaille: arrosageDetaille
          ? ArrosageDetaille(
              frequenceJoursMin: 2,
              frequenceJoursMax: 3,
              volumeLitresM2Min: 3,
              volumeLitresM2Max: 5,
            )
          : null,
    ),
    espacementCm: 40,
    dureeAvantRecolteJoursMin: 60,
    dureeAvantRecolteJoursMax: 80,
    delaiRetourAnnees: 4,
    periodes: const {},
  );

  final unPotager = Potager(
    id: 'pot-1',
    nom: 'Mon potager',
    zoneClimatique: const ZoneClimatique(
      TypeClimat.oceanique,
      ZoneRusticite.zone8,
    ),
    dateCreation: DateTime(2026, 1, 1),
  );

  final uneParcelle = Parcelle(
    id: 'z-1',
    nom: 'Carré nord',
    potagerId: 'pot-1',
    type: TypeParcelle.bacSureleve,
    surface: Surface.enMetresCarres(2),
    exposition: NiveauSoleil.pleinSoleil,
  );

  final unePlantation = Plantation(
    id: 'p-1',
    planteId: 'tomate',
    parcelleId: 'z-1',
    dateMiseEnPlace: DateTime(2026, 4, 1),
    methode: MethodeMiseEnPlace.semisDirect,
    surfaceOccupee: Surface.enMetresCarres(0.5),
    nombrePieds: 3,
  );

  setUp(() {
    potagers = _MockPotagers();
    parcelles = _MockParcelles();
    plantations = _MockPlantations();
    fiches = _MockFiches();
    taches = _MockTaches();
    preferences = _MockPreferences();
    equipements = _MockEquipements();
    recoltes = _MockRecoltes();
    meteo = _MockMeteo();
    geoloc = _MockGeoloc();
    favoris = _MockFavoris();
    familles = _MockFamilles();
    when(() => familles.obtenirToutes()).thenAnswer((_) async => []);

    when(
      () => potagers.obtenirPotagerActif(),
    ).thenAnswer((_) async => unPotager);
    when(() => potagers.obtenirTous()).thenAnswer((_) async => [unPotager]);
    when(
      () => parcelles.obtenirParPotager('pot-1'),
    ).thenAnswer((_) async => [uneParcelle]);
    when(
      () => parcelles.obtenirParId('z-1'),
    ).thenAnswer((_) async => uneParcelle);
    when(
      () => plantations.obtenirParParcelle('z-1'),
    ).thenAnswer((_) async => [unePlantation]);
    when(
      () => plantations.obtenirParId('p-1'),
    ).thenAnswer((_) async => unePlantation);
    when(() => fiches.obtenirParId('tomate')).thenAnswer((_) async => fiche());
    when(() => fiches.obtenirToutes()).thenAnswer((_) async => [fiche()]);
    when(
      () => taches.obtenirEntreDates(any(), any()),
    ).thenAnswer((_) async => []);
    when(
      () => taches.obtenirParCible(any(), any()),
    ).thenAnswer((_) async => []);
    when(
      () => equipements.obtenirParParcelle(any()),
    ).thenAnswer((_) async => []);
    when(
      () => recoltes.obtenirParPlantation(any()),
    ).thenAnswer((_) async => []);
    when(() => preferences.sauvegarder(any())).thenAnswer((_) async {});
    when(() => preferences.sontIllisibles()).thenAnswer((_) async => false);
    when(() => favoris.obtenirIds()).thenAnswer((_) async => <String>{});
    when(() => meteo.obtenirElevation(any())).thenAnswer((_) async => null);
    when(
      () => meteo.obtenirPrevisions(
        any(),
        any(),
        joursPasses: any(named: 'joursPasses'),
      ),
    ).thenAnswer(
      (_) async => [
        PrevisionMeteo(
          date: DateTime(2026, 6, 9),
          tempMin: 14,
          tempMax: 30,
          precipitationsMm: 0,
          type: TypeReleveMeteo.prevu,
        ),
      ],
    );
  });

  /// Mounts [home] with the level stored in the preferences.
  Future<void> monter(
    WidgetTester tester,
    NiveauExperience niveau,
    Widget home,
  ) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    when(
      () => preferences.charger(),
    ).thenAnswer((_) async => PreferencesUtilisateur(niveauExperience: niveau));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesRepositoryProvider.overrideWithValue(preferences),
          potagerRepositoryProvider.overrideWithValue(potagers),
          parcelleRepositoryProvider.overrideWithValue(parcelles),
          plantationRepositoryProvider.overrideWithValue(plantations),
          fichePlanteRepositoryProvider.overrideWith((ref) async => fiches),
          tacheRepositoryProvider.overrideWithValue(taches),
          equipementRepositoryProvider.overrideWithValue(equipements),
          recolteRepositoryProvider.overrideWithValue(recoltes),
          favoriRepositoryProvider.overrideWithValue(favoris),
          meteoServiceProvider.overrideWithValue(meteo),
          geolocalisationServiceProvider.overrideWithValue(geoloc),
          familleBotaniqueRepositoryProvider.overrideWith(
            (ref) async => familles,
          ),
          famillesParIdProvider.overrideWith(
            (ref) async => {
              'solanaceae': FamilleBotanique(
                id: 'solanaceae',
                nomScientifique: 'Solanaceae',
                categories: const {CategoriePlante.legume},
                nomsLocalises: const {'fr': 'Solanacées'},
              ),
            },
          ),
          bioagresseursParIdProvider.overrideWith(
            (ref) async => <String, Bioagresseur>{},
          ),
          horlogeProvider.overrideWithValue(() => maintenant),
          genererTachesArrosageProvider.overrideWith(
            (ref) async => _StubGenererTachesArrosage(),
          ),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  AppLocalizations l10nDe(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;

  /// One test per level: [cible] must be present exactly when the level is in
  /// [visibles], absent otherwise.
  void ligne(
    String libelle,
    Set<NiveauExperience> visibles,
    Future<void> Function(WidgetTester, NiveauExperience) ouvrir,
    Finder Function(AppLocalizations l10n) cible,
  ) {
    for (final niveau in NiveauExperience.values) {
      final visible = visibles.contains(niveau);
      testWidgets(
        '$libelle: ${visible ? 'visible' : 'hidden'} for ${niveau.name}',
        (tester) async {
          await ouvrir(tester, niveau);
          expect(
            cible(l10nDe(tester)),
            visible ? findsOneWidget : findsNothing,
          );
        },
      );
    }
  }

  Future<void> ouvrirMenuPotager(WidgetTester tester) async {
    await tester.tap(find.byIcon(PhosphorIconsRegular.dotsThreeVertical));
    await tester.pumpAndSettle();
  }

  Future<void> ecranPotager(WidgetTester tester, NiveauExperience n) =>
      monter(tester, n, const EcranPotager());

  Future<void> ecranPotagerMenu(WidgetTester tester, NiveauExperience n) async {
    await ecranPotager(tester, n);
    await ouvrirMenuPotager(tester);
  }

  Future<void> formulaireZone(WidgetTester tester, NiveauExperience n) =>
      monter(tester, n, const FormulaireZone(potagerId: 'pot-1'));

  Future<void> catalogue(WidgetTester tester, NiveauExperience n) =>
      monter(tester, n, const EcranCatalogue());

  Future<void> calendrier(WidgetTester tester, NiveauExperience n) =>
      monter(tester, n, const EcranCalendrier());

  Future<void> detailZone(WidgetTester tester, NiveauExperience n) =>
      monter(tester, n, const EcranZoneDetail(zoneId: 'z-1'));

  Future<void> menuCulture(WidgetTester tester, NiveauExperience n) async {
    await detailZone(tester, n);
    await tester.tap(find.byTooltip(l10nDe(tester).cultureActions));
    await tester.pumpAndSettle();
  }

  Future<void> ficheDetail(WidgetTester tester, NiveauExperience n) async {
    await monter(
      tester,
      n,
      Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => afficherFichePlanteDetail(
              context,
              fiche(arrosageDetaille: true),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('core is available at every level', () {
    ligne('garden screen', _tous, ecranPotager, (l) => find.text(l.navPotager));
    ligne('zone and its crop', _tous, detailZone, (l) => find.text('Tomate'));
    ligne('plant catalogue list', _tous, catalogue, (l) => find.text('Tomate'));
    ligne(
      'agenda view',
      _tous,
      calendrier,
      (l) => find.text(l.calendrierVueAgenda),
    );
  });

  group('equipment', () {
    ligne(
      'garden menu entry',
      _intermediairePlus,
      ecranPotagerMenu,
      (l) => find.text(l.equipTitre),
    );
    ligne(
      'zone section',
      _intermediairePlus,
      detailZone,
      (l) => find.text(l.zoneEquipementsTitre),
    );
  });

  group('soil techniques', () {
    ligne(
      'zone form',
      _intermediairePlus,
      formulaireZone,
      (l) => find.text(l.formZoneTechniquesTitre),
    );
  });

  group('network view', () {
    ligne(
      'catalogue toggle',
      _intermediairePlus,
      catalogue,
      (l) => find.text(l.catalogueVueReseau),
    );

    for (final niveau in NiveauExperience.values) {
      final teaser = niveau == NiveauExperience.debutant;
      testWidgets(
        'catalogue teaser: ${teaser ? 'shown' : 'absent'} for ${niveau.name}',
        (tester) async {
          await catalogue(tester, niveau);
          expect(
            find.byType(CarteTeaserPalier),
            teaser ? findsOneWidget : findsNothing,
          );
        },
      );
    }
  });

  group('observations', () {
    ligne(
      'crop menu entry',
      _intermediairePlus,
      menuCulture,
      (l) => find.text(l.cultureObserver),
    );
  });

  group('season view', () {
    ligne(
      'calendar segment',
      _intermediairePlus,
      calendrier,
      (l) => find.text(l.calendrierVueSaison),
    );

    for (final niveau in NiveauExperience.values) {
      final teaser = niveau == NiveauExperience.debutant;
      testWidgets(
        'calendar teaser: ${teaser ? 'shown' : 'absent'} for ${niveau.name}',
        (tester) async {
          await calendrier(tester, niveau);
          expect(
            find.byType(CarteTeaserPalier),
            teaser ? findsOneWidget : findsNothing,
          );
        },
      );
    }
  });

  group('multi-garden', () {
    ligne(
      'garden menu entry',
      _intermediairePlus,
      ecranPotagerMenu,
      (l) => find.text(l.potagerChangerDe),
    );
  });

  group('water needs', () {
    ligne('coarse need', _tous, ficheDetail, (l) => find.text(l.ficheArrosage));
    ligne(
      'detailed need',
      _expertSeul,
      ficheDetail,
      (l) => find.text(l.ficheArrosageDetailleTitre),
    );
  });

  group('soil texture and pH', () {
    ligne(
      'texture field',
      _expertSeul,
      formulaireZone,
      (l) => find.text(l.formZoneTexture),
    );
    ligne(
      'pH field',
      _expertSeul,
      formulaireZone,
      (l) => find.text(l.formZonePh),
    );
  });

  group('dashboard stats', () {
    ligne(
      'season harvest tile',
      _expertSeul,
      (t, n) => monter(t, n, const EcranAccueil()),
      (l) => find.text(l.accueilRecoltesSaison(0)),
    );
    ligne(
      'locked tile',
      {NiveauExperience.debutant, NiveauExperience.intermediaire},
      (t, n) => monter(t, n, const EcranAccueil()),
      (l) => find.text(l.accueilStatsVerrouillees),
    );
  });

  group('advanced rotation', () {
    ligne(
      'zone section',
      _expertSeul,
      detailZone,
      (l) => find.text(l.zoneRotationTitre),
    );
  });

  group('custom plant sheets', () {
    ligne(
      'catalogue entry point',
      _expertSeul,
      catalogue,
      (l) => find.byTooltip(l.fichesPersoOuvrir),
    );
  });

  group('lunar calendar option', () {
    ligne(
      'privacy switch',
      _intermediairePlus,
      (t, n) => monter(t, n, const PanneauConfidentialite()),
      (l) => find.text(l.confidLunaire),
    );
  });

  group('notification granularity', () {
    ligne(
      'master switch',
      _tous,
      (t, n) => monter(t, n, const PanneauNotifications()),
      (l) => find.text(l.notifMaster),
    );
    ligne(
      'per-category section',
      _intermediairePlus,
      (t, n) => monter(t, n, const PanneauNotifications()),
      (l) => find.text(l.notifParCategorie),
    );
  });

  group('advice verbosity', () {
    // Defect: the watering advice is a fixed one-liner per urgency; it does not
    // depend on the experience level, so beginner and expert read the same text.
    testWidgets('advice verbosity differs by level', skip: true, (
      tester,
    ) async {
      Future<List<String>> conseil(NiveauExperience n) async {
        await detailZone(tester, n);
        final ligneConseil = find
            .ancestor(
              of: find.byIcon(PhosphorIconsBold.drop),
              matching: find.byType(Row),
            )
            .first;
        return tester
            .widgetList<Text>(
              find.descendant(of: ligneConseil, matching: find.byType(Text)),
            )
            .map((t) => t.data ?? '')
            .toList();
      }

      final debutant = await conseil(NiveauExperience.debutant);
      expect(debutant, isNotEmpty);
      await tester.pumpWidget(const SizedBox());
      final expert = await conseil(NiveauExperience.expert);

      expect(expert, isNot(equals(debutant)));
    });
  });
}
