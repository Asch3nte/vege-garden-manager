/// Pure search over glossary terms: case- and accent-insensitive,
/// looking into titles **and** definitions, title matches ranked first.
library;

import '../../domain/services/comparateur_noms.dart';
import 'terme_glossaire.dart';

/// Lowercases [texte] and strips French accents/ligatures, so `Épinard`
/// matches `epinard`. Whitespace is collapsed.
String normaliserRecherche(String texte) =>
    const ComparateurNoms().replier(texte.trim()).replaceAll(_espaces, ' ');

final RegExp _espaces = RegExp(r'\s+');

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
