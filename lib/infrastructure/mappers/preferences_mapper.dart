import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/entities/preferences_utilisateur.dart';
import '../../domain/enums/langue.dart';
import '../../domain/enums/mode_geolocalisation.dart';
import '../../domain/enums/niveau_experience.dart';
import '../../domain/enums/sens_swipe.dart';
import '../../domain/enums/systeme_unites.dart';
import '../../domain/enums/theme_app.dart';
import '../database/app_database.dart';

/// Maps the preferences singleton between the domain entity and its drift row.
///
/// Enum values are stored as their camelCase name (= the SQL CHECK values), so
/// `Enum.name` / `Enum.values.byName` round-trip directly. The per-category
/// notification map is stored as JSON.
class PreferencesMapper {
  const PreferencesMapper();

  PreferencesUtilisateur versEntite(PreferencesRow row) {
    final notifs = (jsonDecode(row.notificationsParCategorie) as Map)
        .map((cle, valeur) => MapEntry(cle as String, valeur as bool));
    return PreferencesUtilisateur(
      langue: Langue.values.byName(row.langue),
      theme: ThemeApp.values.byName(row.theme),
      systemeUnites: SystemeUnites.values.byName(row.systemeUnites),
      sensSwipe: SensSwipe.values.byName(row.sensSwipe),
      niveauExperience: NiveauExperience.values.byName(row.niveauExperience),
      modeGeolocalisation:
          ModeGeolocalisation.values.byName(row.modeGeolocalisation),
      notificationsGlobalesActives: row.notificationsGlobalesActives,
      syncLocaleActive: row.syncLocaleActive,
      communauteOptIn: row.communauteOptIn,
      calendrierLunaireOptIn: row.calendrierLunaireOptIn,
      aideContextuelleActive: row.aideContextuelleActive,
      aideDocCompleteActive: row.aideDocCompleteActive,
      notificationsParCategorie: notifs,
      nePasDerangerDebut: row.nePasDerangerDebut,
      nePasDerangerFin: row.nePasDerangerFin,
      onboardingTermine: row.onboardingTermine,
    );
  }

  PreferencesCompanion versCompanion(PreferencesUtilisateur p) =>
      PreferencesCompanion(
        id: const Value(PreferencesUtilisateur.idSingleton),
        langue: Value(p.langue.name),
        theme: Value(p.theme.name),
        systemeUnites: Value(p.systemeUnites.name),
        sensSwipe: Value(p.sensSwipe.name),
        niveauExperience: Value(p.niveauExperience.name),
        modeGeolocalisation: Value(p.modeGeolocalisation.name),
        notificationsGlobalesActives: Value(p.notificationsGlobalesActives),
        syncLocaleActive: Value(p.syncLocaleActive),
        communauteOptIn: Value(p.communauteOptIn),
        calendrierLunaireOptIn: Value(p.calendrierLunaireOptIn),
        aideContextuelleActive: Value(p.aideContextuelleActive),
        aideDocCompleteActive: Value(p.aideDocCompleteActive),
        notificationsParCategorie: Value(jsonEncode(p.notificationsParCategorie)),
        nePasDerangerDebut: Value(p.nePasDerangerDebut),
        nePasDerangerFin: Value(p.nePasDerangerFin),
        onboardingTermine: Value(p.onboardingTermine),
        derniereModification:
            Value(DateTime.now().toUtc().toIso8601String()),
      );
}
