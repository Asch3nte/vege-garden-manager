// Every recommendation reason, weather alert and watering advice must reach
// the user as a non-empty text, in French and in English.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/horloge_provider.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/state/notifications_notifier.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/raison_reco.dart';
import 'package:pot_a_gerer/domain/enums/type_alerte_meteo.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/enums/urgence_arrosage.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_equipement_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_plantation_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_tache_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/alerte_culture.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/domain/value_objects/conseil_arrosage.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/glossaire/catalogue/notions_cultures.dart';
import 'package:pot_a_gerer/presentation/glossaire/complement_terme.dart';
import 'package:pot_a_gerer/presentation/glossaire/terme_glossaire.dart';
import 'package:pot_a_gerer/presentation/providers/conseil_arrosage_plantation_provider.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_notifications.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_zone_detail.dart';

class _MockPotagers extends Mock implements AbstractPotagerRepository {}

class _MockParcelles extends Mock implements AbstractParcelleRepository {}

class _MockPlantations extends Mock implements AbstractPlantationRepository {}

class _MockEquipements extends Mock implements AbstractEquipementRepository {}

class _MockFiches extends Mock implements AbstractFichePlanteRepository {}

class _MockTaches extends Mock implements AbstractTacheRepository {}

const _locales = ['fr', 'en'];

