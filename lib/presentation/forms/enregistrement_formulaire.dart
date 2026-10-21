import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Save flow shared by the creation forms: the form is disabled while saving,
/// the route pops with the result, or the failure is reported and the form is
/// enabled again.
mixin EnregistrementFormulaire<W extends StatefulWidget> on State<W> {
  bool _enregistrement = false;

  /// Whether a save is in progress (the submit button is then disabled).
  bool get enregistrementEnCours => _enregistrement;

  /// Runs [action] and pops the route with its result. On failure,
  /// [messageErreur] may give a specific message for the exception.
  Future<void> enregistrer<T>(Future<T> Function() action,
      {String? Function(Exception)? messageErreur}) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    setState(() => _enregistrement = true);
    var reussi = false;
    final T resultat;
    try {
      resultat = await action();
      reussi = true;
    } on Exception catch (e) {
      debugPrint('Form save failed: $e');
      messenger.showSnackBar(SnackBar(
          content: Text(messageErreur?.call(e) ?? l10n.formEnregistrementErreur)));
      return;
    } finally {
      if (!reussi && mounted) setState(() => _enregistrement = false);
    }
    if (mounted) Navigator.of(context).pop(resultat);
  }
}
