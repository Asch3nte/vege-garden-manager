import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/state/preferences_notifier.dart';
import '../../application/state/suppressions_differees_notifier.dart';
import '../../l10n/app_localizations.dart';
import '../screens/parametres/enregistreur_preferences.dart';

/// Asks to confirm a list item's deletion, unless the user opted out; the
/// dialog offers to stop asking.
Future<bool> confirmerSuppression(
  BuildContext context,
  WidgetRef ref, {
  required String titre,
  required String message,
}) async {
  if (!(ref.read(preferencesProvider).value?.confirmerSuppressions ?? true)) {
    return true;
  }
  final enregistreur = EnregistreurPreferences.de(context);
  final reponse = await showDialog<_Reponse>(
    context: context,
    builder: (_) => _DialogueSuppression(titre: titre, message: message),
  );
  if (reponse == null || !reponse.confirme) return false;
  if (reponse.nePlusDemander) {
    await enregistreur.executer(() => ref
        .read(preferencesProvider.notifier)
        .definirConfirmerSuppressions(false));
  }
  return true;
}

/// Hides the item [id] at once and erases it with [effacer] once the undo
/// window of the [message] snackbar has passed.
void programmerSuppression(
  BuildContext context,
  WidgetRef ref, {
  required String id,
  required String message,
  required Effacement effacer,
}) {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  var annulable = true;
  final suppressions = ref.read(suppressionsDiffereesProvider.notifier)
    ..programmer(id, (r) {
      // An undo still shown past this point would do nothing.
      if (annulable && messenger.mounted) messenger.hideCurrentSnackBar();
      return effacer(r);
    });
  // A queued snackbar would offer its undo after the erasure.
  messenger.clearSnackBars();
  final affichage = messenger.showSnackBar(SnackBar(
    content: Text(message),
    duration: suppressions.delai,
    persist: false,
    action: SnackBarAction(
      label: l10n.actionAnnuler,
      onPressed: () => suppressions.annuler(id),
    ),
  ));
  unawaited(affichage.closed.then((_) => annulable = false));
}

typedef _Reponse = ({bool confirme, bool nePlusDemander});

class _DialogueSuppression extends StatefulWidget {
  final String titre;
  final String message;

  const _DialogueSuppression({required this.titre, required this.message});

  @override
  State<_DialogueSuppression> createState() => _DialogueSuppressionState();
}

class _DialogueSuppressionState extends State<_DialogueSuppression> {
  bool _nePlusDemander = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.titre),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          CheckboxListTile(
            value: _nePlusDemander,
            onChanged: (v) => setState(() => _nePlusDemander = v ?? false),
            title: Text(l10n.suppressionNePlusDemander),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context)
              .pop((confirme: false, nePlusDemander: false)),
          child: Text(l10n.actionAnnuler),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context)
              .pop((confirme: true, nePlusDemander: _nePlusDemander)),
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          child: Text(l10n.actionSupprimer),
        ),
      ],
    );
  }
}
