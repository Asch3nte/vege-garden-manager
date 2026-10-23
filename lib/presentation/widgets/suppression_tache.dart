import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/tache.dart';
import '../../l10n/app_localizations.dart';
import 'suppression_differee.dart';
import 'titre_tache.dart';

/// Asks to confirm the deletion of [tache], [nomCible] completing a derived
/// title.
Future<bool> confirmerSuppressionTache(
    BuildContext context, WidgetRef ref, Tache tache, String? nomCible) {
  final l10n = AppLocalizations.of(context)!;
  return confirmerSuppression(
    context,
    ref,
    titre: l10n.tacheSupprimerTitre,
    message:
        l10n.tacheSupprimerMessage(TitreTache.texte(l10n, tache, nomCible)),
  );
}
