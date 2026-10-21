import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../app/theme/dimensions_app.dart';
import '../../app/theme/theme_app.dart';
import '../../application/state/favoris_notifier.dart';
import '../../l10n/app_localizations.dart';

/// Heart toggling the favourite state of the sheet [ficheId].
class BoutonFavori extends ConsumerWidget {
  final String ficheId;

  /// Bare icon footprint, for dense rows such as catalogue cards.
  final bool compact;

  const BoutonFavori({super.key, required this.ficheId, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final favori = ref.watch(favorisProvider).value?.contains(ficheId) ?? false;
    final theme = Theme.of(context);
    final couleur =
        theme.extension<AccentsCarnet>()?.chaud ?? theme.colorScheme.primary;
    return IconButton(
      icon: Icon(
        favori ? PhosphorIconsFill.heart : PhosphorIconsRegular.heart,
        color: favori ? couleur : null,
      ),
      iconSize: compact ? TaillesIconesApp.md : null,
      padding: compact ? EdgeInsets.zero : null,
      constraints: compact ? const BoxConstraints() : null,
      visualDensity: compact ? VisualDensity.compact : null,
      tooltip: favori ? l10n.favoriRetirer : l10n.favoriAjouter,
      onPressed: () => ref.read(favorisProvider.notifier).basculer(ficheId),
    );
  }
}
