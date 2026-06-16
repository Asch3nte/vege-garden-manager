import '../../domain/entities/fiche_plante.dart';
import '../../domain/enums/besoin_eau.dart';
import '../../domain/enums/categorie_plante.dart';
import '../../domain/enums/charge_tuteur.dart';
import '../../domain/enums/hemisphere.dart';
import '../../domain/enums/niveau_besoin.dart';
import '../../domain/enums/niveau_soleil.dart';
import '../../domain/enums/qualite_sol.dart';
import '../../domain/enums/sous_type_legume.dart';
import '../../domain/enums/type_benefice_association.dart';
import '../../domain/enums/type_climat.dart';
import '../../domain/enums/type_conflit_association.dart';
import '../../domain/enums/usage_plante.dart';
import '../../domain/enums/zone_rusticite.dart';
import '../../domain/value_objects/association_benefique.dart';
import '../../domain/value_objects/association_conflit.dart';
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
    final rotation = y['rotation'] as Map?;
    final rusticite = y['rusticite'] as Map?;

    return FichePlante(
      id: y['id'] as String,
      parentId: y['parent_id'] as String?,
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
      descriptionsLocalisees: _descriptions(y['i18n'] as Map),
      besoins: BesoinsCulture(
        eau: _enum(BesoinEau.values, besoins['arrosage'] as String),
        soleil: _enum(NiveauSoleil.values, besoins['ensoleillement'] as String),
        qualitesSol: (besoins['qualites_sol'] as Iterable)
            .map((q) => _enum(QualiteSol.values, q as String))
            .toSet(),
        phMin: (besoins['ph_min'] as num).toDouble(),
        phMax: (besoins['ph_max'] as num).toDouble(),
        soleilMin: besoins['ensoleillement_min'] == null
            ? null
            : _enum(NiveauSoleil.values, besoins['ensoleillement_min'] as String),
      ),
      espacementCm: cycle['espacement_cm'] as int,
      dureeAvantRecolteJoursMin: duree[0] as int,
      dureeAvantRecolteJoursMax: duree[1] as int,
      periodes: _periodes(y['periodes'] as Map?),
      associationsBenefiques: _benefices(y),
      associationsNegatives: _conflits(y),
      rotationFamille: rotation?['famille'] as String?,
      delaiRetourAnnees: rotation?['delai_retour_annees'] as int?,
      // Enrichissement §A
      rusticiteMin: rusticite?['zone_min'] == null
          ? null
          : _enum(ZoneRusticite.values, rusticite!['zone_min'] as String),
      // Enrichissement §B
      temperatureMinSurvie: besoins['temperature_min_survie'] == null
          ? null
          : (besoins['temperature_min_survie'] as num).toDouble(),
      geleFatal: besoins['gele_fatal'] as bool? ?? false,
      // Enrichissement §C
      difficulte: y['difficulte'] as int?,
      // Enrichissement §D
      profondeurSolMinCm: cycle['profondeur_sol_min_cm'] as int?,
      compatibleHorsSol: cycle['compatible_hors_sol'] as bool? ?? true,
      // Enrichissement §E
      cultureVerticale: cycle['culture_verticale'] as bool? ?? false,
      // Enrichissement §F — hauteur adulte [min, max]
      hauteurAdulteCmMin: (cycle['hauteur_adulte_cm'] as List?)?[0] as int?,
      hauteurAdulteCmMax: (cycle['hauteur_adulte_cm'] as List?)?[1] as int?,
      // Enrichissement §H
      fixeAzote: rotation?['fixe_azote'] as bool? ?? false,
      besoinAzote: rotation?['besoin_azote'] == null
          ? null
          : _enum(NiveauBesoin.values, rotation!['besoin_azote'] as String),
      // Enrichissement ADR-0010 Lot 2
      repulsifContre: _slugs(y['repulsif_contre']),
      piegeA: _slugs(y['piege_a']),
      chargeTuteur: cycle['charge_tuteur'] == null
          ? null
          : _enum(ChargeTuteur.values, cycle['charge_tuteur'] as String),
    );
  }

  /// A list of bioaggressor slugs (`repulsif_contre` / `piege_a`) as a set,
  /// empty when absent.
  Set<String> _slugs(Object? liste) => liste == null
      ? const {}
      : (liste as Iterable).map((e) => e as String).toSet();

  Map<String, String> _nomsLocalises(Map i18n) => {
        for (final entry in i18n.entries)
          if ((entry.value as Map)['nom_commun'] != null)
            entry.key.toString(): (entry.value as Map)['nom_commun'] as String,
      };

  /// Localized descriptions (YAML block scalars), trimmed of trailing newlines.
  Map<String, String> _descriptions(Map i18n) => {
        for (final entry in i18n.entries)
          if ((entry.value as Map)['description'] != null)
            entry.key.toString():
                ((entry.value as Map)['description'] as String).trim(),
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

  /// Beneficial associations (`associations.beneficies[]`) as typed value
  /// objects, carrying the optional `type` mechanism and the localised reason.
  List<AssociationBenefique> _benefices(Map y) {
    final liste = _sectionAssociations(y, 'beneficies');
    return [
      for (final e in liste)
        AssociationBenefique(
          cibleId: e['id'] as String,
          mecanisme: e['type'] == null
              ? null
              : _enum(TypeBeneficeAssociation.values, e['type'] as String),
          raisonI18n: _raisonI18n(e['raison_i18n'] as Map?),
        ),
    ];
  }

  /// Conflicting associations (`associations.defavorables[]`) as typed value
  /// objects.
  List<AssociationConflit> _conflits(Map y) {
    final liste = _sectionAssociations(y, 'defavorables');
    return [
      for (final e in liste)
        AssociationConflit(
          cibleId: e['id'] as String,
          mecanisme: e['type'] == null
              ? null
              : _enum(TypeConflitAssociation.values, e['type'] as String),
          raisonI18n: _raisonI18n(e['raison_i18n'] as Map?),
        ),
    ];
  }

  Iterable<Map> _sectionAssociations(Map y, String section) {
    final associations = y['associations'] as Map?;
    final liste = associations?[section] as Iterable?;
    return liste == null ? const <Map>[] : liste.cast<Map>();
  }

  /// Localised reason map (`{fr:, en:}`), dropping null entries.
  Map<String, String> _raisonI18n(Map? m) => m == null
      ? const {}
      : {
          for (final entry in m.entries)
            if (entry.value != null)
              entry.key.toString(): entry.value as String,
        };

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
