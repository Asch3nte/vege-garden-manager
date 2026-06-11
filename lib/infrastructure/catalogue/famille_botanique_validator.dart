import '../../domain/entities/famille_botanique.dart';
import '../../domain/enums/categorie_plante.dart';
import '../../domain/exceptions/famille_botanique_invalide_exception.dart';

/// Validates the structure and coherence of a parsed family-sheet map before it
/// is mapped to a [FamilleBotanique] (ADR-0006).
///
/// On the first problem it throws a [FamilleBotaniqueInvalideException]. Category
/// tokens are checked against [CategoriePlante] so an unknown value is reported
/// here rather than crashing the mapper.
class FamilleBotaniqueValidator {
  const FamilleBotaniqueValidator();

  /// snake_case spellings of every [CategoriePlante], for token validation.
  static final Set<String> _categoriesValides = {
    for (final c in CategoriePlante.values) _versSnake(c.name),
  };

  void valider(Map<dynamic, dynamic> y, {required String source}) {
    void exiger(bool condition, String raison) {
      if (!condition) throw FamilleBotaniqueInvalideException(source, raison);
    }

    for (final cle in ['id', 'nom_scientifique', 'schema_version',
        'categories', 'i18n']) {
      exiger(y[cle] != null, 'missing field "$cle"');
    }

    final id = y['id'];
    final nomScientifique = y['nom_scientifique'];
    exiger(id is String && nomScientifique is String,
        'id and nom_scientifique must be strings');
    exiger(
      id == FamilleBotanique.normaliserCle(nomScientifique as String),
      'id must be the normalized scientific name '
      '(expected "${FamilleBotanique.normaliserCle(nomScientifique)}")',
    );

    final categories = y['categories'];
    exiger(categories is List && categories.isNotEmpty,
        'categories must list at least one value');
    for (final c in categories as List) {
      exiger(_categoriesValides.contains(c),
          'unknown category "$c" in categories');
    }

    final i18n = y['i18n'];
    exiger(i18n is Map && i18n['fr'] is Map, 'i18n.fr is mandatory');
    final fr = (i18n as Map)['fr'] as Map;
    exiger(fr['nom_commun'] != null, 'i18n.fr.nom_commun is mandatory');
    exiger(fr['description'] != null, 'i18n.fr.description is mandatory');

    final delai = y['delai_retour_annees'];
    if (delai != null) {
      exiger(delai is int && delai > 0,
          'delai_retour_annees must be a positive integer');
    }

    for (final cle in ['maladies_communes', 'ravageurs_communs']) {
      final v = y[cle];
      if (v != null) exiger(v is List, '$cle must be a list');
    }
  }

  /// camelCase → snake_case (`petitFruit` → `petit_fruit`), to match YAML tokens.
  static String _versSnake(String camel) => camel.replaceAllMapped(
        RegExp('[A-Z]'),
        (m) => '_${m[0]!.toLowerCase()}',
      );
}
