import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Files of `lib/<couche>` importing or exporting one of the [interdites]
/// layers or files.
List<String> _violations(String couche, List<String> interdites) => [
      for (final fichier in Directory('lib/$couche')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart')))
        for (final ligne in fichier.readAsLinesSync())
          if ((ligne.startsWith('import ') || ligne.startsWith('export ')) &&
              interdites.any((c) =>
                  ligne.contains(c.endsWith('.dart') ? '/$c' : '/$c/')))
            '${fichier.path}: $ligne',
    ];

void main() {
  test('domain depends on no other layer', () {
    expect(_violations('domain',
        ['application', 'infrastructure', 'presentation', 'app']), isEmpty);
  });

  test('application does not import infrastructure nor presentation', () {
    expect(_violations('application', ['infrastructure', 'presentation', 'app']),
        isEmpty);
  });

  test('presentation does not import infrastructure nor the composition', () {
    expect(
        _violations('presentation', ['infrastructure', 'app/composition.dart']),
        isEmpty);
  });
}
