import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../app/theme/theme_app.dart';
import '../../application/state/favoris_notifier.dart';
import '../../l10n/app_localizations.dart';

/// Heart toggling the favourite state of the sheet [ficheId].
class BoutonFavori extends ConsumerWidget {
  final String ficheId;

  const BoutonFavori({super.key, required this.ficheId});

  Future<void> _basculer(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context)!.favoriErreur;
    try {
      await ref.read(favorisProvider.notifier).basculer(ficheId);
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

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
      tooltip: favori ? l10n.favoriRetirer : l10n.favoriAjouter,
      onPressed: () => _basculer(context, ref),
    );
  }
}
