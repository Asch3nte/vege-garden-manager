import '../../domain/entities/bioagresseur.dart';
import '../../domain/enums/type_bioagresseur.dart';

/// Maps a validated bioaggressor entry into a domain [Bioagresseur]
/// (ADR-0006, Lot 4).
///
/// Assumes the entry has already passed `BioagresseurValidator`.
class BioagresseurMapper {
  const BioagresseurMapper();

  Bioagresseur versEntite(String slug, Map<dynamic, dynamic> y) {
    final i18n = y['i18n'] as Map;
    return Bioagresseur(
      id: slug,
      type: TypeBioagresseur.values.byName(y['type'] as String),
      nomsLocalises: _champLocalise(i18n, 'nom'),
      descriptionsLocalisees: _champLocalise(i18n, 'description'),
      codeEppo: (y['code_eppo'] as String?)?.trim(),
    );
  }

  /// Collects a per-locale string field from the `i18n` map (trimmed).
  Map<String, String> _champLocalise(Map i18n, String cle) => {
        for (final entry in i18n.entries)
          if ((entry.value as Map)[cle] != null)
            entry.key.toString(): ((entry.value as Map)[cle] as String).trim(),
      };
}
