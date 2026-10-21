import 'package:riverpod/riverpod.dart';

import '../../domain/entities/fiche_plante.dart';
import '../../domain/exceptions/invariant_domaine_exception.dart';
import '../../domain/services/id_fiche_personnelle.dart';
import '../../domain/value_objects/modele_fiche_personnelle.dart';

/// Use case: turn a catalogue [FichePlante] into an editable personal draft.
///
/// Projects the sheet onto the MVP editable subset (identity + basic
/// cultivation); richer catalogue fields are intentionally dropped. A fresh
/// personal id is derived from the name, so saving the draft creates a *copy*
/// rather than overriding the source sheet.
///
/// Pure transformation — no I/O. Uniqueness of the derived id is enforced later,
/// at creation time.
class DupliquerFicheEnModele {
  const DupliquerFicheEnModele();

  /// Builds a draft model from [source].
  ///
  /// Throws [InvariantDomaineException] when the source does not fit the
  /// personal-sheet model (e.g. no soil quality).
  ModeleFichePersonnelle executer(FichePlante source) {
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
