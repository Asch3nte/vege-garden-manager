import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/horloge_provider.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/entities/tache.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/etat_tache.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/priorite_tache.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_tache_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_tache_detail.dart';

class _MockTaches extends Mock implements AbstractTacheRepository {}

class _MockParcelles extends Mock implements AbstractParcelleRepository {}

class _FakeTache extends Fake implements Tache {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeTache()));

  final maintenant = DateTime(2026, 6, 9, 8);

  late _MockTaches taches;
  late _MockParcelles parcelles;

  Tache uneTache({bool faite = false}) => Tache(
        id: 't-1',
        titre: 'Arroser les tomates',
        type: TypeTache.arrosage,
        cible: CibleTache.parcelle,
        cibleId: 'z-1',
        datePrevue: DateTime(2026, 6, 9),
        priorite: PrioriteTache.urgente,
        etat: faite ? EtatTache.terminee : EtatTache.aFaire,
        dateRealisation: faite ? maintenant : null,
      );

  setUp(() {
    taches = _MockTaches();
    parcelles = _MockParcelles();
    when(() => parcelles.obtenirParId('z-1')).thenAnswer(
      (_) async => Parcelle(
        id: 'z-1',
        nom: 'Carré nord',
        potagerId: 'pot-1',
        type: TypeParcelle.bacSureleve,
        surface: Surface.enMetresCarres(1),
        exposition: NiveauSoleil.pleinSoleil,
      ),
    );
  });

  overrides() => [
        tacheRepositoryProvider.overrideWithValue(taches),
        parcelleRepositoryProvider.overrideWithValue(parcelles),
        horlogeProvider.overrideWithValue(() => maintenant),
      ];

  Future<void> monter(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/calendrier/tache/t-1',
      routes: [
        GoRoute(
          path: '/calendrier',
          builder: (_, _) => const Scaffold(body: Text('Agenda')),
          routes: [
            GoRoute(
              path: 'tache/:id',
              builder: (_, state) =>
                  EcranTacheDetail(tacheId: state.pathParameters['id']!),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp.router(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the task fields and its target name', (tester) async {
    when(() => taches.obtenirParId('t-1')).thenAnswer((_) async => uneTache());

    await monter(tester);

    expect(find.text('Arroser les tomates'), findsOneWidget);
    expect(find.text('À faire'), findsOneWidget);
    expect(find.textContaining('Urgente'), findsOneWidget);
    expect(find.textContaining('Carré nord'), findsOneWidget);
    expect(find.text('Marquer comme faite'), findsOneWidget);
  });

  testWidgets('the action button ticks the task off (persisted)',
      (tester) async {
    final tache = uneTache();
    when(() => taches.obtenirParId('t-1')).thenAnswer((_) async => tache);
    when(() => taches.sauvegarder(any())).thenAnswer((_) async {});

    await monter(tester);
    await tester.tap(find.text('Marquer comme faite'));
    await tester.pumpAndSettle();

    expect(tache.estFaite, isTrue);
    verify(() => taches.sauvegarder(tache)).called(1);
  });

  testWidgets('deleting from the menu confirms then returns to the calendar',
      (tester) async {
    when(() => taches.obtenirParId('t-1')).thenAnswer((_) async => uneTache());
    when(() => taches.supprimer('t-1')).thenAnswer((_) async {});

    await monter(tester);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
    await tester.pumpAndSettle();

    verify(() => taches.supprimer('t-1')).called(1);
    expect(find.text('Agenda'), findsOneWidget); // navigated back to calendar
  });
}
