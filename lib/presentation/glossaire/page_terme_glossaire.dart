import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/dimensions_app.dart';
import '../../l10n/app_localizations.dart';
import 'complement_terme.dart';
import 'glossaire_providers.dart';
import 'libelles_glossaire.dart';
import 'ligne_terme.dart';
import 'registre_glossaire.dart';
import 'terme_cliquable.dart';
import 'terme_glossaire.dart';
import 'texte_avec_liens.dart';

/// A glossary term page (`/plus/aide/terme/:id`, ADR-0017 D3): kind badge +
/// chapter, optional illustration, definition with rendered wiki links,
/// « 💡 Astuce », advice list, then the typed derived blocks (family,
/// bioaggressor, enum values, see-also). An unknown id renders a friendly
/// not-found body — never invented content.
///
/// Being a real go_router sub-route, the page joins the global back history:
/// back replays term pages in the exact order the user opened them.
class PageTermeGlossaire extends ConsumerWidget {
  /// Prefixed term id received from the route path (e.g. `famille.solanaceae`).
  final String idTerme;

  const PageTermeGlossaire({super.key, required this.idTerme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final donnees = ref.watch(glossaireDonneesProvider);

    return donnees.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.glossaireTitre)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.glossaireTitre)),
        body: Center(child: Text(l10n.accueilErreurChargement)),
      ),
      data: (data) {
        final index = indexerParId(construireGlossaire(
          l10n: l10n,
          familles: data.familles,
          bioagresseurs: data.bioagresseurs,
        ));
        final terme = index[idTerme];
        if (terme == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.glossaireTitre)),
            body: Center(child: Text(l10n.glossaireTermeIntrouvable)),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(terme.titre)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(EspacementsApp.s4,
                EspacementsApp.s4, EspacementsApp.s4, EspacementsApp.s6),
            children: [
              _Entete(terme: terme),
              if (terme.illustration != null) ...[
                const SizedBox(height: EspacementsApp.s4),
                ClipRRect(
                  borderRadius: RayonsApp.brLg,
                  child: Image.asset(terme.illustration!, fit: BoxFit.cover),
                ),
              ],
              const SizedBox(height: EspacementsApp.s4),
              TexteAvecLiens(texte: terme.definition, index: index),
              if (terme.astuce != null) ...[
                const SizedBox(height: EspacementsApp.s4),
                _Astuce(texte: terme.astuce!, index: index),
              ],
              if (terme.conseils.isNotEmpty) ...[
                const SizedBox(height: EspacementsApp.s4),
                _SousTitre(l10n.glossaireConseils),
                for (final conseil in terme.conseils)
                  Padding(
                    padding: const EdgeInsets.only(top: EspacementsApp.s2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  '),
                        Expanded(
                            child: TexteAvecLiens(texte: conseil, index: index)),
                      ],
                    ),
                  ),
              ],
              for (final complement in terme.complements)
                switch (complement) {
                  ComplementFamille() =>
                    _BlocFamille(bloc: complement, index: index),
                  ComplementBioagresseur() =>
                    _BlocBioagresseur(bloc: complement, index: index),
                  ComplementValeursEnum() =>
                    _BlocValeurs(bloc: complement, index: index),
                  ComplementProvenanceMecanisme() =>
                    _BlocProvenance(bloc: complement),
                  ComplementVoirAussi() =>
                    _BlocVoirAussi(bloc: complement, index: index),
                },
            ],
          ),
        );
      },
    );
  }
}

/// Kind badge + chapter mention.
class _Entete extends StatelessWidget {
  final TermeGlossaire terme;

