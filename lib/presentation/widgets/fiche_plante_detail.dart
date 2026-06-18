import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/dimensions_app.dart';
import '../../application/providers/horloge_provider.dart';
import '../../application/providers/repository_providers.dart';
import '../../application/state/catalogue_notifier.dart';
import '../../application/state/contexte_climat.dart';
import '../../domain/entities/famille_botanique.dart';
import '../../domain/entities/fiche_plante.dart';
import '../../domain/services/resolveur_compagnonnage.dart';
import '../../l10n/app_localizations.dart';
import 'calendrier_semis_recolte.dart';
import 'libelles_enums.dart';

/// Opens the detail of a plant sheet as a draggable modal bottom sheet.
///
/// Shows the sheet's **real** fields (category, sun & water needs, spacing,
/// time-to-harvest) and its companion associations (resolved to plant names via
/// the loaded catalogue). The sowing/harvest month calendar of the mock-up is
/// deferred — periods are indexed by hemisphere/climate, which a catalogue
/// browse has no context for (see docs/15).
///
/// On a species sheet a "variety switcher" lets the user drill into one of the
/// species' varieties in-place; a back button (and the OS back gesture) returns
/// to the species.
/// When [onAjouter] is provided, a pinned "Ajouter au potager" CTA is shown; it
/// closes the sheet and then runs the callback with the **currently displayed**
/// sheet (which may differ from [fiche] if the user drilled into a variety)
/// to drive the add-a-plant flow. Without it, the sheet is read-only.
Future<void> afficherFichePlanteDetail(
  BuildContext context,
  FichePlante fiche, {
  void Function(FichePlante)? onAjouter,
  ContexteAssociation? contexte,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => _FichePlanteDetail(
        fiche: fiche,
        scrollController: scrollController,
        onAjouter: onAjouter,
        contexte: contexte,
      ),
    ),
  );
}

/// Why this sheet was opened from the Associations view (ADR-0012): the relation
/// with the centre plant, shown as a coloured banner at the top of the sheet so
/// the full editorial reason is never truncated in the constellation.
class ContexteAssociation {
  /// Good companion (green) vs to-avoid (red).
  final bool bon;

  /// Localised mechanism / family label, or `null`.
  final String? mecanisme;

  /// Full localised editorial reason, or `null`.
  final String? raison;

  /// Whether the relation is a derived suggestion.
  final bool suggere;

  /// Localised confidence (derived only), or `null`.
  final String? confiance;

  /// Every factor (criterion) behind a derived association, each a full localised
  /// sentence with its real values (ADR-0014). Empty for a curated relation.
  final List<String> facteurs;

  const ContexteAssociation({
    required this.bon,
    this.mecanisme,
    this.raison,
    this.suggere = false,
    this.confiance,
    this.facteurs = const [],
  });
}

class _FichePlanteDetail extends ConsumerStatefulWidget {
  final FichePlante fiche;
  final ScrollController scrollController;
  final void Function(FichePlante)? onAjouter;
  final ContexteAssociation? contexte;

  const _FichePlanteDetail({
    required this.fiche,
    required this.scrollController,
    this.onAjouter,
    this.contexte,
  });

  @override
  ConsumerState<_FichePlanteDetail> createState() => _FichePlanteDetailState();
}

class _FichePlanteDetailState extends ConsumerState<_FichePlanteDetail> {
  /// The sheet currently shown: the species (mother) or one of its varieties,
  /// swapped in-place by the variety switcher / back button.
  late FichePlante _fiche = widget.fiche;

  /// Returns to the species sheet from a variety (back button / OS back).
  void _revenirEspece(FichePlante mere) => setState(() => _fiche = mere);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final vue = ref.watch(catalogueProvider).value;
    // The species this sheet belongs to (itself when it is one), and that
    // species' varieties — the only ones offered by the switcher.
    final mere = vue?.mereDe(_fiche) ?? _fiche;
    final varietes = vue?.varietesDe(mere.id) ?? const <FichePlante>[];
    final surVariete = _fiche.id != mere.id;

    // Companions are resolved by the shared service over **every** species
    // (not the filtered list), bidirectionally — so the names and counts here
    // match the Réseau view exactly (ADR-0008).
    const resolveur = ResolveurCompagnonnage();
    final compagnons =
        resolveur.resoudre(_fiche, vue?.toutesMeres ?? const <FichePlante>[]);
    final bons = _noms(compagnons.bons);
    final aEviter = _noms(compagnons.aEviter);

