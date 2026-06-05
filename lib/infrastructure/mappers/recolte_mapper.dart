import 'package:drift/drift.dart';

import '../../domain/entities/recolte.dart';
import '../../domain/enums/destination_recolte.dart';
import '../../domain/enums/qualite_recolte.dart';
import '../../domain/enums/unite_quantite.dart';
import '../../domain/value_objects/quantite.dart';
import '../database/app_database.dart';

/// Maps a [Recolte] between the domain entity and its drift row.
class RecolteMapper {
  const RecolteMapper();

  Recolte versEntite(RecolteRow r) => Recolte(
        id: r.id,
        plantationId: r.plantationId,
        date: DateTime.parse(r.dateRecolte),
        quantite: Quantite(r.quantite, UniteQuantite.values.byName(r.unite)),
        destination: DestinationRecolte.values.byName(r.destination),
        qualite:
            r.qualite == null ? null : QualiteRecolte.values.byName(r.qualite!),
        notes: r.notes,
      );

  RecoltesCompanion versCompanion(Recolte r) {
    final maintenant = DateTime.now().toUtc().toIso8601String();
    return RecoltesCompanion(
      id: Value(r.id),
      plantationId: Value(r.plantationId),
      dateRecolte: Value(r.date.toUtc().toIso8601String()),
      quantite: Value(r.quantite.valeur),
      unite: Value(r.quantite.unite.name),
      qualite: Value(r.qualite?.name),
      destination: Value(r.destination.name),
      dateCreation: Value(maintenant),
      notes: Value(r.notes),
      createdAt: Value(maintenant),
      updatedAt: Value(maintenant),
    );
  }
}
