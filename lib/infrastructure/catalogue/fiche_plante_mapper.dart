import '../../domain/entities/fiche_plante.dart';
import '../../domain/enums/besoin_eau.dart';
import '../../domain/enums/categorie_plante.dart';
import '../../domain/enums/hemisphere.dart';
import '../../domain/enums/niveau_soleil.dart';
import '../../domain/enums/qualite_sol.dart';
import '../../domain/enums/sous_type_legume.dart';
import '../../domain/enums/type_climat.dart';
import '../../domain/enums/usage_plante.dart';
import '../../domain/value_objects/besoins_culture.dart';
import '../../domain/value_objects/periode.dart';
import '../../domain/value_objects/periodes_culture.dart';

/// Maps a validated plant-sheet map into a domain [FichePlante].
///
/// Pipeline step 4 (see `docs/07-base-de-connaissances-yaml.md` §6). Assumes the
/// map has already passed `FichePlanteValidator`. snake_case YAML values are
/// converted to camelCase enum names; `[min, max]` month lists become `Periode`.
class FichePlanteMapper {
  const FichePlanteMapper();

  FichePlante versEntite(Map<dynamic, dynamic> y) {
    final besoins = y['besoins'] as Map;
    final cycle = y['cycle'] as Map;
    final duree = cycle['duree_avant_recolte_jours'] as List;

    return FichePlante(
      id: y['id'] as String,
      nomScientifique: y['nom_scientifique'] as String,
      familleBotanique: y['famille_botanique'] as String,
      categorie: _enum(CategoriePlante.values, y['categorie'] as String),
      sousType: y['sous_type'] == null
          ? null
          : _enum(SousTypeLegume.values, y['sous_type'] as String),
      usages: (y['usages'] as Iterable)
          .map((u) => _enum(UsagePlante.values, u as String))
          .toSet(),
      nomsLocalises: _nomsLocalises(y['i18n'] as Map),
      besoins: BesoinsCulture(
        eau: _enum(BesoinEau.values, besoins['arrosage'] as String),
        soleil: _enum(NiveauSoleil.values, besoins['ensoleillement'] as String),
        qualitesSol: (besoins['qualites_sol'] as Iterable)
            .map((q) => _enum(QualiteSol.values, q as String))
            .toSet(),
        phMin: (besoins['ph_min'] as num).toDouble(),
        phMax: (besoins['ph_max'] as num).toDouble(),
      ),
      espacementCm: cycle['espacement_cm'] as int,
      dureeAvantRecolteJoursMin: duree[0] as int,
      dureeAvantRecolteJoursMax: duree[1] as int,
      periodes: _periodes(y['periodes'] as Map?),
      associationsBenefiques: _idsAssociation(y, 'beneficies'),
      associationsNegatives: _idsAssociation(y, 'defavorables'),
      rotationFamille: (y['rotation'] as Map?)?['famille'] as String?,
      delaiRetourAnnees: (y['rotation'] as Map?)?['delai_retour_annees'] as int?,
    );
  }

  Map<String, String> _nomsLocalises(Map i18n) => {
        for (final entry in i18n.entries)
          if ((entry.value as Map)['nom_commun'] != null)
            entry.key.toString(): (entry.value as Map)['nom_commun'] as String,
      };

  Map<Hemisphere, Map<TypeClimat, PeriodesCulture>> _periodes(Map? periodes) {
    if (periodes == null) return const {};
    return {
      for (final hemiEntry in periodes.entries)
        _enum(
          Hemisphere.values,
          (hemiEntry.key as String).replaceFirst('hemisphere_', ''),
        ): {
          for (final climatEntry in (hemiEntry.value as Map).entries)
            _enum(TypeClimat.values, climatEntry.key as String):
                _periodesCulture(climatEntry.value as Map),
        },
    };
  }

  PeriodesCulture _periodesCulture(Map m) => PeriodesCulture(
        semisInterieur: _periode(m['semis_interieur']),
        semisExterieur: _periode(m['semis_exterieur']),
        plantation: _periode(m['plantation']),
        recolte: _periode(m['recolte']),
      );

  Periode? _periode(Object? liste) =>
      liste == null ? null : Periode((liste as List)[0] as int, liste[1] as int);

  Set<String> _idsAssociation(Map y, String section) {
    final associations = y['associations'] as Map?;
    final liste = associations?[section] as Iterable?;
    return liste == null
        ? const {}
        : liste.map((e) => (e as Map)['id'] as String).toSet();
  }

  /// Resolves an enum value from a snake_case YAML token (e.g. `petit_fruit` →
  /// `CategoriePlante.petitFruit`).
  static T _enum<T extends Enum>(List<T> valeurs, String snake) =>
      valeurs.byName(_versCamel(snake));

  static String _versCamel(String snake) {
    final parts = snake.split('_');
    return parts.first +
        parts
            .skip(1)
            .map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1))
            .join();
  }
}
