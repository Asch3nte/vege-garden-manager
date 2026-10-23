import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/service_providers.dart';
import '../../l10n/app_localizations.dart';

/// Opens [url] outside the app; a snackbar tells when no handler can.
Future<void> ouvrirLienExterne(
    BuildContext context, WidgetRef ref, Uri url) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  if (!await ref.read(ouvertureLienServiceProvider).ouvrir(url)) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.aproposLienErreur)));
  }
}
