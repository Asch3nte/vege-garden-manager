import 'package:drift/drift.dart';

import '../../core/utils/date_iso.dart';
import '../../domain/entities/potager.dart';
import '../../domain/enums/source_localisation.dart';
import '../../domain/enums/type_climat.dart';
import '../../domain/enums/type_emplacement.dart';
import '../../domain/enums/zone_rusticite.dart';
import '../../domain/value_objects/localisation.dart';
import '../../domain/value_objects/zone_climatique.dart';
import '../database/app_database.dart';

/// Maps a [Potager] between the domain entity and its drift row.
///
/// The `Localisation` and `ZoneClimatique` value objects are flattened into
/// columns. Hydration is **shallow**: parcelles are loaded separately by their
/// own repository.
class PotagerMapper {
  const PotagerMapper();

  Potager versEntite(PotagerRow r) => Potager(
        id: r.id,
        nom: r.nom,
        emplacement: TypeEmplacement.values.byName(r.emplacement),
        localisation: _localisation(r),
        zoneClimatique: ZoneClimatique(
          TypeClimat.values.byName(r.climatType),
          ZoneRusticite.values.byName(r.zoneRusticite),
        ),
        dateCreation: DateIso.depuisStockage(r.dateCreation),
        notes: r.notes,
      );

  PotagersCompanion versCompanion(Potager p) {
    final maintenant = DateIso.maintenant();
    return PotagersCompanion(
      id: Value(p.id),
      nom: Value(p.nom),
      emplacement: Value(p.emplacement.name),
      localisationLatitude: Value(p.localisation.latitude),
      localisationLongitude: Value(p.localisation.longitude),
      localisationVille: Value(p.localisation.ville),
      localisationSource: Value(p.localisation.source.name),
      climatType: Value(p.zoneClimatique.type.name),
      zoneRusticite: Value(p.zoneClimatique.rusticite.name),
      dateCreation: Value(DateIso.versStockage(p.dateCreation)),
      notes: Value(p.notes),
      createdAt: Value(maintenant),
      updatedAt: Value(maintenant),
    );
  }

  Localisation _localisation(PotagerRow r) {
    switch (SourceLocalisation.values.byName(r.localisationSource)) {
      case SourceLocalisation.nonDefinie:
        return const Localisation.nonDefinie();
      case SourceLocalisation.manuelle:
        return Localisation.manuelle(
          ville: r.localisationVille!,
          latitude: r.localisationLatitude!,
          longitude: r.localisationLongitude!,
        );
      case SourceLocalisation.gps:
        return Localisation.gps(
          latitude: r.localisationLatitude!,
          longitude: r.localisationLongitude!,
        );
    }
  }
}
