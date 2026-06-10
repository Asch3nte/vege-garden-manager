/// Resolves sparse inheritance between a variety sheet (fiche fille) and its
/// species sheet (fiche mère): the variety only declares the fields that differ,
/// everything else is inherited from the mother.
///
/// See ADR-0005. The merge runs on the **raw maps** (before validation and
/// mapping), so the merged map looks like a complete, standalone sheet to the
/// rest of the pipeline.
class FusionneurFiches {
  const FusionneurFiches();

  /// Fields a variety can never override — they belong to the species and are
  /// always taken from the mother (ADR-0005). Declaring them on a variety has no
  /// effect.
  static const Set<String> champsNonSurchargeables = {
    'categorie',
    'sous_type',
    'famille_botanique',
    'nom_scientifique',
    'usages',
    'rotation',
    'associations',
  };

  /// Merges variety sheet [fille] onto species sheet [mere], returning a new
  /// plain map.
  ///
  /// Field-by-field: the variety overrides the mother; nested mappings (e.g.
  /// `besoins`, `cycle`, `periodes`) are merged recursively so a variety can
  /// tweak a single sub-field while inheriting its siblings. Non-overridable
  /// fields ([champsNonSurchargeables]) are forced from the mother. `id`,
  /// `parent_id` and the version fields stay the variety's.
  Map<dynamic, dynamic> fusionner(Map mere, Map fille) {
    final resultat = _fusionnerMaps(mere, fille);
    for (final cle in champsNonSurchargeables) {
      if (mere.containsKey(cle)) {
        resultat[cle] = _copierProfond(mere[cle]);
      } else {
        resultat.remove(cle);
      }
    }
    return resultat;
  }

  /// Deep-merges [surcouche] over [base] into a fresh map (recursing into nested
  /// mappings; scalars and lists are replaced wholesale).
  Map<dynamic, dynamic> _fusionnerMaps(Map base, Map surcouche) {
    final out = <dynamic, dynamic>{
      for (final e in base.entries) e.key: _copierProfond(e.value),
    };
    for (final e in surcouche.entries) {
      final existant = out[e.key];
      out[e.key] = (existant is Map && e.value is Map)
          ? _fusionnerMaps(existant, e.value as Map)
          : _copierProfond(e.value);
    }
    return out;
  }

  /// Deep copy that also turns immutable `YamlMap`/`YamlList` nodes into plain
  /// mutable `Map`/`List`, so the merged result is safe to mutate downstream.
  Object? _copierProfond(Object? valeur) {
    if (valeur is Map) {
      return {for (final e in valeur.entries) e.key: _copierProfond(e.value)};
    }
    if (valeur is List) {
      return [for (final v in valeur) _copierProfond(v)];
    }
    return valeur;
  }
}
