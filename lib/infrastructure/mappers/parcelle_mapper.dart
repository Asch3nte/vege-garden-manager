import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/entities/parcelle.dart';
import '../../domain/enums/niveau_soleil.dart';
import '../../domain/enums/ph_sol.dart';
import '../../domain/enums/source_type_sol.dart';
import '../../domain/enums/technique_sol.dart';
import '../../domain/enums/texture_sol.dart';
import '../../domain/enums/type_parcelle.dart';
import '../../domain/value_objects/surface.dart';
import '../database/app_database.dart';

/// Maps a [Parcelle] between the domain entity and its drift row.
///
/// The `Surface` value object is stored normalised in m². Soil techniques are a
/// JSON array of enum names. Hydration is shallow (plantations/equipements are
/// loaded by their own repositories).
class ParcelleMapper {
  const ParcelleMapper();

  Parcelle versEntite(ParcelleRow r) => Parcelle(
        id: r.id,
        nom: r.nom,
        potagerId: r.potagerId,
        type: TypeParcelle.values.byName(r.type),
        surface: r.surfaceUnite == 'cm2'
            ? Surface.enCentimetresCarres(r.surfaceValeur)
            : Surface.enMetresCarres(r.surfaceValeur),
        exposition: NiveauSoleil.values.byName(r.exposition),
        texture:
            r.textureSol == null ? null : TextureSol.values.byName(r.textureSol!),
        textureSource: SourceTypeSol.values.byName(r.textureSolSource),
        ph: r.phSol == null ? null : PhSol.values.byName(r.phSol!),
        techniquesSol: _techniques(r.techniquesSol),
        cultureVerticale: r.cultureVerticale,
        ordre: r.positionOrdre,
        notes: r.notes,
      );

  ParcellesCompanion versCompanion(Parcelle p) {
    final maintenant = DateTime.now().toUtc().toIso8601String();
    return ParcellesCompanion(
      id: Value(p.id),
      nom: Value(p.nom),
      potagerId: Value(p.potagerId),
      type: Value(p.type.name),
      surfaceValeur: Value(p.surface.enMetresCarres),
      surfaceUnite: const Value('m2'),
      exposition: Value(p.exposition.name),
      textureSol: Value(p.texture?.name),
      phSol: Value(p.ph?.name),
      textureSolSource: Value(p.textureSource.name),
      techniquesSol:
          Value(jsonEncode(p.techniquesSol.map((t) => t.name).toList())),
      cultureVerticale: Value(p.cultureVerticale),
      positionOrdre: Value(p.ordre),
      dateCreation: Value(maintenant),
      notes: Value(p.notes),
      createdAt: Value(maintenant),
      updatedAt: Value(maintenant),
    );
  }

  Set<TechniqueSol> _techniques(String? json) {
    if (json == null || json.isEmpty) return {};
    return (jsonDecode(json) as List)
        .map((e) => TechniqueSol.values.byName(e as String))
        .toSet();
  }
}
