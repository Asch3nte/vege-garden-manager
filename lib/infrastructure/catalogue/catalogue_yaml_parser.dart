import 'package:yaml/yaml.dart';

import '../../domain/exceptions/fiche_plante_invalide_exception.dart';

/// Parses the raw YAML text of a plant sheet into a [Map].
///
/// Pipeline step 2 (see `docs/07-base-de-connaissances-yaml.md` §6): turns text
/// into a structured map, surfacing syntax errors as a typed
/// [FichePlanteInvalideException].
class CatalogueYamlParser {
  const CatalogueYamlParser();

  /// Parses [contenu]; [source] identifies the sheet for error messages.
  ///
  /// Throws [FichePlanteInvalideException] on a syntax error or when the root is
  /// not a mapping.
  Map<dynamic, dynamic> parser(String contenu, {required String source}) {
    final Object? doc;
    try {
      doc = loadYaml(contenu);
    } on YamlException catch (e) {
      throw FichePlanteInvalideException(source, 'YAML syntax error: ${e.message}');
    }
    if (doc is! Map) {
      throw FichePlanteInvalideException(source, 'the root must be a mapping');
    }
    return doc;
  }
}
