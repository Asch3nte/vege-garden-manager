import '../../domain/entities/famille_botanique.dart';
import '../../domain/enums/categorie_plante.dart';

/// Maps a validated family-sheet map into a domain [FamilleBotanique] (ADR-0006).
///
/// Assumes the map has already passed `FamilleBotaniqueValidator`. snake_case
/// category tokens are converted to camelCase enum names.
class FamilleBotaniqueMapper {
  const FamilleBotaniqueMapper();

  FamilleBotanique versEntite(Map<dynamic, dynamic> y) {
    final i18n = y['i18n'] as Map;
    return FamilleBotanique(
      id: y['id'] as String,
      nomScientifique: y['nom_scientifique'] as String,
      categories: (y['categories'] as Iterable)
          .map((c) => _enum(CategoriePlante.values, c as String))
          .toSet(),
      nomsLocalises: _champLocalise(i18n, 'nom_commun'),
      descriptionsLocalisees: _champLocalise(i18n, 'description'),
      pourquoiRotationLocalise: _champLocalise(i18n, 'pourquoi_rotation'),
      ennemisCommunsNoteLocalisee: _champLocalise(i18n, 'ennemis_communs_note'),
      associationsNoteLocalisee: _champLocalise(i18n, 'associations_note'),
      maladiesCommunes: _slugs(y['maladies_communes']),
      ravageursCommuns: _slugs(y['ravageurs_communs']),
      delaiRetourAnnees: y['delai_retour_annees'] as int?,
    );
  }

  /// Collects a per-locale string field from the `i18n` map (block scalars are
  /// trimmed of trailing newlines).
  Map<String, String> _champLocalise(Map i18n, String cle) => {
        for (final entry in i18n.entries)
          if ((entry.value as Map)[cle] != null)
            entry.key.toString(): ((entry.value as Map)[cle] as String).trim(),
      };

  Set<String> _slugs(Object? liste) => liste == null
      ? const {}
      : (liste as Iterable).map((e) => e.toString()).toSet();

  /// Resolves an enum value from a snake_case YAML token (e.g. `petit_fruit` →
  /// `CategoriePlante.petitFruit`).
  static T _enum<T extends Enum>(List<T> valeurs, String snake) {
    final parts = snake.split('_');
    final camel = parts.first +
        parts
            .skip(1)
            .map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1))
            .join();
    return valeurs.byName(camel);
  }
}
