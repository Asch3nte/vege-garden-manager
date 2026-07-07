import 'package:riverpod/riverpod.dart';

import '../../domain/entities/fiche_plante.dart';
import '../../domain/services/id_fiche_personnelle.dart';
import '../../domain/value_objects/modele_fiche_personnelle.dart';

/// Use case: turn a catalogue [FichePlante] into an editable personal draft.
///
/// Projects the sheet onto the MVP editable subset (identity + basic
/// cultivation); richer catalogue fields are intentionally dropped. A fresh
/// personal id is derived from the name, so saving the draft creates a *copy*
/// rather than overriding the source sheet (`docs/07 §7`).
///
/// Pure transformation — no I/O. Uniqueness of the derived id is enforced later,
/// at creation time.
class DupliquerFicheEnModele {
  const DupliquerFicheEnModele();

  /// Builds a draft model from [source].
  ///
  /// Throws [ArgumentError] when the source carries no soil quality, which the
  /// personal-sheet model requires (the catalogue itself never emits such a
  /// sheet in practice).
  ModeleFichePersonnelle executer(FichePlante source) {
    if (source.besoins.qualitesSol.isEmpty) {
      throw ArgumentError.value(source.id, 'source',
          'cannot duplicate a sheet without any soil quality');
    }
    final nomFr = source.nomLocalise('fr');
    return ModeleFichePersonnelle(
      idFiche: IdFichePersonnelle.depuisNom(nomFr),
      categorie: source.categorie,
      sousType: source.sousType,
      usages: source.usages,
      nomScientifique: source.nomScientifique,
      familleBotanique: source.familleBotanique,
      nomCommunFr: nomFr,
      nomCommunEn: source.nomsLocalises['en'],
      descriptionFr: source.descriptionLocalisee('fr'),
      ensoleillement: source.besoins.soleil,
      arrosage: source.besoins.eau,
      qualitesSol: source.besoins.qualitesSol,
      phMin: source.besoins.phMin,
      phMax: source.besoins.phMax,
      espacementCm: source.espacementCm,
      dureeAvantRecolteJoursMin: source.dureeAvantRecolteJoursMin,
      dureeAvantRecolteJoursMax: source.dureeAvantRecolteJoursMax,
      difficulte: source.difficulte,
    );
  }
}

/// DI provider for [DupliquerFicheEnModele].
final dupliquerFicheEnModeleProvider = Provider<DupliquerFicheEnModele>(
  (ref) => const DupliquerFicheEnModele(),
);
