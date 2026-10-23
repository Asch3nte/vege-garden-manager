import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/presentation/widgets/document/lecteur_document.dart';

void main() {
  const lecteur = LecteurDocument();

  test('headings, paragraphs and bullets, wrapped lines joined', () {
    final blocs = lecteur.lire('''
# Titre

## 1. Section

Un paragraphe
sur deux lignes.

- une puce
  qui continue
- une autre
''');

    expect(blocs, hasLength(5));
    expect(blocs[0], isA<TitreDocument>().having((t) => t.niveau, 'niveau', 1));
    expect(blocs[1], isA<TitreDocument>().having((t) => t.niveau, 'niveau', 2));
    expect(blocs[2], isA<ParagrapheDocument>());
    expect(blocs[2].texteBrut, 'Un paragraphe sur deux lignes.');
    expect(blocs[3], isA<PuceDocument>());
    expect(blocs[3].texteBrut, 'une puce qui continue');
    expect(blocs[4].texteBrut, 'une autre');
  });

  test('bold and links become segments', () {
    final segments = lecteur
        .lire('Texte **gras** et [un lien](https://exemple.org/a).')
        .single
        .segments;

    expect(segments.map((s) => s.texte),
        ['Texte ', 'gras', ' et ', 'un lien', '.']);
    expect(segments[1].gras, isTrue);
    expect(segments[3].lien, Uri.parse('https://exemple.org/a'));
    expect(segments[0].gras || segments[0].lien != null, isFalse);
  });

  test('a non-https link stays plain text', () {
    final segments =
        lecteur.lire('[piège](javascript:alert(1))').single.segments;

    expect(segments.every((s) => s.lien == null), isTrue);
  });

  test('the embedded privacy policies parse into sections', () {
    for (final langue in ['', '.en']) {
      final source = _lire('docs/politique-confidentialite$langue.md');
      final blocs = lecteur.lire(source);
      expect(blocs.whereType<TitreDocument>().where((t) => t.niveau == 2),
          hasLength(12));
      expect(blocs.expand((b) => b.segments).where((s) => s.lien != null),
          hasLength(2));
    }
  });
}

String _lire(String chemin) => File(chemin).readAsStringSync();
