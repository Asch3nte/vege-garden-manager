/// Pure search over glossary terms (ADR-0017, D3): case- and accent-insensitive,
/// looking into titles **and** definitions, title matches ranked first.
library;

import 'terme_glossaire.dart';

const String _accents = 'àâäáãåçèêëéìîïíòôöóõùûüúÿñ';
const String _sans = 'aaaaaaceeeeiiiiooooouuuuyn';

/// Lowercases [texte] and strips French accents/ligatures, so `Épinard`
/// matches `epinard`. Whitespace is collapsed.
String normaliserRecherche(String texte) {
  final tampon = StringBuffer();
  for (final rune in texte.trim().toLowerCase().runes) {
    final c = String.fromCharCode(rune);
    if (c == 'œ' || c == 'æ') {
      tampon.write(c == 'œ' ? 'oe' : 'ae');
      continue;
    }
    final i = _accents.indexOf(c);
    tampon.write(i >= 0 ? _sans[i] : c);
  }
  return tampon.toString().replaceAll(RegExp(r'\s+'), ' ');
}

/// Filters [termes] on [requete].
///
/// Returns an unmodifiable list: terms whose **title** contains the normalized
/// query first (in their incoming order), then terms whose **definition**
/// contains it. A blank query returns all terms unchanged.
List<TermeGlossaire> rechercherTermes(
  List<TermeGlossaire> termes,
  String requete,
) {
  final normalisee = normaliserRecherche(requete);
  if (normalisee.isEmpty) return List<TermeGlossaire>.unmodifiable(termes);

  final parTitre = <TermeGlossaire>[];
  final parDefinition = <TermeGlossaire>[];
  for (final terme in termes) {
    if (normaliserRecherche(terme.titre).contains(normalisee)) {
      parTitre.add(terme);
    } else if (normaliserRecherche(terme.definition).contains(normalisee)) {
      parDefinition.add(terme);
    }
  }
  return List<TermeGlossaire>.unmodifiable([...parTitre, ...parDefinition]);
}
