// Widget tests for the "À propos" settings panel: the version is read from
// [AbstractInfoApplicationService] rather than a hardcoded constant.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/application/providers/service_providers.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_info_application_service.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_ouverture_lien_service.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/screens/parametres/panneau_a_propos.dart';

class _MockInfoApplication extends Mock
    implements AbstractInfoApplicationService {}

class _MockOuvertureLien extends Mock implements AbstractOuvertureLienService {}

void main() {
  setUpAll(() => registerFallbackValue(Uri.parse('https://example.org')));

  late _MockInfoApplication service;
  late _MockOuvertureLien lienService;

  setUp(() {
    service = _MockInfoApplication();
    when(() => service.obtenirVersionAffichee())
        .thenAnswer((_) async => '9.9.9+42');
    lienService = _MockOuvertureLien();
  });

  Future<void> monter(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          infoApplicationServiceProvider.overrideWithValue(service),
          ouvertureLienServiceProvider.overrideWithValue(lienService),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PanneauAPropos(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the version reported by the info service', (tester) async {
    await monter(tester);

    expect(find.text('Version 9.9.9+42'), findsOneWidget);
  });

  testWidgets('the licence page reports the same version', (tester) async {
    await monter(tester);

    await tester.tap(find.text('Licences open source'));
    await tester.pumpAndSettle();

    expect(find.text('9.9.9+42'), findsOneWidget);
  });

  testWidgets('tapping "code source" opens the repo URL', (tester) async {
    when(() => lienService.ouvrir(any())).thenAnswer((_) async => true);
    await monter(tester);

    await tester.tap(find.text('Code source'));
    await tester.pumpAndSettle();

    verify(() => lienService.ouvrir(
          Uri.parse('https://github.com/Asch3nte/vege-garden-manager'),
        )).called(1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('shows a snackbar when no handler can open the link',
      (tester) async {
    when(() => lienService.ouvrir(any())).thenAnswer((_) async => false);
    await monter(tester);

    await tester.tap(find.text('Code source'));
    await tester.pumpAndSettle();

    expect(find.text("Impossible d'ouvrir ce lien."), findsOneWidget);
  });
}
