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
  /// One recognizer per link, kept across rebuilds so a tap in progress
  /// survives them.
  final Map<SegmentTexte, TapGestureRecognizer> _reconnaisseurs = {};

  @override
  void initState() {
    super.initState();
    _creerReconnaisseurs();
  }

  @override
  void didUpdateWidget(VueDocument ancien) {
    super.didUpdateWidget(ancien);
    if (!identical(ancien.blocs, widget.blocs)) {
      _liberer();
      _creerReconnaisseurs();
    }
  }

  @override
  void dispose() {
    _liberer();
    super.dispose();
  }

  void _creerReconnaisseurs() {
    for (final s in widget.blocs.expand((b) => b.segments)) {
      if (s.lien case final lien?) {
        _reconnaisseurs[s] = TapGestureRecognizer()
          ..onTap = () => widget.onLien(lien);
      }
    }
  }

  void _liberer() {
    for (final r in _reconnaisseurs.values) {
      r.dispose();
    }
    _reconnaisseurs.clear();
  }

  @override
  Widget build(BuildContext context) {
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
                  style: switch (niveau) {
                    1 => theme.textTheme.headlineSmall,
                    2 => theme.textTheme.titleMedium,
                    _ => theme.textTheme.titleSmall,
                  },
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
          if (_reconnaisseurs[s] case final reconnaisseur?)
            TextSpan(
              text: s.texte,
              style: TextStyle(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
              recognizer: reconnaisseur,
            )
          else
            TextSpan(
              text: s.texte,
              style: s.gras ? const TextStyle(fontWeight: FontWeight.w600) : null,
            ),
      ]);
}
