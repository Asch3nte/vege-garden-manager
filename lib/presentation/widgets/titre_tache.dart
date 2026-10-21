import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/state/nom_plante_plantation_provider.dart';
import '../../domain/entities/tache.dart';
import '../../domain/enums/cible_tache.dart';
import '../../l10n/app_localizations.dart';
import 'libelles_enums.dart';

/// Title of a task: its own, or the one derived from its type and crop.
class TitreTache extends ConsumerWidget {
  final Tache tache;
  final TextStyle? style;
  final TextOverflow? overflow;

  const TitreTache(this.tache, {super.key, this.style, this.overflow});

  /// Title of [tache], [nomCible] completing a derived one.
  static String texte(AppLocalizations l10n, Tache tache, String? nomCible) {
    final propre = tache.titre;
    if (propre != null) return propre;
    final action = l10n.typeTache(tache.type);
    return nomCible == null ? action : l10n.tacheTitreDerive(action, nomCible);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nom = tache.titre == null && tache.cible == CibleTache.plantation
        ? ref.watch(nomPlantePlantationProvider(tache.cibleId)).value
        : null;
    return Text(texte(AppLocalizations.of(context)!, tache, nom),
        style: style, overflow: overflow);
  }
}
