import 'package:flutter/material.dart';

import '../../app/theme/dimensions_app.dart';
import '../glossaire/terme_cliquable.dart';

/// A [DropdownButtonFormField] whose **menu** shows a short description under
/// each option's label, while the **closed field** displays the label only
/// (via [DropdownButtonFormField.selectedItemBuilder]).
///
/// Used wherever a choice may be unfamiliar to the user — climate, hardiness
/// zone, planting type… — so the meaning of each option is visible right next
/// to it, without prior knowledge. Centralised so every such field looks alike.
class ChampDeroulantDecrit<T> extends StatelessWidget {
  /// Currently selected value (must be one of [options]).
  final T value;

  /// The selectable values, in display order.
  final List<T> options;

  /// Label shown for an option (the bold line, and the closed field).
  final String Function(T) libelle;

  /// One-line helper shown under the label, inside the menu only.
  final String Function(T) description;

  /// Called with the newly picked value.
  final ValueChanged<T> onChanged;

  /// Field label (floating).
  final String labelText;

  /// Optional field-level helper, under the closed field.
  final String? helperText;

  /// Optional glossary page id of the field's concept (ADR-0017 D5): renders a
  /// discreet « ? » suffix opening that page (e.g. `notion.type-climat`).
  final String? idAideGlossaire;

  const ChampDeroulantDecrit({
    super.key,
    required this.value,
    required this.options,
    required this.libelle,
    required this.description,
    required this.onChanged,
    required this.labelText,
    this.helperText,
    this.idAideGlossaire,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      // Null lets each menu item size to its two-line content (label + helper).
      itemHeight: null,
      decoration: InputDecoration(
        labelText: labelText,
        helperText: helperText,
        helperMaxLines: 2,
        border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
        suffixIcon: idAideGlossaire == null
            ? null
            : AideGlossaire(idTerme: idAideGlossaire!, infobulle: labelText),
      ),
      // Closed field: label only, single line.
      selectedItemBuilder: (context) => [
        for (final o in options)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              libelle(o),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      items: [
        for (final o in options)
          DropdownMenuItem<T>(
            value: o,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: EspacementsApp.s1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(libelle(o), style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 2),
                  Text(
                    description(o),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
