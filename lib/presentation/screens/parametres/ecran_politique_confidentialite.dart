import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/service_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/document/lecteur_document.dart';
import '../../widgets/document/vue_document.dart';
import '../../widgets/ouverture_lien.dart';
import 'widgets_parametres.dart';

/// The privacy policy for a language code, without its title (the screen's
/// own).
final politiqueConfidentialiteProvider = FutureProvider.autoDispose
    .family<List<BlocDocument>, String>((ref, langue) async {
  try {
    final source =
        await ref.watch(politiqueConfidentialiteSourceProvider).lire(langue);
    return List.unmodifiable(const LecteurDocument()
        .lire(source)
        .where((b) => b is! TitreDocument || b.niveau > 1));
  } on Exception catch (e, pile) {
    developer.log('Privacy policy unreadable',
        name: 'confidentialite', error: e, stackTrace: pile);
    rethrow;
  }
});

/// Shows the privacy policy, readable offline.
class EcranPolitiqueConfidentialite extends ConsumerWidget {
  const EcranPolitiqueConfidentialite({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final langue = Localizations.localeOf(context).languageCode;
    return PanneauParametres(
      titre: l10n.politiqueConfidentialite,
      enfants: [
        switch (ref.watch(politiqueConfidentialiteProvider(langue))) {
          AsyncData(:final value) => VueDocument(
              blocs: value,
              onLien: (url) => ouvrirLienExterne(context, ref, url),
            ),
          AsyncError() => Text(l10n.politiqueConfidentialiteErreur),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ],
    );
  }
}
