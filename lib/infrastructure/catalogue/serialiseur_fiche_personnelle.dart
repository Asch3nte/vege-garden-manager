import '../../domain/enums/besoin_eau.dart';
import '../../domain/enums/categorie_plante.dart';
import '../../domain/enums/niveau_soleil.dart';
import '../../domain/enums/qualite_sol.dart';
import '../../domain/enums/sous_type_legume.dart';
import '../../domain/enums/usage_plante.dart';
import '../../domain/value_objects/modele_fiche_personnelle.dart';

/// Serializes a [ModeleFichePersonnelle] to the YAML plant-sheet format and back.
///
/// The emitted YAML is the on-disk source of truth (`yaml_contenu`) and is
/// designed to pass `FichePlanteValidator` (with `validerFormatId: false`, since
/// personal ids use their own namespace) and to map through `FichePlanteMapper`
/// exactly like a built-in sheet. Every user string is emitted as an escaped
/// double-quoted scalar, so the result is always valid YAML — a corrupt sheet
/// can never be produced from a well-formed model.
///
/// See `docs/07-base-de-connaissances-yaml.md` §7. The current MVP schema covers
/// identity + basic cultivation; unset optional fields are simply omitted.
class SerialiseurFichePersonnelle {
  const SerialiseurFichePersonnelle();

  /// Schema version stamped on emitted personal sheets.
  static const int versionSchemaCourante = 1;

  /// Emits [modele] as a YAML document (source of truth for storage/export).
  String versYaml(ModeleFichePersonnelle modele) {
    final b = StringBuffer();
    b.writeln('id: ${_s(modele.idFiche)}');
    b.writeln('nom_scientifique: ${_s(modele.nomScientifique)}');
    b.writeln('famille_botanique: ${_s(modele.familleBotanique)}');
    b.writeln('categorie: ${_s(_snake(modele.categorie.name))}');
    if (modele.sousType != null) {
      b.writeln('sous_type: ${_s(_snake(modele.sousType!.name))}');
    }
    b.writeln('schema_version: $versionSchemaCourante');
    b.writeln('usages:');
    for (final u in modele.usages) {
      b.writeln('  - ${_s(_snake(u.name))}');
    }
    b.writeln('i18n:');
    b.writeln('  fr:');
    b.writeln('    nom_commun: ${_s(modele.nomCommunFr)}');
    if (modele.descriptionFr != null && modele.descriptionFr!.isNotEmpty) {
      b.writeln('    description: ${_s(modele.descriptionFr!)}');
    }
    if (modele.nomCommunEn != null && modele.nomCommunEn!.isNotEmpty) {
      b.writeln('  en:');
      b.writeln('    nom_commun: ${_s(modele.nomCommunEn!)}');
    }
    b.writeln('besoins:');
    b.writeln('  ensoleillement: ${_s(_snake(modele.ensoleillement.name))}');
    b.writeln('  arrosage: ${_s(_snake(modele.arrosage.name))}');
    b.writeln('  qualites_sol:');
    for (final q in modele.qualitesSol) {
      b.writeln('    - ${_s(_snake(q.name))}');
    }
    b.writeln('  ph_min: ${_num(modele.phMin)}');
    b.writeln('  ph_max: ${_num(modele.phMax)}');
    b.writeln('cycle:');
    b.writeln('  espacement_cm: ${modele.espacementCm}');
    b.writeln('  duree_avant_recolte_jours:');
    b.writeln('    - ${modele.dureeAvantRecolteJoursMin}');
    b.writeln('    - ${modele.dureeAvantRecolteJoursMax}');
    if (modele.difficulte != null) {
      b.writeln('difficulte: ${modele.difficulte}');
    }
    return b.toString();
  }

  /// Rebuilds a model from a parsed YAML [map] (as produced by `loadYaml`).
  ///
  /// Assumes the map is well-formed for the MVP schema; callers that read
  /// untrusted content should validate first. snake_case tokens are converted to
  /// the matching camelCase enum names.
  ModeleFichePersonnelle depuisMap(Map<dynamic, dynamic> map) {
    final i18n = map['i18n'] as Map;
    final fr = i18n['fr'] as Map;
    final en = i18n['en'] as Map?;
    final besoins = map['besoins'] as Map;
    final cycle = map['cycle'] as Map;
    final duree = cycle['duree_avant_recolte_jours'] as List;
    return ModeleFichePersonnelle(
      idFiche: map['id'] as String,
      categorie: _enum(CategoriePlante.values, map['categorie'] as String),
      sousType: map['sous_type'] == null
          ? null
          : _enum(SousTypeLegume.values, map['sous_type'] as String),
      usages: (map['usages'] as Iterable)
          .map((u) => _enum(UsagePlante.values, u as String))
          .toSet(),
      nomScientifique: map['nom_scientifique'] as String,
      familleBotanique: map['famille_botanique'] as String,
      nomCommunFr: fr['nom_commun'] as String,
      nomCommunEn: en?['nom_commun'] as String?,
      descriptionFr: (fr['description'] as String?)?.trim(),
      ensoleillement:
          _enum(NiveauSoleil.values, besoins['ensoleillement'] as String),
      arrosage: _enum(BesoinEau.values, besoins['arrosage'] as String),
      qualitesSol: (besoins['qualites_sol'] as Iterable)
          .map((q) => _enum(QualiteSol.values, q as String))
          .toSet(),
      phMin: (besoins['ph_min'] as num).toDouble(),
      phMax: (besoins['ph_max'] as num).toDouble(),
      espacementCm: cycle['espacement_cm'] as int,
      dureeAvantRecolteJoursMin: duree[0] as int,
      dureeAvantRecolteJoursMax: duree[1] as int,
      difficulte: map['difficulte'] as int?,
    );
  }

  /// Emits an escaped double-quoted YAML scalar — always valid, whatever the
  /// user typed (colons, quotes, newlines, unicode…).
  static String _s(String value) {
    final escaped = StringBuffer();
    for (final rune in value.runes) {
      switch (rune) {
        case 0x5C: // backslash
          escaped.write(r'\\');
        case 0x22: // double quote
          escaped.write(r'\"');
        case 0x0A: // newline
          escaped.write(r'\n');
        case 0x0D: // carriage return
          escaped.write(r'\r');
        case 0x09: // tab
          escaped.write(r'\t');
        default:
          if (rune < 0x20) {
            escaped.write('\\x${rune.toRadixString(16).padLeft(2, '0')}');
          } else {
            escaped.writeCharCode(rune);
          }
      }
    }
    return '"$escaped"';
  }

  /// Emits a number without a trailing `.0` when it is integral, so `6.0`
  /// round-trips as a clean `6` but `6.5` keeps its precision.
  static String _num(double value) =>
      value == value.roundToDouble() ? '${value.round()}' : '$value';

  /// The snake_case YAML token for an enum value (`CategoriePlante.petitFruit`
  /// → `petit_fruit`). Shared with the mapper for the denormalized columns.
  static String token(Enum valeur) => _snake(valeur.name);

  static T _enum<T extends Enum>(List<T> valeurs, String snake) =>
      valeurs.byName(_camel(snake));

  /// `petit_fruit` → `petitFruit`.
  static String _camel(String snake) {
    final parts = snake.split('_');
    return parts.first +
        parts
            .skip(1)
            .map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1))
            .join();
  }

  /// `petitFruit` → `petit_fruit`.
  static String _snake(String camel) => camel.replaceAllMapped(
        RegExp('[A-Z]'),
        (m) => '_${m[0]!.toLowerCase()}',
      );
}
