/// Orders display names alphabetically, ignoring case and accents, so that
/// `Échalote` sorts between `Courgette` and `Fraise`.
class ComparateurNoms {
  static const String _accents = 'àâäáãåçèêëéìîïíòôöóõøùûüúÿýñł';
  static const String _sans = 'aaaaaaceeeeiiiioooooouuuuyynl';
  static const Map<String, String> _ligatures = {
    'œ': 'oe',
    'æ': 'ae',
    'ß': 'ss',
  };

  // Unicode combining diacritical marks, left over by decomposed (NFD) text.
  static const int _diacritiqueMin = 0x0300;
  static const int _diacritiqueMax = 0x036F;

  const ComparateurNoms();

  /// Lowercased [nom] with accents and ligatures folded (`Œillet` → `oeillet`).
  String replier(String nom) {
    final tampon = StringBuffer();
    for (final rune in nom.toLowerCase().runes) {
      if (rune >= _diacritiqueMin && rune <= _diacritiqueMax) continue;
      final c = String.fromCharCode(rune);
      final ligature = _ligatures[c];
      if (ligature != null) {
        tampon.write(ligature);
        continue;
      }
      final i = _accents.indexOf(c);
      tampon.write(i >= 0 ? _sans[i] : c);
    }
    return tampon.toString();
  }

  /// Compares the folded names; raw names break ties so the order is total.
  int comparer(String a, String b) {
    final ordre = replier(a).compareTo(replier(b));
    return ordre != 0 ? ordre : a.compareTo(b);
  }
}
