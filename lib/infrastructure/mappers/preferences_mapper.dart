import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/entities/preferences_utilisateur.dart';
import '../../domain/enums/famille_effet_association.dart';
import '../../domain/enums/famille_effet_conflit.dart';
import '../../domain/enums/langue.dart';
import '../../domain/enums/mode_geolocalisation.dart';
import '../../domain/enums/niveau_experience.dart';
import '../../domain/enums/poids_association.dart';
import '../../domain/enums/sens_swipe.dart';
import '../../domain/enums/systeme_unites.dart';
import '../../domain/enums/theme_app.dart';
import '../../domain/value_objects/profil_ponderation_associations.dart';
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
      meteoAutoActive: row.meteoAutoActive,
      communauteOptIn: row.communauteOptIn,
      calendrierLunaireOptIn: row.calendrierLunaireOptIn,
      aideContextuelleActive: row.aideContextuelleActive,
      aideDocCompleteActive: row.aideDocCompleteActive,
      notificationsParCategorie: notifs,
      nePasDerangerDebut: row.nePasDerangerDebut,
      nePasDerangerFin: row.nePasDerangerFin,
      onboardingTermine: row.onboardingTermine,
      ponderationAssociations:
          _decoderPonderation(row.ponderationAssociations),
      potagerActifId: row.potagerActifId,
    );
  }

  /// Decodes the weighting profile from its JSON map `{famille: poids}`. Unknown
  /// family/weight names are skipped (forward-compatible); an empty map yields
  /// the neutral default.
  static ProfilPonderationAssociations _decoderPonderation(String json) {
    final brut = jsonDecode(json) as Map;
    final poids = <FamilleEffetAssociation, PoidsAssociation>{};
    final poidsConflit = <FamilleEffetConflit, PoidsAssociation>{};
    // Benefit and conflict families share one JSON map; their enum names never
    // collide, so each key resolves to exactly one side (ADR-0014).
    for (final entry in brut.entries) {
      final valeur = _parNom(PoidsAssociation.values, entry.value);
      if (valeur == null) continue;
      final benef = _parNom(FamilleEffetAssociation.values, entry.key);
      if (benef != null) {
        poids[benef] = valeur;
        continue;
      }
      final conflit = _parNom(FamilleEffetConflit.values, entry.key);
      if (conflit != null) poidsConflit[conflit] = valeur;
    }
    return ProfilPonderationAssociations(poids, poidsConflit: poidsConflit);
  }

  /// Enum value whose `name` equals [nom], or `null` (skip-unknown).
  static T? _parNom<T extends Enum>(List<T> valeurs, Object? nom) {
    for (final v in valeurs) {
      if (v.name == nom) return v;
    }
    return null;
  }

  static String _encoderPonderation(ProfilPonderationAssociations p) =>
      jsonEncode({
        for (final f in FamilleEffetAssociation.values) f.name: p.poids(f).name,
        for (final f in FamilleEffetConflit.values)
          f.name: p.poidsConflit(f).name,
      });

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
        meteoAutoActive: Value(p.meteoAutoActive),
        communauteOptIn: Value(p.communauteOptIn),
        calendrierLunaireOptIn: Value(p.calendrierLunaireOptIn),
        aideContextuelleActive: Value(p.aideContextuelleActive),
        aideDocCompleteActive: Value(p.aideDocCompleteActive),
        notificationsParCategorie: Value(jsonEncode(p.notificationsParCategorie)),
        ponderationAssociations:
            Value(_encoderPonderation(p.ponderationAssociations)),
        nePasDerangerDebut: Value(p.nePasDerangerDebut),
        nePasDerangerFin: Value(p.nePasDerangerFin),
        onboardingTermine: Value(p.onboardingTermine),
        potagerActifId: Value(p.potagerActifId),
        derniereModification:
            Value(DateTime.now().toUtc().toIso8601String()),
      );
}
