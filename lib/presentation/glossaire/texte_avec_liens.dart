import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../app/theme/couleurs_termes.dart';
import 'liens_glossaire.dart';
import 'terme_cliquable.dart';
import 'terme_glossaire.dart';

/// Renders a glossary text with its wiki links (`[[id]]` / `[[id|texte]]`,
/// ADR-0017 D2) as tappable spans navigating to the target term page.
///
/// Rules (never a dead link):
///  - a link whose id resolves in [index] becomes an underlined span
///    **coloured by the target's kind** (the D5 chart — same grammar as
///    `TermeCliquable`); a **bare** link (`[[id]]`) displays the target's
///    title instead of the id;
///  - a link whose id does **not** resolve renders as plain text (its label).
class TexteAvecLiens extends StatefulWidget {
  /// The text to render (may embed wiki links).
  final String texte;

  /// The glossary index used to resolve link targets.
  final Map<String, TermeGlossaire> index;

  /// Base style of the plain segments (defaults to `bodyMedium`).
  final TextStyle? style;

  /// Optional span rendered before the text, on the same line (e.g. the bold
  /// label of a described enum value) — wraps as regular text, unlike a
  /// separate widget.
  final InlineSpan? prefixe;

  const TexteAvecLiens({
    super.key,
    required this.texte,
    required this.index,
    this.style,
    this.prefixe,
  });

  @override
  State<TexteAvecLiens> createState() => _TexteAvecLiensState();
}

class _TexteAvecLiensState extends State<TexteAvecLiens> {
  /// Recognizers created for the current build, disposed on rebuild/unmount.
  final List<TapGestureRecognizer> _recognizers = [];

  void _libererRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _libererRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _libererRecognizers();
    final theme = Theme.of(context);
    final termes = couleursTermesDe(context);
    final base = widget.style ?? theme.textTheme.bodyMedium;

    final spans = <InlineSpan>[?widget.prefixe];
    for (final segment in analyserLiensGlossaire(widget.texte)) {
      switch (segment) {
        case SegmentBrut():
          spans.add(TextSpan(text: segment.texte));
        case SegmentLien():
          final cible = widget.index[segment.idCible];
          if (cible == null) {
            // Unresolved target: plain text, never a dead link.
            spans.add(TextSpan(text: segment.texte));
          } else {
            final couleur = termes.couleurDe(cible.type);
            final recognizer = TapGestureRecognizer()
              ..onTap = () => ouvrirTermeGlossaire(context, cible.id);
            _recognizers.add(recognizer);
            spans.add(TextSpan(
              // Bare link ([[id]]): show the target's title, not the raw id.
              text: segment.texte == segment.idCible
                  ? cible.titre
                  : segment.texte,
              style: base?.copyWith(
                color: couleur,
                decoration: TextDecoration.underline,
                decorationColor: couleur,
                fontWeight: FontWeight.w600,
              ),
              recognizer: recognizer,
            ));
          }
      }
    }
    return Text.rich(TextSpan(style: base, children: spans));
  }
}
