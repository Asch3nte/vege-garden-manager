import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:pot_a_gerer/application/providers/langue_provider.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/state/preferences_notifier.dart';
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/enums/langue.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_preferences_repository.dart';

class _MockPreferences extends Mock implements AbstractPreferencesRepository {}

void main() {
  Future<String> resoudre(Langue langue, {String systeme = 'en'}) async {
    final preferences = _MockPreferences();
    when(() => preferences.charger())
        .thenAnswer((_) async => PreferencesUtilisateur(langue: langue));
    final c = ProviderContainer(overrides: [
      preferencesRepositoryProvider.overrideWithValue(preferences),
      codeLangueSystemeProvider.overrideWithValue(systeme),
    ]);
    addTearDown(c.dispose);
    await c.read(preferencesProvider.future);
    return c.read(codeLangueProvider);
  }

  test('an explicit preference wins over the system language', () async {
    expect(await resoudre(Langue.fr), 'fr');
    expect(await resoudre(Langue.en, systeme: 'fr'), 'en');
  });

  test('auto follows the system language', () async {
    expect(await resoudre(Langue.auto, systeme: 'en'), 'en');
  });

  test('defaults to French while the preferences are not loaded', () {
    final c = ProviderContainer(overrides: [
      preferencesRepositoryProvider.overrideWithValue(_MockPreferences()),
    ]);
    addTearDown(c.dispose);
    expect(c.read(codeLangueProvider), 'fr');
  });
}
