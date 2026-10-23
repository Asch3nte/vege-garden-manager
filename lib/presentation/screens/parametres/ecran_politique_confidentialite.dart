import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/service_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/document/lecteur_document.dart';
import '../../widgets/document/vue_document.dart';
import 'widgets_parametres.dart';

/// Reads an embedded text asset by its path.
final lectureAssetTexteProvider =
    Provider<Future<String> Function(String)>((ref) => rootBundle.loadString);

/// The privacy policy embedded in the app, per language code (French unless
/// English).
final politiqueConfidentialiteProvider =
    FutureProvider.family<List<BlocDocument>, String>((ref, langue) async {
  final suffixe = langue == 'en' ? '.en' : '';
  final source = await ref
      .watch(lectureAssetTexteProvider)('docs/politique-confidentialite$suffixe.md');
  return const LecteurDocument().lire(source);
});

/// Shows the privacy policy, readable offline.
class EcranPolitiqueConfidentialite extends ConsumerWidget {
  const EcranPolitiqueConfidentialite({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final langue = Localizations.localeOf(context).languageCode;
    final politique = ref.watch(politiqueConfidentialiteProvider(langue));
    return PanneauParametres(
      titre: l10n.politiqueConfidentialite,
      enfants: [
        switch (politique) {
          AsyncData(:final value) => VueDocument(
              // The screen title already names the document.
              blocs: value
                  .where((b) => b is! TitreDocument || b.niveau > 1)
                  .toList(),
              onLien: (url) => _ouvrir(context, ref, url),
            ),
          AsyncError() => Text(l10n.politiqueConfidentialiteErreur),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ],
    );
  }

  Future<void> _ouvrir(BuildContext context, WidgetRef ref, Uri url) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (!await ref.read(ouvertureLienServiceProvider).ouvrir(url)) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.aproposLienErreur)));
    }
  }
}
