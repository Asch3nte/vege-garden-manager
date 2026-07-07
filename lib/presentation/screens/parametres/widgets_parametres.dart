import 'package:flutter/material.dart';

import '../../../app/theme/dimensions_app.dart';

/// Scaffold shell for a settings sub-panel: an app bar with a back button and a
/// scrollable body. The panels push onto the navigator from the settings root.
class PanneauParametres extends StatelessWidget {
  /// App-bar title.
  final String titre;

  /// Body content (already padded by the panel as needed).
  final List<Widget> enfants;

  /// Optional app-bar actions (e.g. an `AideGlossaire` towards the concept
  /// page explaining the panel, ADR-0017 D5).
  final List<Widget>? actions;

  const PanneauParametres(
      {super.key, required this.titre, required this.enfants, this.actions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titre), actions: actions),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          EspacementsApp.s4,
          EspacementsApp.s4,
          EspacementsApp.s4,
          EspacementsApp.s6,
        ),
        children: enfants,
      ),
    );
  }
}

/// A titled section grouping related settings, with an optional footer note.
class ZoneParametres extends StatelessWidget {
  /// Optional section heading.
  final String? titre;

  /// Section rows.
  final List<Widget> enfants;

  /// Optional explanatory footer.
  final String? note;

  const ZoneParametres({super.key, this.titre, required this.enfants, this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: EspacementsApp.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (titre != null) ...[
            Text(titre!, style: theme.textTheme.titleLarge),
            const SizedBox(height: EspacementsApp.s2),
          ],
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: const BorderRadius.all(RayonsApp.lg),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Column(children: enfants),
          ),
          if (note != null) ...[
            const SizedBox(height: EspacementsApp.s2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: TaillesIconesApp.sm, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: EspacementsApp.s2),
                Expanded(
                  child: Text(
                    note!,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A category row on the settings root (icon + title + subtitle + chevron).
class LigneCategorie extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String sousTitre;
  final VoidCallback onTap;

  const LigneCategorie({
    super.key,
    required this.icone,
    required this.titre,
    required this.sousTitre,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: EspacementsApp.s2),
      child: Material(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: RayonsApp.brLg,
        child: InkWell(
          borderRadius: RayonsApp.brLg,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(EspacementsApp.s3),
            decoration: BoxDecoration(
              borderRadius: RayonsApp.brLg,
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Row(
              children: [
                Icon(icone, color: theme.colorScheme.primary),
                const SizedBox(width: EspacementsApp.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titre, style: theme.textTheme.bodyLarge),
                      Text(
                        sousTitre,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: TaillesIconesApp.md, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An inline switch row (icon + label + optional subtitle + toggle).
class RangeeInterrupteur extends StatelessWidget {
  final IconData icone;
  final String label;
  final String? sousTitre;
  final bool valeur;
  final ValueChanged<bool>? onChanged;

  const RangeeInterrupteur({
    super.key,
    required this.icone,
    required this.label,
    this.sousTitre,
    required this.valeur,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final desactive = onChanged == null;
    final couleurTexte = desactive
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EspacementsApp.s3,
        vertical: EspacementsApp.s2,
      ),
      child: Row(
        children: [
          Icon(
            icone,
            size: TaillesIconesApp.md,
            color: desactive ? theme.colorScheme.outline : theme.colorScheme.primary,
          ),
          const SizedBox(width: EspacementsApp.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: couleurTexte)),
                if (sousTitre != null)
                  Text(
                    sousTitre!,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          Switch(value: valeur, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// A stacked field: a label (+ optional hint) over a full-width control.
class ChampEmpile extends StatelessWidget {
  final String label;
  final String? indication;
  final Widget enfant;

  const ChampEmpile({
    super.key,
    required this.label,
    this.indication,
    required this.enfant,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(EspacementsApp.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              if (indication != null) ...[
                const Spacer(),
                Text(
                  indication!,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
          const SizedBox(height: EspacementsApp.s2),
          enfant,
        ],
      ),
    );
  }
}

/// A segmented selector over an enum's values.
class ChampSegmente<T> extends StatelessWidget {
  final T valeur;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  const ChampSegmente({
    super.key,
    required this.valeur,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<T>(
        segments: [
          for (final (val, lab) in options)
            ButtonSegment(value: val, label: Text(lab)),
        ],
        selected: {valeur},
        onSelectionChanged: (s) => onChanged(s.first),
        showSelectedIcon: false,
      ),
    );
  }
}
