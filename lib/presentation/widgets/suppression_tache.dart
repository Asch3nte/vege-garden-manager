import 'package:flutter/widgets.dart';

import '../../domain/entities/tache.dart';
import '../../l10n/app_localizations.dart';
import 'dialogue_confirmation.dart';
import 'titre_tache.dart';

/// Asks to confirm the deletion of [tache], [nomCible] completing a derived
/// title.
Future<bool> confirmerSuppressionTache(
    BuildContext context, Tache tache, String? nomCible) {
  final l10n = AppLocalizations.of(context)!;
  return confirmerAction(
    context,
    titre: l10n.tacheSupprimerTitre,
    message:
        l10n.tacheSupprimerMessage(TitreTache.texte(l10n, tache, nomCible)),
    libelleConfirmer: l10n.actionSupprimer,
    destructif: true,
  );
}
