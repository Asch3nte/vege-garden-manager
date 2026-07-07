/// Wiki-link mini-syntax for glossary content (ADR-0017, D2).
///
/// Glossary texts (definitions, advice — stored in the ARB) may embed links to
/// other terms:
///
///  - `[[famille.solanaceae]]` — link, displayed text = the id (the renderer
///    usually substitutes the target's title);
///  - `[[famille.solanaceae|les Solanacées]]` — link with explicit label.
///
/// [analyserLiensGlossaire] splits a text into plain/link segments. It is a
/// **pure** function: rendering (colored clickable spans, dead-link fallback)
/// belongs to the widgets; integrity (every id resolves) is enforced by the
/// glossary integrity test (D6).
library;

/// One segment of an analysed glossary text: either plain text or a link.
sealed class SegmentTexte {
  /// The text to display for this segment.
  final String texte;

  const SegmentTexte(this.texte);
}

/// Plain text segment (rendered as-is).
class SegmentBrut extends SegmentTexte {
  const SegmentBrut(super.texte);

  @override
  bool operator ==(Object other) => other is SegmentBrut && other.texte == texte;

  @override
  int get hashCode => Object.hash(SegmentBrut, texte);

  @override
  String toString() => 'SegmentBrut($texte)';
}

/// Link segment pointing to the glossary term [idCible]; [texte] is the label
/// to display (the id itself when the link had no explicit label).
class SegmentLien extends SegmentTexte {
  /// The prefixed glossary id the link targets (e.g. `bio.mildiou`).
  final String idCible;

  const SegmentLien(this.idCible, super.texte);

  @override
  bool operator ==(Object other) =>
      other is SegmentLien && other.idCible == idCible && other.texte == texte;

  @override
  int get hashCode => Object.hash(SegmentLien, idCible, texte);

  @override
  String toString() => 'SegmentLien($idCible, $texte)';
}

/// `[[id]]` or `[[id|label]]` — id and label must be non-empty and free of
/// brackets/pipes.
final RegExp _lien = RegExp(r'\[\[([^\[\]|]+?)(?:\|([^\[\]|]+?))?\]\]');

/// Splits [texte] into an ordered list of [SegmentTexte].
///
/// Malformed constructs (unclosed `[[`, empty id or label, nested brackets)
/// are left verbatim as plain text — the parser never drops characters, so
/// `segments.map((s) => …)` always covers the whole input. Ids and labels are
/// trimmed; a blank id after trimming keeps the raw text.
List<SegmentTexte> analyserLiensGlossaire(String texte) {
  final segments = <SegmentTexte>[];
  var position = 0;

  for (final correspondance in _lien.allMatches(texte)) {
    if (correspondance.start > position) {
      segments.add(SegmentBrut(texte.substring(position, correspondance.start)));
    }

    final id = correspondance.group(1)!.trim();
    final etiquette = correspondance.group(2)?.trim();
    if (id.isEmpty || (etiquette != null && etiquette.isEmpty)) {
      // Blank id/label after trimming: keep the raw construct as plain text.
      segments.add(SegmentBrut(correspondance.group(0)!));
    } else {
      segments.add(SegmentLien(id, etiquette ?? id));
    }
    position = correspondance.end;
  }

  if (position < texte.length) {
    segments.add(SegmentBrut(texte.substring(position)));
  }
  return List<SegmentTexte>.unmodifiable(segments);
}

/// Every link id present in [texte], in order of appearance (with duplicates).
/// Used by the integrity test (D6) to check that all links resolve.
List<String> extraireIdsLiens(String texte) => List<String>.unmodifiable(
    analyserLiensGlossaire(texte).whereType<SegmentLien>().map((s) => s.idCible));