    final liste = ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
        EspacementsApp.s5,
        0,
        EspacementsApp.s5,
        EspacementsApp.s6,
      ),
      children: [
        // Association banner (ADR-0012) — only on the originally tapped sheet.
        if (widget.contexte != null && _fiche.id == widget.fiche.id) ...[
          _BandeauAssociation(contexte: widget.contexte!),
          const SizedBox(height: EspacementsApp.s4),
        ],
        Row(
          children: [
            // On a variety, a back button returns to the species sheet.
            if (surVariete)
              Padding(
                padding: const EdgeInsets.only(right: EspacementsApp.s1),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: l10n.ficheRetourEspece,
                  onPressed: () => _revenirEspece(mere),
                ),
              )
            else
              Icon(Icons.eco,
                  size: TaillesIconesApp.xl, color: theme.colorScheme.primary),
            const SizedBox(width: EspacementsApp.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_fiche.nomLocalise('fr'), style: theme.textTheme.headlineSmall),
                  Text(
                    l10n.categorie(_fiche.categorie),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: EspacementsApp.s2),
        Text(
          _fiche.nomScientifique,
          style: theme.textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        // Variety switcher: the line shows the species and opens a picker of its
        // varieties; choosing one re-renders the whole sheet for it. Hidden when
        // the species has no varieties.
        if (varietes.isNotEmpty)
          _SelecteurVariete(
            mere: mere,
            varietes: varietes,
            courante: _fiche,
            onChoisir: (v) => setState(() => _fiche = v),
          ),
        if (_fiche.descriptionLocalisee('fr') != null) ...[
          const SizedBox(height: EspacementsApp.s4),
          Text(
            _fiche.descriptionLocalisee('fr')!,
            style: theme.textTheme.bodyMedium,
          ),
        ],
        const SizedBox(height: EspacementsApp.s5),
        _Faits(fiche: _fiche),
        const SizedBox(height: EspacementsApp.s5),
        Text(l10n.ficheCalendrierTitre, style: theme.textTheme.titleLarge),
        const SizedBox(height: EspacementsApp.s3),
        _SectionCalendrier(fiche: _fiche),
        const SizedBox(height: EspacementsApp.s5),
        Text(l10n.ficheAssociations, style: theme.textTheme.titleLarge),
        const SizedBox(height: EspacementsApp.s3),
        _Associations(bons: bons, aEviter: aEviter),
        _SectionFamille(fiche: _fiche),
      ],
    );

    final onAjouter = widget.onAjouter;
    final contenu = onAjouter == null
        // Read-only sheet unless an add-to-garden action was supplied.
        ? liste
        : Column(
            children: [
              Expanded(child: liste),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    EspacementsApp.s5,
                    EspacementsApp.s2,
                    EspacementsApp.s5,
                    EspacementsApp.s4,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        // Close the sheet first, then run the flow on the page
                        // below for whichever sheet is currently displayed.
                        Navigator.of(context).pop();
                        onAjouter(_fiche);
                      },
                      icon: const Icon(Icons.add),
                      label: Text(l10n.ficheAjouterAuPotager),
                    ),
                  ),
                ),
              ),
            ],
          );

    // On a variety, the OS back gesture first returns to the species sheet
    // (consuming the pop); only from the species does it close the sheet.
    return PopScope(
      canPop: !surVariete,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _revenirEspece(mere);
      },
      child: contenu,
    );
  }

  /// Localized, alphabetically-sorted names of an iterable of sheets.
  List<String> _noms(Iterable<FichePlante> fiches) =>
      [for (final f in fiches) f.nomLocalise('fr')]..sort();
}

/// Variety switcher shown under the scientific name: a tappable line labelled
/// "Espèce" that shows the species name and opens a searchable picker of that
/// species' varieties.
class _SelecteurVariete extends StatelessWidget {
  final FichePlante mere;
  final List<FichePlante> varietes;
  final FichePlante courante;
  final ValueChanged<FichePlante> onChoisir;

  const _SelecteurVariete({
    required this.mere,
    required this.varietes,
    required this.courante,
    required this.onChoisir,
  });

