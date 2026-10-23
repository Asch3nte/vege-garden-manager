import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/infrastructure/services/politique_confidentialite_source_impl.dart';

class _MockBundle extends Mock implements AssetBundle {}

void main() {
  test('reads the English policy in English, the French one otherwise',
      () async {
    final bundle = _MockBundle();
    when(() => bundle.loadString(any())).thenAnswer((i) async =>
        i.positionalArguments.single as String);
    final source = PolitiqueConfidentialiteSourceImpl(bundle);

    expect(await source.lire('en'), 'docs/politique-confidentialite.en.md');
    expect(await source.lire('fr'), 'docs/politique-confidentialite.md');
    expect(await source.lire('de'), 'docs/politique-confidentialite.md');
  });
}
