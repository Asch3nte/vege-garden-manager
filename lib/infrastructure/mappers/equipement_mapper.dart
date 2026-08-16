import 'package:drift/drift.dart';

import '../../core/utils/date_iso.dart';
import '../../domain/entities/equipement.dart';
import '../../domain/enums/etat_equipement.dart';
import '../../domain/enums/type_equipement.dart';
import '../database/app_database.dart';

/// Maps an [Equipement] between the domain entity and its drift row.
///
/// The agronomic effect ([Equipement.effet]) is derived from the type and never
/// stored. Enums are persisted as their camelCase `name`.
class EquipementMapper {
  const EquipementMapper();

  Equipement versEntite(EquipementRow r) {
    return Equipement(
      id: r.id,
      nom: r.nom,
      potagerId: r.potagerId,
      parcelleId: r.parcelleId,
      type: TypeEquipement.values.byName(r.type),
      etat: EtatEquipement.values.byName(r.etat),
      marqueModele: r.marqueModele,
      dateInstallation: DateIso.depuisStockage(r.dateInstallation),
      dateRemplacementPrevue:
          DateIso.depuisStockageNullable(r.dateRemplacementPrevue),
      dateRetrait: DateIso.depuisStockageNullable(r.dateRetrait),
      notes: r.notes,
    );
  }

  EquipementsCompanion versCompanion(Equipement e) {
    final maintenant = DateIso.maintenant();
    return EquipementsCompanion(
      id: Value(e.id),
      nom: Value(e.nom),
      potagerId: Value(e.potagerId),
      parcelleId: Value(e.parcelleId),
      type: Value(e.type.name),
      etat: Value(e.etat.name),
      marqueModele: Value(e.marqueModele),
      dateInstallation: Value(DateIso.versStockage(e.dateInstallation)),
      dateRemplacementPrevue:
          Value(DateIso.versStockageNullable(e.dateRemplacementPrevue)),
      dateRetrait: Value(DateIso.versStockageNullable(e.dateRetrait)),
      dateCreation: Value(maintenant),
      notes: Value(e.notes),
      createdAt: Value(maintenant),
      updatedAt: Value(maintenant),
    );
  }
}
