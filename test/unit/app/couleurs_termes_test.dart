import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/app/theme/couleurs_termes.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/presentation/glossaire/type_terme_glossaire.dart';

void main() {
  group('CouleursTermes', () {
    test('both themes carry the term colour chart (ADR-0017 D5)', () {
      expect(ThemeApp.clair().extension<CouleursTermes>(),
          same(CouleursTermes.clair));
      expect(ThemeApp.sombre().extension<CouleursTermes>(),
          same(CouleursTermes.sombre));
    });

    test('every term kind has its own colour (light chart)', () {
      final couleurs = [
        for (final type in TypeTermeGlossaire.values)
          CouleursTermes.clair.couleurDe(type),
      ];
      expect(couleurs.toSet().length, TypeTermeGlossaire.values.length,
          reason: 'two kinds sharing a colour would be indistinguishable');
    });

    test('couleurDe maps each kind to its declared field', () {
      const chart = CouleursTermes.clair;
      expect(chart.couleurDe(TypeTermeGlossaire.famille), chart.famille);
      expect(chart.couleurDe(TypeTermeGlossaire.maladie), chart.maladie);
      expect(chart.couleurDe(TypeTermeGlossaire.ravageur), chart.ravageur);
      expect(chart.couleurDe(TypeTermeGlossaire.outil), chart.outil);
      expect(chart.couleurDe(TypeTermeGlossaire.notion), chart.notion);
    });
  });
}
