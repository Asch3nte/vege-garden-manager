import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/dimensions_app.dart';
import 'lecteur_document.dart';

/// Shows the [blocs] of a document; tapping a link calls [onLien].
class VueDocument extends StatefulWidget {
  final List<BlocDocument> blocs;
  final ValueChanged<Uri> onLien;

  const VueDocument({super.key, required this.blocs, required this.onLien});

  @override
  State<VueDocument> createState() => _VueDocumentState();
}

class _VueDocumentState extends State<VueDocument> {
  final List<TapGestureRecognizer> _reconnaisseurs = [];

  @override
  void dispose() {
    _liberer();
    super.dispose();
  }

  void _liberer() {
    for (final r in _reconnaisseurs) {
      r.dispose();
    }
    _reconnaisseurs.clear();
  }

  @override
  Widget build(BuildContext context) {
    _liberer();
    final theme = Theme.of(context);
    final corps = theme.textTheme.bodyMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final bloc in widget.blocs)
          switch (bloc) {
            TitreDocument(:final niveau) => Padding(
                padding: const EdgeInsets.only(
                    top: EspacementsApp.s4, bottom: EspacementsApp.s2),
                child: Text.rich(
                  _texte(bloc, theme),
                  style: niveau == 1
                      ? theme.textTheme.headlineSmall
                      : theme.textTheme.titleMedium,
                ),
              ),
            ParagrapheDocument() => Padding(
                padding: const EdgeInsets.only(bottom: EspacementsApp.s3),
                child: Text.rich(_texte(bloc, theme), style: corps),
              ),
            PuceDocument() => Padding(
                padding: const EdgeInsets.only(
                    left: EspacementsApp.s2, bottom: EspacementsApp.s2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•', style: corps),
                    const SizedBox(width: EspacementsApp.s2),
                    Expanded(child: Text.rich(_texte(bloc, theme), style: corps)),
                  ],
                ),
              ),
          },
      ],
    );
  }

  TextSpan _texte(BlocDocument bloc, ThemeData theme) => TextSpan(children: [
        for (final s in bloc.segments)
          if (s.lien case final lien?)
            TextSpan(
              text: s.texte,
              style: TextStyle(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
              recognizer: _reconnaisseur(() => widget.onLien(lien)),
            )
          else
            TextSpan(
              text: s.texte,
              style: s.gras ? const TextStyle(fontWeight: FontWeight.w600) : null,
            ),
      ]);

  TapGestureRecognizer _reconnaisseur(VoidCallback onTap) {
    final r = TapGestureRecognizer()..onTap = onTap;
    _reconnaisseurs.add(r);
    return r;
  }
}
