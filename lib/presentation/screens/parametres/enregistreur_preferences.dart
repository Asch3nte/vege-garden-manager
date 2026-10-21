import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Runs preference changes from a settings panel and reports a failed save.
class EnregistreurPreferences {
  final ScaffoldMessengerState _messenger;
  final String _message;

  EnregistreurPreferences._(this._messenger, this._message);

  /// Recorder reporting through the [ScaffoldMessenger] of [context].
  factory EnregistreurPreferences.de(BuildContext context) =>
      EnregistreurPreferences._(ScaffoldMessenger.of(context),
          AppLocalizations.of(context)!.formEnregistrementErreur);

  /// Runs [action], reporting a failure instead of letting it pass silently.
  Future<void> executer(Future<void> Function() action) async {
    try {
      await action();
    } on Exception catch (e) {
      debugPrint('Preference save failed: $e');
      _messenger.showSnackBar(SnackBar(content: Text(_message)));
    }
  }

  /// [setter] as a value callback whose failures are reported.
  void Function(T) pour<T>(Future<void> Function(T) setter) =>
      (valeur) => executer(() => setter(valeur));
}
