import '../../domain/exceptions/fiche_plante_invalide_exception.dart';

/// Validates the structure and coherence of a parsed plant-sheet map before it
/// is mapped to a `FichePlante`.
///
/// Pipeline step 3 (see `docs/07-base-de-connaissances-yaml.md` §6). On the first
/// problem it throws a [FichePlanteInvalideException] describing the issue.
class FichePlanteValidator {
  const FichePlanteValidator();

  void valider(Map<dynamic, dynamic> y, {required String source}) {
    void exiger(bool condition, String raison) {
      if (!condition) throw FichePlanteInvalideException(source, raison);
    }

    for (final cle in ['id', 'nom_scientifique', 'famille_botanique',
        'categorie', 'usages', 'i18n', 'besoins', 'cycle']) {
      exiger(y[cle] != null, 'missing field "$cle"');
    }

    exiger(
      y['usages'] is List && (y['usages'] as List).isNotEmpty,
      'usages must list at least one value',
    );

    final i18n = y['i18n'];
    exiger(i18n is Map && i18n['fr'] is Map, 'i18n.fr is mandatory');
    exiger(
      (i18n as Map)['fr']['nom_commun'] != null,
      'i18n.fr.nom_commun is mandatory',
    );

    final besoins = y['besoins'] as Map;
    for (final cle in ['ensoleillement', 'arrosage', 'qualites_sol', 'ph_min',
        'ph_max']) {
      exiger(besoins[cle] != null, 'missing field "besoins.$cle"');
    }
    final phMin = (besoins['ph_min'] as num).toDouble();
    final phMax = (besoins['ph_max'] as num).toDouble();
    exiger(phMin >= 0 && phMax <= 14, 'pH must be within 0..14');
    exiger(phMin <= phMax, 'ph_min must be <= ph_max');

    final cycle = y['cycle'] as Map;
    exiger(cycle['espacement_cm'] is int && cycle['espacement_cm'] > 0,
        'cycle.espacement_cm must be a positive integer');
    final duree = cycle['duree_avant_recolte_jours'];
    exiger(
      duree is List &&
          duree.length == 2 &&
          duree[0] is int &&
          duree[1] is int &&
          duree[0] > 0 &&
          duree[0] <= duree[1],
      'cycle.duree_avant_recolte_jours must be [min, max] with 0 < min <= max',
    );
  }
}
