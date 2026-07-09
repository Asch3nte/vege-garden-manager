import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/state/preferences_notifier.dart';
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/enums/famille_effet_association.dart';
import 'package:pot_a_gerer/domain/enums/langue.dart';
import 'package:pot_a_gerer/domain/enums/poids_association.dart';
import 'package:pot_a_gerer/domain/enums/mode_geolocalisation.dart';
import 'package:pot_a_gerer/domain/enums/niveau_experience.dart';
import 'package:pot_a_gerer/domain/enums/theme_app.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_preferences_repository.dart';

class MockPreferences extends Mock implements AbstractPreferencesRepository {}

class _FakePrefs extends Fake implements PreferencesUtilisateur {}

void main() {
  setUpAll(() => registerFallbackValue(_FakePrefs()));

  late MockPreferences repo;

  setUp(() {
    repo = MockPreferences();
    when(() => repo.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());
    when(() => repo.sauvegarder(any())).thenAnswer((_) async {});
  });

  ProviderContainer conteneur() {
    final c = ProviderContainer(overrides: [
      preferencesRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('loads the stored preferences', () async {
    when(() => repo.charger()).thenAnswer(
      (_) async => PreferencesUtilisateur(niveauExperience: NiveauExperience.expert),
    );

    final prefs = await conteneur().read(preferencesProvider.future);

    expect(prefs.niveauExperience, NiveauExperience.expert);
  });

  test('a setter applies the change, persists it and publishes it', () async {
    final c = conteneur();
    await c.read(preferencesProvider.future);

    await c.read(preferencesProvider.notifier).definirLangue(Langue.en);

    final captured = verify(() => repo.sauvegarder(captureAny())).captured;
    expect((captured.single as PreferencesUtilisateur).langue, Langue.en);
    expect(c.read(preferencesProvider).value!.langue, Langue.en);
  });

  test('theme, geolocation and level setters round-trip', () async {
    final c = conteneur();
    await c.read(preferencesProvider.future);
    final notifier = c.read(preferencesProvider.notifier);

    await notifier.definirTheme(ThemeApp.sombre);
    await notifier.definirGeolocalisation(ModeGeolocalisation.gps);
    await notifier.definirNiveau(NiveauExperience.intermediaire);

    final prefs = c.read(preferencesProvider).value!;
    expect(prefs.theme, ThemeApp.sombre);
    expect(prefs.modeGeolocalisation, ModeGeolocalisation.gps);
    expect(prefs.niveauExperience, NiveauExperience.intermediaire);
  });

  test('toggling sync persists the boolean opt-out', () async {
    final c = conteneur();
    await c.read(preferencesProvider.future);

    await c.read(preferencesProvider.notifier).definirSyncLocale(true);

    expect(c.read(preferencesProvider).value!.syncLocaleActive, isTrue);
  });

  test('terminerOnboarding marks the flag and persists it', () async {
    final c = conteneur();
    await c.read(preferencesProvider.future);

    await c.read(preferencesProvider.notifier).terminerOnboarding();

    final captured = verify(() => repo.sauvegarder(captureAny())).captured;
    expect((captured.single as PreferencesUtilisateur).onboardingTermine,
        isTrue);
    expect(c.read(preferencesProvider).value!.onboardingTermine, isTrue);
  });

  test('a notification category toggle updates only that key', () async {
    final c = conteneur();
    await c.read(preferencesProvider.future);

    await c.read(preferencesProvider.notifier)
        .definirNotificationCategorie('arrosage', false);

    final map = c.read(preferencesProvider).value!.notificationsParCategorie;
    expect(map['arrosage'], isFalse);
  });

  test('definirMeteoAuto toggles and persists the automatic-weather opt-out',
      () async {
    final c = conteneur();
    await c.read(preferencesProvider.future);
    final notifier = c.read(preferencesProvider.notifier);

    expect(c.read(preferencesProvider).value!.meteoAutoActive, isTrue); // default

    await notifier.definirMeteoAuto(false);

    final captured = verify(() => repo.sauvegarder(captureAny())).captured;
    expect((captured.last as PreferencesUtilisateur).meteoAutoActive, isFalse);
    expect(c.read(preferencesProvider).value!.meteoAutoActive, isFalse);
  });

  test('do-not-disturb setter stores the window, and clearing removes it',
      () async {
    final c = conteneur();
    await c.read(preferencesProvider.future);
    final notifier = c.read(preferencesProvider.notifier);

    await notifier.definirNePasDeranger('22:00', '07:00');
    var prefs = c.read(preferencesProvider).value!;
    expect(prefs.nePasDerangerActif, isTrue);
    expect(prefs.nePasDerangerDebut, '22:00');
    expect(prefs.nePasDerangerFin, '07:00');

    await notifier.desactiverNePasDeranger();
    prefs = c.read(preferencesProvider).value!;
    expect(prefs.nePasDerangerActif, isFalse);
    expect(prefs.nePasDerangerDebut, isNull);
    expect(prefs.nePasDerangerFin, isNull);
  });

  test('setting an association weight updates only that family (ADR-0011)',
      () async {
    final c = conteneur();
    await c.read(preferencesProvider.future);

    await c.read(preferencesProvider.notifier).definirPoidsAssociation(
        FamilleEffetAssociation.protectionRavageurs, PoidsAssociation.ignore);

    final profil = c.read(preferencesProvider).value!.ponderationAssociations;
    expect(profil.poids(FamilleEffetAssociation.protectionRavageurs),
        PoidsAssociation.ignore);
    expect(profil.poids(FamilleEffetAssociation.fertilite),
        PoidsAssociation.normal);
  });

  test('reinitialiserPonderationAssociations restores the neutral profile',
      () async {
    final c = conteneur();
    await c.read(preferencesProvider.future);
    final notifier = c.read(preferencesProvider.notifier);

    await notifier.definirPoidsAssociation(
        FamilleEffetAssociation.gainDePlace, PoidsAssociation.fort);
    await notifier.reinitialiserPonderationAssociations();

    expect(c.read(preferencesProvider).value!.ponderationAssociations.estDefaut,
        isTrue);
  });
}
