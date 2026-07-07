/// Derives the logical catalogue id of a user-authored sheet from its name.
///
/// Every personal id carries the [prefixe] so it can never collide with a
/// built-in catalogue id (canonical `CAT3-NNN` format), while a collision
/// between two personal sheets is resolved with a numeric suffix at creation
/// time. The slug folds common French accents and keeps only `[a-z0-9_]`.
///
/// See `docs/07-base-de-connaissances-yaml.md` §7. Pure, no I/O.
class IdFichePersonnelle {
  const IdFichePersonnelle._();

  /// Namespace prefix guaranteeing personal ids never shadow a built-in sheet
  /// unintentionally.
  static const String prefixe = 'perso_';

  /// Builds the base logical id from a common [nom] (e.g. `Tomate de mémé` →
  /// `perso_tomate_de_meme`). Falls back to `perso_fiche` for an empty slug.
  static String depuisNom(String nom) {
    final slug = _slug(nom);
    return prefixe + (slug.isEmpty ? 'fiche' : slug);
  }

  static const Map<String, String> _accents = {
    'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a',
    'ç': 'c',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'î': 'i', 'ï': 'i', 'í': 'i',
    'ô': 'o', 'ö': 'o', 'ó': 'o', 'õ': 'o',
    'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
    'ÿ': 'y', 'ñ': 'n',
    'œ': 'oe', 'æ': 'ae',
  };

  static String _slug(String nom) {
    final folded = StringBuffer();
    for (final c in nom.toLowerCase().split('')) {
      folded.write(_accents[c] ?? c);
    }
    return folded
        .toString()
        .replaceAll(RegExp('[^a-z0-9]+'), '_')
        .replaceAll(RegExp('^_+|_+\$'), '');
  }
}
