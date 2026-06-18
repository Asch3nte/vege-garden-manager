import '../../domain/entities/bioagresseur.dart';
import '../../domain/enums/type_bioagresseur.dart';
import '../../domain/exceptions/bioagresseur_invalide_exception.dart';

/// Validates a single parsed entry of the bioaggressor reference before it is
/// mapped to a [Bioagresseur] (ADR-0006, Lot 4).
///
/// On the first problem it throws a [BioagresseurInvalideException]. The `type`
/// token is checked against [TypeBioagresseur] so an unknown value is reported
/// here rather than crashing the mapper.
class BioagresseurValidator {
  const BioagresseurValidator();

  /// snake_case spellings of every [TypeBioagresseur], for token validation.
  static final Set<String> _typesValides = {
    for (final t in TypeBioagresseur.values) t.name,
  };

  /// Validates the [entry] keyed by [slug]. [source] identifies the entry in
  /// error messages (the slug, or the file path).
  void valider(String slug, Map<dynamic, dynamic> entry,
      {required String source}) {
    void exiger(bool condition, String raison) {
      if (!condition) throw BioagresseurInvalideException(source, raison);
    }

    exiger(slug == Bioagresseur.normaliserSlug(slug),
        'slug must be normalized (expected "${Bioagresseur.normaliserSlug(slug)}")');

    final type = entry['type'];
    exiger(type is String && _typesValides.contains(type),
        'type must be one of ${_typesValides.join(' | ')} (got "$type")');

    final codeEppo = entry['code_eppo'];
    if (codeEppo != null) {
      exiger(codeEppo is String && codeEppo.trim().isNotEmpty,
          'code_eppo, when set, must be a non-empty string');
    }

    final i18n = entry['i18n'];
    exiger(i18n is Map && i18n['fr'] is Map, 'i18n.fr is mandatory');
    final fr = (i18n as Map)['fr'] as Map;
    final nom = fr['nom'];
    exiger(nom is String && nom.trim().isNotEmpty,
        'i18n.fr.nom is mandatory and must not be empty');
  }
}