  const _Entete({required this.terme});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        BadgeTypeTerme(terme: terme),
        const SizedBox(width: EspacementsApp.s2),
        Expanded(
          child: Text(
            l10n.chapitreGlossaire(terme.chapitre),
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// « 💡 Astuce » tinted block (wiki links rendered, D2 — one grammar for all
/// glossary texts).
class _Astuce extends StatelessWidget {
  final String texte;
  final Map<String, TermeGlossaire> index;

  const _Astuce({required this.texte, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(EspacementsApp.s3),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: RayonsApp.brLg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline,
              size: TaillesIconesApp.md, color: theme.colorScheme.primary),
          const SizedBox(width: EspacementsApp.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.glossaireAstuce,
                    style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary)),
                TexteAvecLiens(texte: texte, index: index),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SousTitre extends StatelessWidget {
  final String texte;

  const _SousTitre(this.texte);

  @override
  Widget build(BuildContext context) {
    return Text(texte, style: Theme.of(context).textTheme.titleMedium);
  }
}

/// Clickable chips towards other term pages, tinted by the D5 chart;
/// unresolved ids are skipped (never a dead chip).
class _ChipsTermes extends StatelessWidget {
  final List<String> ids;
  final Map<String, TermeGlossaire> index;

  const _ChipsTermes({required this.ids, required this.index});

  @override
  Widget build(BuildContext context) {
    final cibles = [for (final id in ids) index[id]].nonNulls.toList();
    if (cibles.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: EspacementsApp.s2,
      runSpacing: EspacementsApp.s1,
      children: [
        for (final cible in cibles)
          PuceTermeGlossaire(
            idTerme: cible.id,
            texte: cible.titre,
            type: cible.type,
          ),
      ],
    );
  }
}

/// Family block: scientific name, rotation rationale (+ return delay), shared
/// diseases/pests as clickable chips, enemies & associations notes.
class _BlocFamille extends StatelessWidget {
  final ComplementFamille bloc;
  final Map<String, TermeGlossaire> index;

  const _BlocFamille({required this.bloc, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;
    final famille = bloc.famille;
    final pourquoiRotation = famille.pourquoiRotation(locale);
    final ennemis = famille.ennemisCommunsNote(locale);
    final associations = famille.associationsNote(locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: EspacementsApp.s4),
        Text(
          famille.nomScientifique,
          style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant),
        ),
        if (pourquoiRotation != null || famille.delaiRetourAnnees != null) ...[
          const SizedBox(height: EspacementsApp.s4),
          _SousTitre(l10n.ficheFamilleRotation),
          if (pourquoiRotation != null) ...[
            const SizedBox(height: EspacementsApp.s1),
            Text(pourquoiRotation, style: theme.textTheme.bodyMedium),
          ],
          if (famille.delaiRetourAnnees != null) ...[
            const SizedBox(height: EspacementsApp.s1),
            Text(
              l10n.glossaireDelaiRetour(famille.delaiRetourAnnees!),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ],
        if (bloc.idsMaladies.isNotEmpty) ...[
          const SizedBox(height: EspacementsApp.s4),
          _SousTitre(l10n.ficheFamilleMaladies),
          const SizedBox(height: EspacementsApp.s2),
          _ChipsTermes(ids: bloc.idsMaladies, index: index),
        ],
        if (bloc.idsRavageurs.isNotEmpty) ...[
          const SizedBox(height: EspacementsApp.s4),
          _SousTitre(l10n.ficheFamilleRavageurs),
          const SizedBox(height: EspacementsApp.s2),
          _ChipsTermes(ids: bloc.idsRavageurs, index: index),
        ],
        if (ennemis != null) ...[
          const SizedBox(height: EspacementsApp.s2),
          Text(ennemis, style: theme.textTheme.bodyMedium),
        ],
        if (associations != null) ...[
          const SizedBox(height: EspacementsApp.s4),
          _SousTitre(l10n.ficheFamilleAssociations),
          const SizedBox(height: EspacementsApp.s1),
          Text(associations, style: theme.textTheme.bodyMedium),
        ],
      ],
    );
  }
}

/// Bioaggressor block: EPPO code and the families that share it (clickable).
class _BlocBioagresseur extends StatelessWidget {
  final ComplementBioagresseur bloc;
  final Map<String, TermeGlossaire> index;

  const _BlocBioagresseur({required this.bloc, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final codeEppo = bloc.bioagresseur.codeEppo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (codeEppo != null) ...[
          const SizedBox(height: EspacementsApp.s4),
          Text(
            l10n.glossaireCodeEppo(codeEppo),
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
        if (bloc.idsFamilles.isNotEmpty) ...[
          const SizedBox(height: EspacementsApp.s4),
          _SousTitre(l10n.glossaireFamillesConcernees),
          const SizedBox(height: EspacementsApp.s2),
          _ChipsTermes(ids: bloc.idsFamilles, index: index),
        ],
      ],
    );
  }
}

/// Enum-values block: each value with its existing description — rendered
/// with wiki links (D2: one grammar for every glossary text).
class _BlocValeurs extends StatelessWidget {
  final ComplementValeursEnum bloc;
  final Map<String, TermeGlossaire> index;

  const _BlocValeurs({required this.bloc, required this.index});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: EspacementsApp.s4),
        for (final valeur in bloc.valeurs)
          Padding(
            padding: const EdgeInsets.only(top: EspacementsApp.s2),
            child: TexteAvecLiens(
              texte: valeur.description == null ? '' : ' — ${valeur.description}',
              index: index,
              prefixe: TextSpan(
                text: valeur.libelle,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}

/// Provenance block of a mechanism page: "computed by the engine" (derivation
/// rules) vs "documented by the permaculture community" (curated pairs).
class _BlocProvenance extends StatelessWidget {
  final ComplementProvenanceMecanisme bloc;

  const _BlocProvenance({required this.bloc});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: EspacementsApp.s4),
      child: Container(
        padding: const EdgeInsets.all(EspacementsApp.s3),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: RayonsApp.brLg,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              bloc.calculeParMoteur
                  ? Icons.memory_outlined
                  : Icons.menu_book_outlined,
              size: TaillesIconesApp.md,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: EspacementsApp.s2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.glossaireProvenanceTitre,
                      style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant)),
                  Text(
                    bloc.calculeParMoteur
                        ? l10n.glossaireProvenanceCalculee
                        : l10n.glossaireProvenanceDocumentee,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// « Voir aussi » block: clickable chips to related terms.
class _BlocVoirAussi extends StatelessWidget {
  final ComplementVoirAussi bloc;
  final Map<String, TermeGlossaire> index;

  const _BlocVoirAussi({required this.bloc, required this.index});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: EspacementsApp.s4),
        _SousTitre(l10n.glossaireVoirAussi),
        const SizedBox(height: EspacementsApp.s2),
        _ChipsTermes(ids: bloc.ids, index: index),
      ],
    );
  }
}
