import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/famille_effet_association.dart';
import 'package:pot_a_gerer/domain/enums/mode_geolocalisation.dart';
import 'package:pot_a_gerer/domain/enums/niveau_experience.dart';
import 'package:pot_a_gerer/domain/enums/poids_association.dart';
import 'package:pot_a_gerer/domain/enums/theme_app.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/repositories/preferences_repository_impl.dart';

void main() {
  late AppDatabase db;
  late PreferencesRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = PreferencesRepositoryImpl(db);
  });
  tearDown(() => db.close());

  test('charger returns the seeded defaults', () async {
    final p = await repo.charger();
    expect(p.niveauExperience, NiveauExperience.debutant);
    expect(p.theme, ThemeApp.auto);
    expect(p.modeGeolocalisation, ModeGeolocalisation.desactivee);
    expect(p.onboardingTermine, isFalse);
  });

  test('save then load round-trips the onboarding flag', () async {
    await repo.sauvegarder(
        (await repo.charger()).copierAvec(onboardingTermine: true));
    expect((await repo.charger()).onboardingTermine, isTrue);
  });

  test('save then load round-trips enums, do-not-disturb and notif map',
      () async {
    final modifie = (await repo.charger())
        .copierAvec(
          theme: ThemeApp.sombre,
          niveauExperience: NiveauExperience.expert,
          notificationsParCategorie: {'arrosage': false, 'semis': true},
        )
        .avecNePasDeranger('22:00', '07:00');

    await repo.sauvegarder(modifie);
    final relu = await repo.charger();

    expect(relu.theme, ThemeApp.sombre);
    expect(relu.niveauExperience, NiveauExperience.expert);
    expect(relu.nePasDerangerDebut, '22:00');
    expect(relu.nePasDerangerFin, '07:00');
    expect(relu.notificationsParCategorie, {'arrosage': false, 'semis': true});
  });

  test('charger returns the default weighting profile (ADR-0011)', () async {
    expect((await repo.charger()).ponderationAssociations.estDefaut, isTrue);
  });

  test('save then load round-trips the association weighting profile', () async {
    final modifie = (await repo.charger()).copierAvec(
      ponderationAssociations: (await repo.charger())
          .ponderationAssociations
          .avec(FamilleEffetAssociation.protectionRavageurs,
              PoidsAssociation.ignore)
          .avec(FamilleEffetAssociation.gainDePlace, PoidsAssociation.fort),
    );

    await repo.sauvegarder(modifie);
    final relu = await repo.charger();

    expect(relu.ponderationAssociations.poids(
        FamilleEffetAssociation.protectionRavageurs), PoidsAssociation.ignore);
    expect(relu.ponderationAssociations.poids(
        FamilleEffetAssociation.gainDePlace), PoidsAssociation.fort);
    expect(relu.ponderationAssociations.poids(
        FamilleEffetAssociation.fertilite), PoidsAssociation.normal);
  });

  test('reinitialiser restores the defaults', () async {
    await repo.sauvegarder(
        (await repo.charger()).copierAvec(theme: ThemeApp.sombre));
    await repo.reinitialiser();
    expect((await repo.charger()).theme, ThemeApp.auto);
  });
}