  Future<void> _ouvrir(BuildContext context) async {
    final choix = await _choisirVariete(context, varietes, courante);
    if (choix != null && choix.id != courante.id) onChoisir(choix);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    // On the species sheet no variety is chosen yet — invite to pick one; on a
    // variety, show its name.
    final surVariete = courante.id != mere.id;
    final valeur =
        surVariete ? courante.nomLocalise('fr') : l10n.ficheVarieteChoisir;

    return InkWell(
      borderRadius: RayonsApp.brMd,
      onTap: () => _ouvrir(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: EspacementsApp.s2),
        child: Row(
          children: [
            Flexible(
              child: Text(
                valeur,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

/// Opens the variety picker (a searchable modal list) and returns the chosen
/// variety, or `null` if dismissed.
Future<FichePlante?> _choisirVariete(
  BuildContext context,
  List<FichePlante> varietes,
  FichePlante courante,
) {
  return showModalBottomSheet<FichePlante>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ListeVarietes(varietes: varietes, courante: courante),
  );
}

/// Searchable list of varieties used by the picker: a search field filtering by
/// localized or scientific name, then the matching varieties as tappable rows.
class _ListeVarietes extends StatefulWidget {
  final List<FichePlante> varietes;
  final FichePlante courante;

  const _ListeVarietes({required this.varietes, required this.courante});

  @override
  State<_ListeVarietes> createState() => _ListeVarietesState();
}

class _ListeVarietesState extends State<_ListeVarietes> {
  String _requete = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final terme = _requete.trim().toLowerCase();
    final resultats = [
      for (final v in widget.varietes)
        if (terme.isEmpty ||
            v.nomLocalise('fr').toLowerCase().contains(terme) ||
            v.nomScientifique.toLowerCase().contains(terme))
          v,
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                EspacementsApp.s5,
                0,
                EspacementsApp.s5,
                EspacementsApp.s3,
              ),
              child: TextField(
                onChanged: (v) => setState(() => _requete = v),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.ficheVarieteRecherche,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
                  isDense: true,
                ),
              ),
            ),
            if (resultats.isEmpty)
              Padding(
                padding: const EdgeInsets.all(EspacementsApp.s5),
                child: Text(
                  l10n.ficheVarieteAucune,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: resultats.length,
                  itemBuilder: (context, i) {
                    final v = resultats[i];
                    final selectionne = v.id == widget.courante.id;
                    return ListTile(
                      leading: Icon(Icons.spa_outlined,
                          color: theme.colorScheme.secondary),
                      title: Text(v.nomLocalise('fr')),
                      subtitle: Text(
                        v.nomScientifique,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      trailing: selectionne
                          ? Icon(Icons.check, color: theme.colorScheme.primary)
                          : null,
                      selected: selectionne,
                      onTap: () => Navigator.of(context).pop(v),
                    );
                  },
                ),
              ),
            const SizedBox(height: EspacementsApp.s2),
          ],
        ),
      ),
    );
  }
}

/// Two-column fact grid (exposure, watering, spacing, time-to-harvest).
class _Faits extends StatelessWidget {
  final FichePlante fiche;

  const _Faits({required this.fiche});

  /// Formats a pH value with a French decimal comma, dropping a trailing `,0`.
  static String _ph(double v) {
    final s = v.toStringAsFixed(1).replaceAll('.', ',');
    return s.endsWith(',0') ? s.substring(0, s.length - 2) : s;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final b = fiche.besoins;
    // Exposition shown as a **range** when a minimum tolerance is set (ADR-0014):
    // e.g. « Mi-ombre à plein soleil » instead of just the optimum.
    final expo = (b.soleilMin != null && b.soleilMin != b.soleil)
        ? l10n.ficheExpositionPlage(
            l10n.exposition(b.soleilMin!), l10n.exposition(b.soleil).toLowerCase())
        : l10n.exposition(b.soleil);
    final hMin = fiche.hauteurAdulteCmMin;
    final hMax = fiche.hauteurAdulteCmMax;
    final faits = <(IconData, String, String)>[
      (Icons.wb_sunny_outlined, l10n.ficheExposition, expo),
      (Icons.water_drop_outlined, l10n.ficheArrosage, l10n.besoinEau(b.eau)),
      (Icons.straighten, l10n.ficheEspacement, l10n.ficheEspacementCm(fiche.espacementCm)),
      if (hMin != null || hMax != null)
        (
          Icons.height,
          l10n.ficheHauteur,
          (hMin != null && hMax != null && hMin != hMax)
              ? l10n.ficheHauteurCm(hMin, hMax)
              : l10n.ficheHauteurCmUnique((hMax ?? hMin)!),
        ),
      (
        Icons.science_outlined,
        l10n.fichePh,
        l10n.fichePhPlage(_ph(b.phMin), _ph(b.phMax)),
      ),
      (
        Icons.eco_outlined,
        l10n.ficheRecolte,
        l10n.ficheRecolteJours(
          fiche.dureeAvantRecolteJoursMin,
          fiche.dureeAvantRecolteJoursMax,
        ),
      ),
    ];

    return Column(
      children: [
        for (final (icone, cle, valeur) in faits)
          Padding(
            padding: const EdgeInsets.only(bottom: EspacementsApp.s3),
            child: _Fait(icone: icone, cle: cle, valeur: valeur),
          ),
      ],
    );
  }
}