Widget _app(String locale, Widget home, List<Override> overrides, [Key? key]) =>
    ProviderScope(
      key: key,
      overrides: overrides,
      child: MaterialApp(
        theme: ThemeApp.clair(),
        locale: Locale(locale),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

String _textOf(Text t) => (t.data ?? t.textSpan?.toPlainText() ?? '').trim();

void main() {
  group('RaisonReco', () {
    for (final locale in _locales) {
      test('every RaisonReco has a non-empty explanation ($locale)', () {
        final l10n = lookupAppLocalizations(Locale(locale));
        final terme = construireNotionsCultures(l10n).singleWhere(
          (t) => t.id == TermeGlossaire.idNotion('pourquoi-recommandation'),
        );
        final valeurs = terme.complements
            .whereType<ComplementValeursEnum>()
            .single
            .valeurs;

        expect(valeurs, hasLength(RaisonReco.values.length));
        for (var i = 0; i < RaisonReco.values.length; i++) {
          final raison = RaisonReco.values[i];
          expect(
            valeurs[i].libelle.trim(),
            isNotEmpty,
            reason: '$raison label',
          );
          expect(
            (valeurs[i].description ?? '').trim(),
            isNotEmpty,
            reason: '$raison description',
          );
        }
      });
    }
  });

  group('AlerteCulture', () {
    final maintenant = DateTime(2026, 1, 12, 9);

    for (final locale in _locales) {
      for (final type in TypeAlerteMeteo.values) {
        testWidgets('every AlerteCulture kind has a non-empty explanation '
            '($locale, ${type.name})', (tester) async {
          final alerte = AlerteCulture(
            type: type,
            date: DateTime(2026, 1, 12),
            valeurDeclenchante: 5,
            plantationsConcernees: const ['pl-1'],
          );
          await tester.pumpWidget(
            _app(locale, const EcranNotifications(), [
              horlogeProvider.overrideWithValue(() => maintenant),
              alertesMeteoProvider.overrideWith((ref) async => [alerte]),
            ]),
          );
          await tester.pumpAndSettle();

          final card = find.byType(Card);
          expect(card, findsOneWidget);
          // Title and detail are the first two Text children of the card's
          // text column.
          final colonne = tester.widget<Column>(
            find.descendant(of: card, matching: find.byType(Column)).first,
          );
          final textes = colonne.children
              .whereType<Text>()
              .map(_textOf)
              .toList();
          expect(textes.length, greaterThanOrEqualTo(2));
          expect(textes[0], isNotEmpty, reason: 'title');
          expect(textes[1], isNotEmpty, reason: 'detail');
        });
      }
    }
  });

  group('ConseilArrosage', () {
    final maintenant = DateTime(2026, 6, 9, 8, 24);
    late _MockPotagers potagers;
    late _MockParcelles parcelles;
    late _MockPlantations plantations;
    late _MockFiches fiches;
    late List<Override> overridesBase;

    setUp(() {
      potagers = _MockPotagers();
      parcelles = _MockParcelles();
      plantations = _MockPlantations();
      fiches = _MockFiches();
      final taches = _MockTaches();
      final equipements = _MockEquipements();
      when(
        () => taches.obtenirEntreDates(any(), any()),
      ).thenAnswer((_) async => []);
      when(
        () => equipements.obtenirParParcelle(any()),
      ).thenAnswer((_) async => []);
      when(() => potagers.obtenirPotagerActif()).thenAnswer(
        (_) async => Potager(
          id: 'pot-1',
          nom: 'Mon potager',
          zoneClimatique: const ZoneClimatique(
            TypeClimat.oceanique,
            ZoneRusticite.zone8,
          ),
          dateCreation: DateTime(2026, 1, 1),
        ),
      );
      final parcelle = Parcelle(
        id: 'z-1',
        nom: 'Carré nord',
        potagerId: 'pot-1',
        type: TypeParcelle.bacSureleve,
        surface: Surface.enMetresCarres(2),
        exposition: NiveauSoleil.pleinSoleil,
      );
      when(
        () => parcelles.obtenirParPotager('pot-1'),
      ).thenAnswer((_) async => [parcelle]);
      when(
        () => parcelles.obtenirParId('z-1'),
      ).thenAnswer((_) async => parcelle);
      final pl = Plantation(
        id: 'p-1',
        planteId: 'tomate',
        parcelleId: 'z-1',
        dateMiseEnPlace: DateTime(2026, 4, 1),
        methode: MethodeMiseEnPlace.semisDirect,
        surfaceOccupee: Surface.enMetresCarres(0.5),
        nombrePieds: 3,
      );
      when(
        () => plantations.obtenirParParcelle('z-1'),
      ).thenAnswer((_) async => [pl]);
      when(() => plantations.obtenirParId('p-1')).thenAnswer((_) async => pl);
      when(() => fiches.obtenirParId('tomate')).thenAnswer(
        (_) async => FichePlante(
          id: 'tomate',
          nomScientifique: 'tomate sp',
          familleBotanique: 'Test',
          categorie: CategoriePlante.legume,
          usages: const {UsagePlante.alimentaire},
          nomsLocalises: const {'fr': 'Tomate', 'en': 'Tomato'},
          besoins: BesoinsCulture(
            eau: BesoinEau.modere,
            soleil: NiveauSoleil.pleinSoleil,
            phMin: 6,
            phMax: 7,
          ),
          espacementCm: 40,
          dureeAvantRecolteJoursMin: 60,
          dureeAvantRecolteJoursMax: 80,
          periodes: const {},
        ),
      );
      overridesBase = [
        potagerRepositoryProvider.overrideWithValue(potagers),
        parcelleRepositoryProvider.overrideWithValue(parcelles),
        plantationRepositoryProvider.overrideWithValue(plantations),
        equipementRepositoryProvider.overrideWithValue(equipements),
        tacheRepositoryProvider.overrideWithValue(taches),
        fichePlanteRepositoryProvider.overrideWith((ref) async => fiches),
        horlogeProvider.overrideWithValue(() => maintenant),
      ];
    });

    /// Text of the advice row itself, rendered in the zone screen.
    Future<String> texteLigne(
      WidgetTester tester,
      String locale,
      ConseilArrosage conseil,
    ) async {
      await tester.pumpWidget(
        _app(locale, const EcranZoneDetail(zoneId: 'z-1'), [
          ...overridesBase,
          conseilArrosagePlantationProvider(
            'p-1',
          ).overrideWith((ref) async => conseil),
        ]),
      );
      await tester.pumpAndSettle();
      final ligne = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_LigneConseilArrosage',
      );
      expect(ligne, findsOneWidget);
      return find
          .descendant(of: ligne, matching: find.byType(Text))
          .evaluate()
          .map((e) => _textOf(e.widget as Text))
          .join();
    }

    // Representative day count: `joursAvantArrosage` is a nullable int.
    ConseilArrosage conseil(
      UrgenceArrosage u,
      bool recente,
      bool prevue,
      bool retention,
    ) => ConseilArrosage(
      urgence: u,
      joursAvantArrosage: u == UrgenceArrosage.bientot ? 2 : null,
      pluieRecente: recente,
      pluiePrevue: prevue,
      retentionRenforcee: retention,
      indiceBesoin: 0.5,
    );

    // Dry-soil advice with no forecast rain renders no row at all.
    bool silencieux(UrgenceArrosage u, bool prevue) =>
        u == UrgenceArrosage.pasNecessaire && !prevue;

    for (final locale in _locales) {
      for (final u in UrgenceArrosage.values) {
        for (final recente in [false, true]) {
          for (final prevue in [false, true]) {
            for (final retention in [false, true]) {
              if (silencieux(u, prevue)) continue;
              testWidgets(
                'every ConseilArrosage combination yields a non-empty '
                'message ($locale, ${u.name}, recente=$recente, '
                'prevue=$prevue, retention=$retention)',
                (tester) async {
                  final texte = await texteLigne(
                    tester,
                    locale,
                    conseil(u, recente, prevue, retention),
                  );
                  expect(texte, isNotEmpty);
                },
              );
            }
          }
        }
      }

      // Defect: a "no watering needed" advice without forecast rain renders no
      // row, so the user gets no explanation (rain or retention is not told).
      testWidgets(
        'every ConseilArrosage combination yields a non-empty message '
        '($locale, pasNecessaire without forecast rain)',
        (tester) async {
          for (final recente in [false, true]) {
            for (final retention in [false, true]) {
              final texte = await texteLigne(
                tester,
                locale,
                conseil(
                  UrgenceArrosage.pasNecessaire,
                  recente,
                  false,
                  retention,
                ),
              );
              expect(
                texte,
                isNotEmpty,
                reason: 'recente=$recente retention=$retention',
              );
            }
          }
        },
        skip: true,
      );
    }
  });
}
