import 'package:drift/drift.dart';

import '../../domain/entities/plantation.dart';
import '../../domain/enums/methode_mise_en_place.dart';
import '../../domain/enums/statut_plantation.dart';
import '../../domain/value_objects/surface.dart';
import '../database/app_database.dart';

/// Maps a [Plantation] between the domain entity and its drift row. Hydration is
/// shallow (harvests are loaded by `RecolteRepository`).
class PlantationMapper {
  const PlantationMapper();

  Plantation versEntite(PlantationRow r) => Plantation(
        id: r.id,
        planteId: r.planteId,
        parcelleId: r.parcelleId,
        dateMiseEnPlace: DateTime.parse(r.dateMiseEnPlace),
        methode: MethodeMiseEnPlace.values.byName(r.methode),
        surfaceOccupee: r.surfaceOccupeeUnite == 'cm2'
            ? Surface.enCentimetresCarres(r.surfaceOccupeeValeur)
            : Surface.enMetresCarres(r.surfaceOccupeeValeur),
        nombrePieds: r.nombrePieds,
        statut: StatutPlantation.values.byName(r.statut),
        dateFinReelle:
            r.dateFinReelle == null ? null : DateTime.parse(r.dateFinReelle!),
        raisonFin: r.raisonFin,
      );

  PlantationsCompanion versCompanion(Plantation p) {
    final maintenant = DateTime.now().toUtc().toIso8601String();
    return PlantationsCompanion(
      id: Value(p.id),
      parcelleId: Value(p.parcelleId),
      planteId: Value(p.planteId),
      dateMiseEnPlace: Value(p.dateMiseEnPlace.toUtc().toIso8601String()),
      methode: Value(p.methode.name),
      surfaceOccupeeValeur: Value(p.surfaceOccupee.enMetresCarres),
      surfaceOccupeeUnite: const Value('m2'),
      nombrePieds: Value(p.nombrePieds),
      statut: Value(p.statut.name),
      dateFinReelle: Value(p.dateFinReelle?.toUtc().toIso8601String()),
      raisonFin: Value(p.raisonFin),
      createdAt: Value(maintenant),
      updatedAt: Value(maintenant),
    );
  }
}
