import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../app/theme/dimensions_app.dart';
import '../../domain/enums/teinte_zone.dart';
import '../../domain/value_objects/couleur_zone.dart';
import '../../l10n/app_localizations.dart';
import 'couleur_zone_ui.dart';
import 'libelles_enums.dart';

/// Zone colour picker: the palette tints, then a custom swatch opening an RGB
/// panel.
class SelecteurCouleurZone extends StatelessWidget {
  final CouleurZone valeur;
  final ValueChanged<CouleurZone> onChanged;

  const SelecteurCouleurZone({
    super.key,
    required this.valeur,
    required this.onChanged,
  });

  Future<void> _choisirPersonnalisee(BuildContext context) async {
    final choisie = await showDialog<CouleurZone>(
      context: context,
      builder: (_) => _PanneauCouleurRgb(initiale: valeur.couleur),
    );
    if (choisie != null) onChanged(choisie);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: EspacementsApp.s2,
      runSpacing: EspacementsApp.s2,
      children: [
        for (final t in TeinteZone.values)
          _Pastille(
            couleur: CouleurZone.teinte(t).couleur,
            libelle: l10n.teinteZone(t),
            selectionnee: valeur == CouleurZone.teinte(t),
            onTap: () => onChanged(CouleurZone.teinte(t)),
          ),
        _Pastille(
          couleur: valeur.estPersonnalisee ? valeur.couleur : null,
          libelle: l10n.formZoneCouleurPerso,
          selectionnee: valeur.estPersonnalisee,
          onTap: () => _choisirPersonnalisee(context),
        ),
      ],
    );
  }
}

/// A round swatch; without [couleur] it shows a palette icon.
class _Pastille extends StatelessWidget {
  final Color? couleur;
  final String libelle;
  final bool selectionnee;
  final VoidCallback onTap;

  const _Pastille({
    required this.couleur,
    required this.libelle,
    required this.selectionnee,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fond = couleur ?? theme.colorScheme.surfaceContainerHighest;
    final contraste =
        ThemeData.estimateBrightnessForColor(fond) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Semantics(
      button: true,
      selected: selectionnee,
      label: libelle,
      excludeSemantics: true,
      child: Tooltip(
        message: libelle,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: TaillesIconesApp.xl2,
            height: TaillesIconesApp.xl2,
            decoration: BoxDecoration(
              color: fond,
              shape: BoxShape.circle,
              border: Border.all(
                color: selectionnee
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.outlineVariant,
                width: selectionnee ? 3 : 1,
              ),
            ),
            child: selectionnee
                ? Icon(
                    PhosphorIconsBold.check,
                    size: TaillesIconesApp.md,
                    color: contraste,
                  )
                : couleur == null
                ? Icon(
                    PhosphorIconsRegular.palette,
                    size: TaillesIconesApp.md,
                    color: contraste,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// Free colour panel: red, green and blue sliders kept in sync with a
/// `#RRGGBB` field. Pops the chosen [CouleurZone], or `null` on cancel.
class _PanneauCouleurRgb extends StatefulWidget {
  final Color initiale;

  const _PanneauCouleurRgb({required this.initiale});

  @override
  State<_PanneauCouleurRgb> createState() => _PanneauCouleurRgbState();
}

class _PanneauCouleurRgbState extends State<_PanneauCouleurRgb> {
  static final RegExp _formatHex = RegExp(r'^#?([0-9a-fA-F]{6})$');

  late int _rgb = widget.initiale.toARGB32() & 0xFFFFFF;
  late final TextEditingController _hex = TextEditingController(
    text: _versHex(_rgb),
  );
  bool _hexValide = true;

  static String _versHex(int rgb) =>
      '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';

  int _composante(int decalage) => (_rgb >> decalage) & 0xFF;

  void _definirComposante(int decalage, int valeur) => setState(() {
    _rgb = (_rgb & ~(0xFF << decalage)) | (valeur << decalage);
    _hex.text = _versHex(_rgb);
    _hexValide = true;
  });

  void _saisirHex(String texte) {
    final m = _formatHex.firstMatch(texte.trim());
    setState(() {
      _hexValide = m != null;
      if (m != null) _rgb = int.parse(m.group(1)!, radix: 16);
    });
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final composantes = [
      (l10n.couleurRouge, 16),
      (l10n.couleurVert, 8),
      (l10n.couleurBleu, 0),
    ];
    return AlertDialog(
      title: Text(l10n.formZoneCouleurPerso),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: EspacementsApp.s7,
              decoration: BoxDecoration(
                color: Color(0xFF000000 | _rgb),
                borderRadius: const BorderRadius.all(RayonsApp.md),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
            ),
            const SizedBox(height: EspacementsApp.s3),
            for (final (libelle, decalage) in composantes)
              Row(
                children: [
                  SizedBox(
                    width: EspacementsApp.s8,
                    child: Text(libelle, style: theme.textTheme.bodyMedium),
                  ),
                  Expanded(
                    child: Slider(
                      value: _composante(decalage).toDouble(),
                      max: 255,
                      divisions: 255,
                      label: '${_composante(decalage)}',
                      onChanged: (v) => _definirComposante(decalage, v.round()),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: EspacementsApp.s2),
            TextField(
              controller: _hex,
              decoration: InputDecoration(
                labelText: l10n.couleurHex,
                errorText: _hexValide ? null : l10n.couleurHexInvalide,
                border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[#0-9a-fA-F]')),
                LengthLimitingTextInputFormatter(7),
              ],
              onChanged: _saisirHex,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionAnnuler),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(CouleurZone.personnalisee(_rgb)),
          child: Text(l10n.actionValider),
        ),
      ],
    );
  }
}
