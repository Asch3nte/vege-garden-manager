import '../../domain/enums/charge_tuteur.dart';
import '../../domain/enums/type_benefice_association.dart';
import '../../domain/enums/type_conflit_association.dart';
import '../../domain/exceptions/fiche_plante_invalide_exception.dart';

/// Validates the structure and coherence of a parsed plant-sheet map before it
/// is mapped to a `FichePlante`.
///
/// Pipeline step 3 (see `docs/07-base-de-connaissances-yaml.md` §6). On the first
/// problem it throws a [FichePlanteInvalideException] describing the issue.
class FichePlanteValidator {
  /// When `true`, [valider] also enforces the canonical ADR-0005 id format.
  ///
  /// Defaults to `false` during the migration window: the embedded sheets still
  /// carry legacy `snake_case` ids until the rename (Lot 2 tooling executed in
  /// Lot 3). Flip to `true` once every sheet uses the canonical format.
  final bool validerFormatId;

  const FichePlanteValidator({this.validerFormatId = false});

  /// Canonical id pattern (ADR-0005): `CAT3-NNN` for a species,
  /// `CAT3-NNN-VNNN` for a variety. Examples: `LEG-001`, `LEG-001-V001`.
  static final RegExp _formatId = RegExp(r'^[A-Z]{3}-\d{3}(-V\d{3})?$');

  /// Whether [id] matches the canonical ADR-0005 id format.
  static bool formatIdValide(String id) => _formatId.hasMatch(id);

  void valider(Map<dynamic, dynamic> y, {required String source}) {
    void exiger(bool condition, String raison) {
      if (!condition) throw FichePlanteInvalideException(source, raison);
    }

    for (final cle in ['id', 'nom_scientifique', 'famille_botanique',
        'categorie', 'usages', 'i18n', 'besoins', 'cycle']) {
      exiger(y[cle] != null, 'missing field "$cle"');
    }

    // Canonical id format — only enforced once the catalogue is migrated.
    if (validerFormatId) {
      final id = y['id'];
      exiger(
        id is String && formatIdValide(id),
        'id must match the canonical format CAT3-NNN[-VNNN] (e.g. LEG-001-V001)',
      );
    }

    // Variety sheet (ADR-0005): a `parent_id` must be a non-empty string and the
    // variety id must live in its mother's namespace (id prefixed by parent_id).
    // Validation runs after inheritance resolution, so the inherited required
    // fields above are already present. (Strict id format is enforced in Lot 2.)
    final parentId = y['parent_id'];
    if (parentId != null) {
      exiger(parentId is String && parentId.isNotEmpty,
          'parent_id must be a non-empty string');
      final id = y['id'];
      exiger(
        id is String && id != parentId && id.startsWith(parentId as String),
        'a variety id must be prefixed by its parent_id',
      );
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

    // Optional enrichment fields
    final difficulte = y['difficulte'];
    if (difficulte != null) {
      exiger(
        difficulte is int && difficulte >= 1 && difficulte <= 3,
        'difficulte must be an integer in 1..3',
      );
    }

    final rusticite = y['rusticite'] as Map?;
    if (rusticite != null) {
      final zoneMin = rusticite['zone_min'];
      exiger(
        zoneMin is String && zoneMin.startsWith('zone'),
        'rusticite.zone_min must be a valid ZoneRusticite (e.g. zone6)',
      );
    }

    final hauteur = cycle['hauteur_adulte_cm'];
    if (hauteur != null) {
      exiger(
        hauteur is List &&
            hauteur.length == 2 &&
            hauteur[0] is int &&
            hauteur[1] is int &&
            (hauteur[0] as int) > 0 &&
            (hauteur[0] as int) <= (hauteur[1] as int),
        'cycle.hauteur_adulte_cm must be [min, max] with 0 < min <= max',
      );
    }

    final profondeur = cycle['profondeur_sol_min_cm'];
    if (profondeur != null) {
      exiger(
        profondeur is int && profondeur > 0,
        'cycle.profondeur_sol_min_cm must be a positive integer',
      );
    }

    // Targeted defence (optional, ADR-0010 Lot 2): lists of bioaggressor slugs.
    // (Referential resolution is checked by VerificateurIntegriteRepulsifs.)
    for (final cle in ['repulsif_contre', 'piege_a']) {
      final liste = y[cle];
      if (liste != null) {
        exiger(liste is List, '$cle must be a list of slugs');
        for (final slug in liste as List) {
          exiger(slug is String && slug.isNotEmpty,
              '$cle entries must be non-empty strings');
        }
      }
    }
    final chargeTuteur = cycle['charge_tuteur'];
    if (chargeTuteur != null) {
      final valides = ChargeTuteur.values.map((e) => e.name).toSet();
      exiger(
        chargeTuteur is String && valides.contains(_versCamel(chargeTuteur)),
        'cycle.charge_tuteur "$chargeTuteur" must be one of legere|moyenne|lourde',
      );
    }

    // Associations (optional, ADR-0010): each entry needs a non-empty id; the
    // `type` mechanism, when present, must be a known enum value and the
    // `raison_i18n`, when present, must be a map.
    final associations = y['associations'] as Map?;
    if (associations != null) {
      _validerAssociations(associations, 'beneficies',
          TypeBeneficeAssociation.values.map((e) => e.name).toSet(), exiger);
      _validerAssociations(associations, 'defavorables',
          TypeConflitAssociation.values.map((e) => e.name).toSet(), exiger);
    }
  }

  /// Validates one associations section (`beneficies` / `defavorables`) against
  /// the [mecanismesValides] enum names (camelCase). [exiger] reports failures.
  void _validerAssociations(
    Map associations,
    String section,
    Set<String> mecanismesValides,
    void Function(bool, String) exiger,
  ) {
    final liste = associations[section];
    if (liste == null) return;
    exiger(liste is List, 'associations.$section must be a list');
    for (final entree in liste as List) {
      exiger(
        entree is Map &&
            entree['id'] is String &&
            (entree['id'] as String).isNotEmpty,
        'associations.$section[].id must be a non-empty string',
      );
      final type = (entree as Map)['type'];
      if (type != null) {
        exiger(
          type is String && mecanismesValides.contains(_versCamel(type)),
          'associations.$section[].type "$type" is not a known mechanism',
        );
      }
      final raison = entree['raison_i18n'];
      if (raison != null) {
        exiger(raison is Map,
            'associations.$section[].raison_i18n must be a map');
      }
    }
  }

  /// Converts a snake_case YAML token to camelCase to match an enum name.
  static String _versCamel(String snake) {
    final parts = snake.split('_');
    return parts.first +
        parts
            .skip(1)
            .map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1))
            .join();
  }
}