class _Fait extends StatelessWidget {
  final IconData icone;
  final String cle;
  final String valeur;

  const _Fait({required this.icone, required this.cle, required this.valeur});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icone, size: TaillesIconesApp.md, color: theme.colorScheme.primary),
        const SizedBox(width: EspacementsApp.s3),
        Text(
          cle,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const Spacer(),
        Text(valeur, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

/// Companion plants: good ones and ones to avoid.
class _Associations extends StatelessWidget {
  final List<String> bons;
  final List<String> aEviter;

  const _Associations({required this.bons, required this.aEviter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (bons.isEmpty && aEviter.isEmpty) {
      return Text(
        l10n.ficheAucuneAssociation,
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bons.isNotEmpty) ...[
          Text(l10n.ficheBonsCompagnons, style: theme.textTheme.bodySmall),
          const SizedBox(height: EspacementsApp.s2),
          Wrap(
            spacing: EspacementsApp.s2,
            runSpacing: EspacementsApp.s2,
            children: [for (final n in bons) Chip(label: Text(n))],
          ),
        ],
        if (aEviter.isNotEmpty) ...[
          const SizedBox(height: EspacementsApp.s4),
          Text(
            l10n.ficheAEviter,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
          ),
          const SizedBox(height: EspacementsApp.s2),
          Wrap(
            spacing: EspacementsApp.s2,
            runSpacing: EspacementsApp.s2,
            children: [
              for (final n in aEviter)
                Chip(
                  label: Text(n),
                  side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Sowing/harvest calendar for the sheet, resolved for the active garden's
/// climate context (hemisphere × climate). Falls back to a note when there is
/// no garden, and flags an assumed hemisphere when the garden has no position.
class _SectionCalendrier extends ConsumerWidget {
  final FichePlante fiche;

  const _SectionCalendrier({required this.fiche});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final contexte = ref.watch(contexteClimatProvider);

    return contexte.when(
      loading: () => const SizedBox(
        height: 24,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => Text(
        l10n.saisonNonRenseigne,
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      data: (ctx) {
        if (ctx == null) {
          return Text(
            l10n.ficheCalendrierSansContexte,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          );
        }
        final pc = fiche.periodesPour(ctx.hemisphere, ctx.climat);
        final moisActuel = ref.read(horlogeProvider)().month;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CalendrierSemisRecolte(
              semis: pc?.semisExterieur ?? pc?.semisInterieur,
              plantation: pc?.plantation,
              recolte: pc?.recolte,
              moisActuel: moisActuel,
            ),
            if (ctx.hemisphereSuppose) ...[
              const SizedBox(height: EspacementsApp.s2),
              Text(
                l10n.saisonHemisphereSuppose,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Family-level educational section (ADR-0006 Lot 4): the plant's botanical
/// family name + description, its rotation rationale, the diseases/pests it
/// commonly shares (resolved to localized names via the bioaggressor reference,
/// each with its description as a tooltip) and its association rationale.
///
/// Renders nothing when the family sheet is unknown; each editorial note is
/// shown only when present (no invented content — docs/15 rule).
class _SectionFamille extends ConsumerWidget {
  final FichePlante fiche;

  const _SectionFamille({required this.fiche});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final famille = ref
        .watch(familleBotaniqueCacheProvider)
        .value
        ?.parId(FamilleBotanique.normaliserCle(fiche.familleBotanique));
    if (famille == null) return const SizedBox.shrink();

    final bioCache = ref.watch(bioagresseurCacheProvider).value;
    Widget puce(String slug) {
      final bio = bioCache?.parId(slug);
      final chip = Chip(label: Text(bio?.nomLocalise('fr') ?? slug));
      final desc = bio?.descriptionLocalisee('fr');
      return desc == null ? chip : Tooltip(message: desc, child: chip);
    }

    Widget sousTitre(String t) => Padding(
          padding: const EdgeInsets.only(bottom: EspacementsApp.s2),
          child: Text(t, style: theme.textTheme.bodySmall),
        );

    final desc = famille.descriptionLocalisee('fr');
    final pourquoi = famille.pourquoiRotation('fr');
    final ennemis = famille.ennemisCommunsNote('fr');
    final assoc = famille.associationsNote('fr');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: EspacementsApp.s5),
        Text(l10n.ficheFamilleTitre(famille.nomLocalise('fr')),
            style: theme.textTheme.titleLarge),
        const SizedBox(height: EspacementsApp.s3),
        if (desc != null)
          Text(desc, style: theme.textTheme.bodyMedium),
        if (pourquoi != null) ...[
          const SizedBox(height: EspacementsApp.s4),
          sousTitre(l10n.ficheFamilleRotation),
          Text(pourquoi, style: theme.textTheme.bodySmall),
        ],
        if (famille.maladiesCommunes.isNotEmpty) ...[
          const SizedBox(height: EspacementsApp.s4),
          sousTitre(l10n.ficheFamilleMaladies),
          Wrap(
            spacing: EspacementsApp.s2,
            runSpacing: EspacementsApp.s2,
            children: [for (final s in famille.maladiesCommunes) puce(s)],
          ),
        ],
        if (famille.ravageursCommuns.isNotEmpty) ...[
          const SizedBox(height: EspacementsApp.s4),
          sousTitre(l10n.ficheFamilleRavageurs),
          Wrap(
            spacing: EspacementsApp.s2,
            runSpacing: EspacementsApp.s2,
            children: [for (final s in famille.ravageursCommuns) puce(s)],
          ),
        ],
        if (ennemis != null) ...[
          const SizedBox(height: EspacementsApp.s2),
          Text(
            ennemis,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
        if (assoc != null) ...[
          const SizedBox(height: EspacementsApp.s4),
          sousTitre(l10n.ficheFamilleAssociations),
          Text(assoc, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}


/// Coloured header explaining the association that led here (ADR-0012): the
/// mechanism/family, the full editorial reason (never truncated), and, for a
/// derived relation, a "suggested + confidence" note. Green for a good
/// companion, red (error) for a to-avoid.
class _BandeauAssociation extends StatelessWidget {
  final ContexteAssociation contexte;

  const _BandeauAssociation({required this.contexte});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final couleur =
        contexte.bon ? theme.colorScheme.primary : theme.colorScheme.error;
    final titre = contexte.mecanisme ??
        (contexte.bon ? l10n.ficheAssocBon : l10n.ficheAssocEviter);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EspacementsApp.s3),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.10),
        borderRadius: const BorderRadius.all(RayonsApp.md),
        border: Border.all(color: couleur.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(contexte.bon ? Icons.favorite_outline : Icons.block,
                  size: TaillesIconesApp.sm, color: couleur),
              const SizedBox(width: EspacementsApp.s2),
              Expanded(
                child: Text(
                  titre,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: couleur, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (contexte.suggere) ...[
            const SizedBox(height: EspacementsApp.s1),
            Text(
              contexte.confiance == null
                  ? l10n.assocSuggere
                  : '${l10n.assocSuggere} · ${contexte.confiance}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: couleur.withValues(alpha: 0.9),
                fontStyle: FontStyle.italic,
              ),
            ),
            // Every variable that entered the calculation, with its real value
            // (ADR-0014) — nothing left vague.
            if (contexte.facteurs.isNotEmpty) ...[
              const SizedBox(height: EspacementsApp.s2),
              Text(
                l10n.assocFacteursTitre,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              for (final f in contexte.facteurs)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•  ',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: couleur)),
                      Expanded(
                        child: Text(f, style: theme.textTheme.bodySmall),
                      ),
                    ],
                  ),
                ),
            ],
          ] else ...[
            // Curated association: the counterpart of "Suggestion · …",
            // elaborated here as promised by the cluster label (ADR-0013 §7).
            const SizedBox(height: EspacementsApp.s1),
            Text(
              l10n.assocHorsSuggestion,
              style: theme.textTheme.labelSmall?.copyWith(
                color: couleur.withValues(alpha: 0.9),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.assocHorsSuggestionExpl,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (contexte.raison != null) ...[
            const SizedBox(height: EspacementsApp.s2),
            Text(contexte.raison!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
