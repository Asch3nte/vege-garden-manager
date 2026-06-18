import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/verifier_referentiels.dart';

void main() {
  test('the real reference data has no fatal error', () async {
    final rapport = await verifierReferentiels();
    expect(rapport.ok, isTrue, reason: rapport.erreurs.join('\n'));
    // Editorial content is still being filled → warnings are expected.
    expect(rapport.avertissements, isNotEmpty);
  });

  test('reports an integrity error for an unknown family slug', () async {
    final tmp = Directory.systemTemp.createTempSync('verif_ref_');
    addTearDown(() => tmp.deleteSync(recursive: true));

    final famillesDir = Directory('${tmp.path}/familles')..createSync();
    File('${famillesDir.path}/solanaceae.yaml').writeAsStringSync('''
id: solanaceae
nom_scientifique: Solanaceae
schema_version: 1
categories: [legume]
i18n:
  fr:
    nom_commun: Solanacées
    description: Famille test.
ravageurs_communs: [slug_inexistant]
''');
    final bioFichier = File('${tmp.path}/bioagresseurs.yaml')
      ..writeAsStringSync('''
bioagresseurs:
  mildiou:
    type: maladie
    i18n:
      fr: { nom: Mildiou }
''');

    final rapport = await verifierReferentiels(
      famillesDir: famillesDir.path,
      bioagresseursFichier: bioFichier.path,
    );

    expect(rapport.ok, isFalse);
    expect(rapport.erreurs.any((e) => e.contains('slug_inexistant')), isTrue);
  });
}
