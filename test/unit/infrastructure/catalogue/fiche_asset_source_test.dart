import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/fiche_asset_source.dart';

void main() {
  test('keeps plant sheets and skips the reserved folders, on any platform',
      () {
    for (final sep in ['/', r'\']) {
      String chemin(List<String> parties) => parties.join(sep);

      expect(
          FicheAssetSource.estFiche(
              chemin(['assets', 'fiches_plantes', 'legumes', 'tomate.yaml'])),
          isTrue,
          reason: sep);
      for (final reserve in ['_schema', '_familles', '_referentiels']) {
        expect(
            FicheAssetSource.estFiche(
                chemin(['assets', 'fiches_plantes', reserve, 'x.yaml'])),
            isFalse,
            reason: '$reserve $sep');
      }
      expect(
          FicheAssetSource.estFiche(
              chemin(['assets', 'fiches_plantes', 'legumes', 'notes.md'])),
          isFalse);
    }
  });
}
