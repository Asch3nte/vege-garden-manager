import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/dimensions_app.dart';
import '../../l10n/app_localizations.dart';
import 'catalogue_notions.dart';
import 'chapitre_glossaire.dart';
import 'glossaire_providers.dart';
import 'libelles_glossaire.dart';
import 'ligne_terme.dart';
import 'recherche_glossaire.dart';
import 'registre_glossaire.dart';
import 'terme_glossaire.dart';

/// « Aide & lexique » — the glossary cover (ADR-0017, D3): an always-visible
/// search field, the « Par où commencer ? » novice entry, then the nine book
/// chapters with their entry counts. Reached from the Plus root
/// (`/plus/aide`); chapters and terms are sub-routes, so the global back
/// history replays pages in opening order.
class PanneauAide extends ConsumerStatefulWidget {
  const PanneauAide({super.key});

  @override
  ConsumerState<PanneauAide> createState() => _PanneauAideState();
}

class _PanneauAideState extends ConsumerState<PanneauAide> {
  final TextEditingController _controleur = TextEditingController();

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final donnees = ref.watch(glossaireDonneesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.glossaireTitre)),
      body: donnees.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.accueilErreurChargement)),
        data: (data) {
          final termes = construireGlossaire(
            l10n: l10n,
            familles: data.familles,
            bioagresseurs: data.bioagresseurs,
          );
          final requete = _controleur.text;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(EspacementsApp.s4,
                    EspacementsApp.s4, EspacementsApp.s4, 0),
                child: TextField(
                  controller: _controleur,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: l10n.glossaireRecherche,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: requete.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () =>
                                setState(() => _controleur.clear()),
                          ),
                  ),
                ),
              ),
              Expanded(
                child: normaliserRecherche(requete).isEmpty
                    ? _Chapitres(termes: termes)
                    : _Resultats(termes: termes, requete: requete),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The cover content: novice entry + chapter list with counts.
class _Chapitres extends StatelessWidget {
  final List<TermeGlossaire> termes;

  const _Chapitres({required this.termes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final index = indexerParId(termes);
    final commencer = index[idNotionCommencer];

    return ListView(
      padding: const EdgeInsets.fromLTRB(EspacementsApp.s4, EspacementsApp.s2,
          EspacementsApp.s4, EspacementsApp.s6),
      children: [
        if (commencer != null)
          Padding(
            padding: const EdgeInsets.only(top: EspacementsApp.s2),
            child: Material(
              color: theme.colorScheme.primaryContainer,
              borderRadius: RayonsApp.brLg,
              child: InkWell(
                borderRadius: RayonsApp.brLg,
                onTap: () =>
                    context.go(RoutesApp.aideTerme(commencer.id)),
                child: Padding(
                  padding: const EdgeInsets.all(EspacementsApp.s3),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_objects_outlined,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: EspacementsApp.s3),
                      Expanded(
                        child: Text(commencer.titre,
                            style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary)),
                      ),
                      Icon(Icons.chevron_right,
                          size: TaillesIconesApp.md,
                          color: theme.colorScheme.primary),
                    ],
                  ),
                ),
              ),
            ),
          ),
        for (final chapitre in ChapitreGlossaire.values)
          _LigneChapitre(
            chapitre: chapitre,
            nombre: termes.where((t) => t.chapitre == chapitre).length,
          ),
      ],
    );
  }
}

/// One chapter row: icon + label + entry count.
class _LigneChapitre extends StatelessWidget {
  final ChapitreGlossaire chapitre;
  final int nombre;

  const _LigneChapitre({required this.chapitre, required this.nombre});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(top: EspacementsApp.s2),
      child: Material(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: RayonsApp.brLg,
        child: InkWell(
          borderRadius: RayonsApp.brLg,
          onTap: () => context.go(RoutesApp.aideChapitre(chapitre.name)),
          child: Container(
            padding: const EdgeInsets.all(EspacementsApp.s3),
            decoration: BoxDecoration(
              borderRadius: RayonsApp.brLg,
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Row(
              children: [
                Icon(iconeChapitreGlossaire(chapitre),
                    color: theme.colorScheme.primary),
                const SizedBox(width: EspacementsApp.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.chapitreGlossaire(chapitre),
                          style: theme.textTheme.bodyLarge),
                      Text(
                        l10n.glossaireEntrees(nombre),
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    size: TaillesIconesApp.md,
                    color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Search results across the whole glossary (title matches first).
class _Resultats extends StatelessWidget {
  final List<TermeGlossaire> termes;
  final String requete;

  const _Resultats({required this.termes, required this.requete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final resultats = rechercherTermes(termes, requete);

    if (resultats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(EspacementsApp.s5),
          child: Text(
            l10n.glossaireAucunResultat,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(EspacementsApp.s4, EspacementsApp.s2,
          EspacementsApp.s4, EspacementsApp.s6),
      children: [
        for (final terme in resultats) LigneTermeGlossaire(terme: terme),
      ],
    );
  }
}
