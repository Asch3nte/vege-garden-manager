import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:yaml/yaml.dart';

import '../../domain/entities/fiche_plante_personnelle.dart';
import '../catalogue/serialiseur_fiche_personnelle.dart';
import '../database/app_database.dart';

/// Maps a [FichePlantePersonnelle] between the domain entity and its drift row.
///
/// The emitted YAML ([FichePlantePersonnelleRow.yamlContenu]) is the source of
/// truth: reads rebuild the model from it. The other columns are a denormalized
/// projection (categorie, sous_type, usages, names, family) kept in sync on
/// write so lists and queries never need to parse the YAML.
class FichePlantePersonnelleMapper {
  final SerialiseurFichePersonnelle _serialiseur;

  const FichePlantePersonnelleMapper(
      [this._serialiseur = const SerialiseurFichePersonnelle()]);

  FichePlantePersonnelle versEntite(FichePlantePersonnelleRow r) {
    final map = loadYaml(r.yamlContenu) as YamlMap;
    return FichePlantePersonnelle(
      id: r.id,
      contenu: _serialiseur.depuisMap(map),
      dateCreation: DateTime.parse(r.dateCreation),
      dateModification: DateTime.parse(r.updatedAt),
    );
  }

  FichesPlantesPersonnellesCompanion versCompanion(FichePlantePersonnelle f) {
    final m = f.contenu;
    return FichesPlantesPersonnellesCompanion(
      id: Value(f.id),
      idFiche: Value(m.idFiche),
      yamlContenu: Value(_serialiseur.versYaml(m)),
      schemaVersion:
          const Value(SerialiseurFichePersonnelle.versionSchemaCourante),
      categorie: Value(SerialiseurFichePersonnelle.token(m.categorie)),
      sousType: Value(m.sousType == null
          ? null
          : SerialiseurFichePersonnelle.token(m.sousType!)),
      usages: Value(jsonEncode(
          m.usages.map(SerialiseurFichePersonnelle.token).toList())),
      nomCommunFr: Value(m.nomCommunFr),
      nomCommunEn: Value(m.nomCommunEn),
      familleBotanique: Value(m.familleBotanique),
      dateCreation: Value(f.dateCreation.toUtc().toIso8601String()),
      createdAt: Value(f.dateCreation.toUtc().toIso8601String()),
      updatedAt: Value(f.dateModification.toUtc().toIso8601String()),
    );
  }
}
