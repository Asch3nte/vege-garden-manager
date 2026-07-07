import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/dimensions_app.dart';
import '../../l10n/app_localizations.dart';
import 'chapitre_glossaire.dart';
import 'glossaire_providers.dart';
import 'libelles_glossaire.dart';
import 'ligne_terme.dart';
import 'registre_glossaire.dart';

/// One glossary chapter (`/plus/aide/chapitre/:nom`): the list of its terms,
/// in registry order (references sorted alphabetically, notions in catalogue
/// order). An unknown chapter name renders a friendly not-found body.
class EcranChapitreGlossaire extends ConsumerWidget {
  /// `ChapitreGlossaire.name` received from the route path.
  final String nomChapitre;

  const EcranChapitreGlossaire({super.key, required this.nomChapitre});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final chapitre = ChapitreGlossaire.values.asNameMap()[nomChapitre];
    final donnees = ref.watch(glossaireDonneesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(chapitre == null
            ? l10n.glossaireTitre
            : l10n.chapitreGlossaire(chapitre)),
      ),
      body: chapitre == null
          ? Center(child: Text(l10n.glossaireTermeIntrouvable))
          : donnees.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text(l10n.accueilErreurChargement)),
              data: (data) {
                final termes = construireGlossaire(
                  l10n: l10n,
                  familles: data.familles,
                  bioagresseurs: data.bioagresseurs,
                ).where((t) => t.chapitre == chapitre);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(EspacementsApp.s4,
                      EspacementsApp.s2, EspacementsApp.s4, EspacementsApp.s6),
                  children: [
                    for (final terme in termes)
                      LigneTermeGlossaire(terme: terme),
                  ],
                );
              },
            ),
    );
  }
}
