import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/enums/langue.dart';
import 'package:pot_a_gerer/domain/enums/mode_geolocalisation.dart';
import 'package:pot_a_gerer/domain/enums/niveau_experience.dart';
import 'package:pot_a_gerer/domain/enums/theme_app.dart';

void main() {
  group('PreferencesUtilisateur — smart defaults', () {
    test('privacy-first defaults', () {
      final p = PreferencesUtilisateur();
      expect(p.id, 'singleton');
      expect(p.langue, Langue.auto);
      expect(p.theme, ThemeApp.auto);
      expect(p.niveauExperience, NiveauExperience.debutant);
      expect(p.modeGeolocalisation, ModeGeolocalisation.desactivee);
      expect(p.notificationsGlobalesActives, isTrue);
      expect(p.syncLocaleActive, isFalse);
      expect(p.communauteOptIn, isFalse);
      expect(p.aideContextuelleActive, isTrue);
      expect(p.nePasDerangerActif, isFalse);
      expect(p.onboardingTermine, isFalse);
    });
  });

  group('PreferencesUtilisateur — onboarding', () {
    test('copierAvec sets the completion flag', () {
      final p = PreferencesUtilisateur().copierAvec(onboardingTermine: true);
      expect(p.onboardingTermine, isTrue);
    });

    test('the do-not-disturb helpers preserve the flag', () {
      final p = PreferencesUtilisateur()
          .copierAvec(onboardingTermine: true)
          .avecNePasDeranger('22:00', '07:00');
      expect(p.onboardingTermine, isTrue);
      expect(p.sansNePasDeranger().onboardingTermine, isTrue);
    });

    test('it participates in equality', () {
      expect(
        PreferencesUtilisateur() ==
            PreferencesUtilisateur(onboardingTermine: true),
        isFalse,
      );
    });
  });

  group('PreferencesUtilisateur — potagerActifId (ADR-0009 multi-potager)', () {
    test('defaults to null (no explicit selection)', () {
      expect(PreferencesUtilisateur().potagerActifId, isNull);
    });

    test('copierAvec sets the active garden selection', () {
      final p = PreferencesUtilisateur().copierAvec(potagerActifId: 'pot-2');
      expect(p.potagerActifId, 'pot-2');
    });

    test('copierAvec without the field keeps the previous selection', () {
      final p = PreferencesUtilisateur(potagerActifId: 'pot-1')
          .copierAvec(theme: ThemeApp.sombre);
      expect(p.potagerActifId, 'pot-1');
    });

    test('it participates in equality', () {
      expect(
        PreferencesUtilisateur() ==
            PreferencesUtilisateur(potagerActifId: 'pot-1'),
        isFalse,
      );
    });
  });

  group('PreferencesUtilisateur — meteoAutoActive (weather opt-out)', () {
    test('defaults to on', () {
      expect(PreferencesUtilisateur().meteoAutoActive, isTrue);
    });

    test('copierAvec toggles the opt-out', () {
      final p = PreferencesUtilisateur().copierAvec(meteoAutoActive: false);
      expect(p.meteoAutoActive, isFalse);
    });

    test('copierAvec without the field keeps the previous value', () {
      final p = PreferencesUtilisateur(meteoAutoActive: false)
          .copierAvec(theme: ThemeApp.sombre);
      expect(p.meteoAutoActive, isFalse);
    });

    test('it participates in equality', () {
      expect(
        PreferencesUtilisateur() ==
            PreferencesUtilisateur(meteoAutoActive: false),
        isFalse,
      );
    });
  });

  group('PreferencesUtilisateur — copierAvec', () {
    test('overrides one field and keeps the rest', () {
      final p = PreferencesUtilisateur();
      final p2 = p.copierAvec(theme: ThemeApp.sombre);
      expect(p2.theme, ThemeApp.sombre);
      expect(p2.langue, p.langue);
      expect(p2.niveauExperience, p.niveauExperience);
    });

    test('is immutable: the original is unchanged', () {
      final p = PreferencesUtilisateur();
      p.copierAvec(niveauExperience: NiveauExperience.expert);
      expect(p.niveauExperience, NiveauExperience.debutant);
    });

    test('the exposed notification map is unmodifiable', () {
      final p = PreferencesUtilisateur();
      expect(
        () => p.notificationsParCategorie['arrosage'] = false,
        throwsUnsupportedError,
      );
    });
  });

  group('PreferencesUtilisateur — do-not-disturb', () {
    test('rejects a half-set window at construction', () {
      expect(
        () => PreferencesUtilisateur(nePasDerangerDebut: '22:00'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('avecNePasDeranger sets both bounds', () {
      final p = PreferencesUtilisateur().avecNePasDeranger('22:00', '07:00');
      expect(p.nePasDerangerActif, isTrue);
      expect(p.nePasDerangerDebut, '22:00');
      expect(p.nePasDerangerFin, '07:00');
    });

    test('sansNePasDeranger clears the window', () {
      final p = PreferencesUtilisateur()
          .avecNePasDeranger('22:00', '07:00')
          .sansNePasDeranger();
      expect(p.nePasDerangerActif, isFalse);
      expect(p.nePasDerangerDebut, isNull);
      expect(p.nePasDerangerFin, isNull);
    });
  });

  group('PreferencesUtilisateur — value equality', () {
    test('same values are equal (including notification map)', () {
      final a = PreferencesUtilisateur(
        notificationsParCategorie: {'arrosage': true, 'semis': false},
      );
      final b = PreferencesUtilisateur(
        notificationsParCategorie: {'semis': false, 'arrosage': true},
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a single different field breaks equality', () {
      expect(
        PreferencesUtilisateur() ==
            PreferencesUtilisateur(theme: ThemeApp.clair),
        isFalse,
      );
    });
  });
}
