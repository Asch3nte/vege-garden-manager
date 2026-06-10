import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Shows a confirmation dialog and resolves to `true` only if the user confirms.
///
/// Use for irreversible or destructive actions (deleting a zone or a plant). The
/// [destructif] flag tints the confirm button with the error colour.
Future<bool> confirmerAction(
  BuildContext context, {
  required String titre,
  required String message,
  required String libelleConfirmer,
  bool destructif = false,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  final confirme = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titre),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.actionAnnuler),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: destructif
              ? FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                )
              : null,
          child: Text(libelleConfirmer),
        ),
      ],
    ),
  );
  return confirme ?? false;
}
