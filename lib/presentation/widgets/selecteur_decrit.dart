import 'package:flutter/material.dart';

import '../../app/theme/dimensions_app.dart';

/// Opens a modal bottom sheet listing [options], each as a label with a short
/// description, and returns the picked value (or `null` if dismissed).
///
/// The settings-side counterpart of [ChampDeroulantDecrit] (forms): both show
/// the same per-option description so an unfamiliar choice — climate, hardiness
/// zone… — is explained right next to it. The current [valeur] is checked.
Future<T?> choisirOptionDecrite<T>(
  BuildContext context, {
  required String titre,
  required T valeur,
  required List<T> options,
  required String Function(T) libelle,
  required String Function(T) description,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) {
      final theme = Theme.of(context);
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: EspacementsApp.s4),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                EspacementsApp.s5,
                0,
                EspacementsApp.s5,
                EspacementsApp.s3,
              ),
              child: Text(titre, style: theme.textTheme.titleLarge),
            ),
            for (final o in options)
              ListTile(
                selected: o == valeur,
                title: Text(libelle(o)),
                subtitle: Text(description(o)),
                trailing: o == valeur
                    ? Icon(Icons.check, color: theme.colorScheme.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(o),
              ),
          ],
        ),
      );
    },
  );
}
