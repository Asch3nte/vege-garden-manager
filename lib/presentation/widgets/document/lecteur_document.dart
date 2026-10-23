import 'dart:convert';

/// A run of text with its inline style.
class SegmentTexte {
  final String texte;
  final bool gras;

  /// Target of a link; only `https` links are kept.
  final Uri? lien;

  const SegmentTexte(this.texte, {this.gras = false, this.lien});
}

/// A block of a document: heading, paragraph or bullet.
sealed class BlocDocument {
  final List<SegmentTexte> segments;

  BlocDocument(List<SegmentTexte> segments)
      : segments = List.unmodifiable(segments);

  /// The text without its styles.
  String get texteBrut => segments.map((s) => s.texte).join();
}

final class TitreDocument extends BlocDocument {
  /// 1 for `#`, 2 for `##`, 3 for `###`.
  final int niveau;

  TitreDocument(this.niveau, super.segments);
}

final class ParagrapheDocument extends BlocDocument {
  ParagrapheDocument(super.segments);
}

final class PuceDocument extends BlocDocument {
  PuceDocument(super.segments);
}

/// Reads the Markdown subset of the embedded documents: `#` to `###`
/// headings, paragraphs, `- ` bullets, `**bold**` and `[text](https://…)`.
class LecteurDocument {
  static final RegExp _titre = RegExp(r'^(#{1,3}) (.+)$');
  static final RegExp _enLigne =
      RegExp(r'\*\*(.+?)\*\*|\[([^\]]+)\]\(([^)\s]+)\)');

  const LecteurDocument();

  List<BlocDocument> lire(String source) {
    final blocs = <BlocDocument>[];
    final lignes = <String>[];
    var puce = false;

    void clore() {
      if (lignes.isEmpty) return;
      final segments = _segments(lignes.join(' '));
      blocs.add(puce ? PuceDocument(segments) : ParagrapheDocument(segments));
      lignes.clear();
      puce = false;
    }

    for (final brute in const LineSplitter().convert(source)) {
      final ligne = brute.trim();
      if (ligne.isEmpty) {
        clore();
        continue;
      }
      final titre = _titre.firstMatch(ligne);
      if (titre != null) {
        clore();
        blocs.add(TitreDocument(titre[1]!.length, _segments(titre[2]!)));
      } else if (ligne.startsWith('- ')) {
        clore();
        puce = true;
        lignes.add(ligne.substring(2));
      } else {
        lignes.add(ligne);
      }
    }
    clore();
    return List.unmodifiable(blocs);
  }

  List<SegmentTexte> _segments(String texte) {
    final segments = <SegmentTexte>[];
    var debut = 0;
    for (final m in _enLigne.allMatches(texte)) {
      if (m.start > debut) {
        segments.add(SegmentTexte(texte.substring(debut, m.start)));
      }
      if (m[1] != null) {
        segments.add(SegmentTexte(m[1]!, gras: true));
      } else {
        final cible = Uri.tryParse(m[3]!);
        segments.add(SegmentTexte(m[2]!,
            lien: cible != null && cible.scheme == 'https' ? cible : null));
      }
      debut = m.end;
    }
    if (debut < texte.length) segments.add(SegmentTexte(texte.substring(debut)));
    return segments;
  }
}
