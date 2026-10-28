import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/repositories/potager_repository_impl.dart';
import 'package:pot_a_gerer/infrastructure/repositories/preferences_repository_impl.dart';

/// Stores an active garden at [position] and finished-onboarding preferences
/// with the weather opt-out set to [meteoAuto].
Future<void> peuplerPotagerActif(
  AppDatabase db, {
  required bool meteoAuto,
  required Localisation position,
}) async {
  await PotagerRepositoryImpl(db).sauvegarder(
    Potager(
      id: 'pot-1',
      nom: 'Jardin',
      zoneClimatique: const ZoneClimatique(
        TypeClimat.oceanique,
        ZoneRusticite.zone8,
      ),
      dateCreation: DateTime(2026, 1, 1),
      localisation: position,
    ),
  );
  await PreferencesRepositoryImpl(db).sauvegarder(
    PreferencesUtilisateur(
      onboardingTermine: true,
      meteoAutoActive: meteoAuto,
      potagerActifId: 'pot-1',
    ),
  );
}
