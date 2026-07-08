import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/dimensions_app.dart';
import '../../application/state/fiches_personnelles_notifier.dart';
import '../../domain/entities/fiche_plante_personnelle.dart';
import '../../domain/enums/besoin_eau.dart';
import '../../domain/enums/categorie_plante.dart';
import '../../domain/enums/niveau_soleil.dart';
import '../../domain/enums/qualite_sol.dart';
import '../../domain/enums/sous_type_legume.dart';
import '../../domain/enums/usage_plante.dart';
import '../../domain/services/id_fiche_personnelle.dart';
import '../../domain/value_objects/modele_fiche_personnelle.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/libelles_enums.dart';

/// Opens the personal-sheet form and returns the saved [FichePlantePersonnelle],
/// or `null` if the user cancelled.
///
/// When [ficheInitiale] is provided, the form opens in **edit** mode
/// (pre-filled, persists changes); otherwise it creates a new sheet. A
/// [modeleInitial] pre-fills a fresh draft (e.g. duplicated from a catalogue
/// sheet) without being an edit — it is ignored when [ficheInitiale] is set.
Future<FichePlantePersonnelle?> ouvrirFormulaireFichePersonnelle(
  BuildContext context, {
  FichePlantePersonnelle? ficheInitiale,
  ModeleFichePersonnelle? modeleInitial,
}) {
  return Navigator.of(context).push<FichePlantePersonnelle>(
    MaterialPageRoute(
      builder: (_) => FormulaireFichePersonnelle(
        ficheInitiale: ficheInitiale,
        modeleInitial: modeleInitial,
      ),
      fullscreenDialog: true,
    ),
  );
}

/// Editor for a user-authored plant sheet (MVP subset: identity + basic
/// cultivation). Creates a sheet, or edits [ficheInitiale] when provided.
/// Persists through [fichesPersonnellesProvider], which refreshes the catalogue.
class FormulaireFichePersonnelle extends ConsumerStatefulWidget {
  /// Sheet being edited (null = creation).
  final FichePlantePersonnelle? ficheInitiale;

  /// Draft to pre-fill a creation with (ignored in edit mode).
  final ModeleFichePersonnelle? modeleInitial;

  const FormulaireFichePersonnelle({
    super.key,
    this.ficheInitiale,
    this.modeleInitial,
  });

  @override
  ConsumerState<FormulaireFichePersonnelle> createState() =>
      _FormulaireFichePersonnelleState();
}

class _FormulaireFichePersonnelleState
    extends ConsumerState<FormulaireFichePersonnelle> {
  final _cleForm = GlobalKey<FormState>();
  final _nomFr = TextEditingController();
  final _nomEn = TextEditingController();
  final _nomScientifique = TextEditingController();
  final _famille = TextEditingController();
  final _espacement = TextEditingController();
  final _recolteMin = TextEditingController();
  final _recolteMax = TextEditingController();
  final _description = TextEditingController();

  CategoriePlante _categorie = CategoriePlante.legume;
  SousTypeLegume? _sousType;
  final Set<UsagePlante> _usages = {};
  final Set<QualiteSol> _qualitesSol = {};
  NiveauSoleil _ensoleillement = NiveauSoleil.pleinSoleil;
  BesoinEau _arrosage = BesoinEau.modere;
  RangeValues _ph = const RangeValues(6, 7);
  int? _difficulte;

  bool _usagesEnErreur = false;
  bool _qualitesEnErreur = false;
  bool _enregistrement = false;

  bool get _edition => widget.ficheInitiale != null;

  @override
  void initState() {
    super.initState();
    final modele = widget.ficheInitiale?.contenu ?? widget.modeleInitial;
    if (modele != null) _prefill(modele);
  }

  void _prefill(ModeleFichePersonnelle m) {
    _nomFr.text = m.nomCommunFr;
    _nomEn.text = m.nomCommunEn ?? '';
    _nomScientifique.text = m.nomScientifique;
    _famille.text = m.familleBotanique;
    _espacement.text = m.espacementCm.toString();
    _recolteMin.text = m.dureeAvantRecolteJoursMin.toString();
    _recolteMax.text = m.dureeAvantRecolteJoursMax.toString();
    _description.text = m.descriptionFr ?? '';
    _categorie = m.categorie;
    _sousType = m.sousType;
    _usages
      ..clear()
      ..addAll(m.usages);
    _qualitesSol
      ..clear()
      ..addAll(m.qualitesSol);
    _ensoleillement = m.ensoleillement;
    _arrosage = m.arrosage;
    _ph = RangeValues(m.phMin, m.phMax);
    _difficulte = m.difficulte;
  }

  @override
  void dispose() {
    _nomFr.dispose();
    _nomEn.dispose();
    _nomScientifique.dispose();
    _famille.dispose();
    _espacement.dispose();
    _recolteMin.dispose();
    _recolteMax.dispose();
    _description.dispose();
    super.dispose();
  }

  /// Builds the edited model. Assumes the form has passed validation, so numeric
  /// fields parse and the required sets are non-empty. The logical id is derived
  /// from the French name on creation and preserved on edit (the use case also
  /// enforces this — kept consistent here for a valid model).
  ModeleFichePersonnelle _versModele() {
    final nomFr = _nomFr.text.trim();
    final nomEn = _nomEn.text.trim();
    final description = _description.text.trim();
    return ModeleFichePersonnelle(
      idFiche: widget.ficheInitiale?.idFiche ?? IdFichePersonnelle.depuisNom(nomFr),
      categorie: _categorie,
      sousType: _categorie == CategoriePlante.legume ? _sousType : null,
      usages: _usages,
      nomScientifique: _nomScientifique.text.trim(),
      familleBotanique: _famille.text.trim(),
      nomCommunFr: nomFr,
      nomCommunEn: nomEn.isEmpty ? null : nomEn,
      descriptionFr: description.isEmpty ? null : description,
      ensoleillement: _ensoleillement,
      arrosage: _arrosage,
      qualitesSol: _qualitesSol,
      phMin: _ph.start,
      phMax: _ph.end,
      espacementCm: int.parse(_espacement.text.trim()),
      dureeAvantRecolteJoursMin: int.parse(_recolteMin.text.trim()),
      dureeAvantRecolteJoursMax: int.parse(_recolteMax.text.trim()),
      difficulte: _difficulte,
    );
  }

  Future<void> _enregistrer() async {
    // Text fields validate through the Form; the two required multi-selects are
    // FormField-free, so they are checked here and surfaced with inline errors.
    final champsOk = _cleForm.currentState!.validate();
    final usagesOk = _usages.isNotEmpty;
    final qualitesOk = _qualitesSol.isNotEmpty;
    setState(() {
      _usagesEnErreur = !usagesOk;
      _qualitesEnErreur = !qualitesOk;
    });
    if (!champsOk || !usagesOk || !qualitesOk) return;

    setState(() => _enregistrement = true);
    final notifier = ref.read(fichesPersonnellesProvider.notifier);
    final modele = _versModele();
    final FichePlantePersonnelle fiche;
    if (widget.ficheInitiale != null) {
      fiche = await notifier.modifier(
        existante: widget.ficheInitiale!,
        contenu: modele,
      );
    } else {
      fiche = await notifier.creer(modele);
    }
    if (mounted) Navigator.of(context).pop(fiche);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _edition ? l10n.fichePersoFormTitreModifier : l10n.fichePersoFormTitre,
        ),
      ),
      body: Form(
        key: _cleForm,
        child: ListView(
          padding: const EdgeInsets.all(EspacementsApp.s4),
          children: [
            _Section(titre: l10n.fichePersoFormSectionIdentite),
            _champTexte(
              controller: _nomFr,
              label: l10n.fichePersoFormNomFr,
              autofocus: !_edition,
              obligatoire: true,
            ),
            _espace(),
            _champTexte(
              controller: _nomScientifique,
              label: l10n.fichePersoFormNomScientifique,
              obligatoire: true,
            ),
            _espace(),
            _champTexte(
              controller: _famille,
              label: l10n.fichePersoFormFamille,
              obligatoire: true,
            ),
            _espace(),
            _champTexte(
              controller: _nomEn,
              label: l10n.fichePersoFormNomEn,
            ),
            _espace(),
            DropdownButtonFormField<CategoriePlante>(
              initialValue: _categorie,
              isExpanded: true,
              decoration: _decoration(l10n.fichePersoFormCategorie),
              items: [
                for (final c in CategoriePlante.values)
                  DropdownMenuItem(value: c, child: Text(l10n.categorie(c))),
              ],
              onChanged: (v) => setState(() {
                _categorie = v!;
                if (_categorie != CategoriePlante.legume) _sousType = null;
              }),
            ),
            if (_categorie == CategoriePlante.legume) ...[
              _espace(),
              DropdownButtonFormField<SousTypeLegume?>(
                initialValue: _sousType,
                isExpanded: true,
                decoration: _decoration(l10n.fichePersoFormSousType),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(l10n.fichePersoFormDifficulteNon),
                  ),
                  for (final s in SousTypeLegume.values)
                    DropdownMenuItem(
                      value: s,
                      child: Text(l10n.sousTypeLegume(s)),
                    ),
                ],
                onChanged: (v) => setState(() => _sousType = v),
              ),
            ],
            _espace(),
            _ChampChips<UsagePlante>(
              label: l10n.fichePersoFormUsages,
              valeurs: UsagePlante.values,
              selection: _usages,
              libelle: l10n.usagePlante,
              enErreur: _usagesEnErreur,
              messageErreur: l10n.fichePersoFormUsagesRequis,
              onToggle: (v, actif) => setState(() {
                actif ? _usages.add(v) : _usages.remove(v);
                if (_usages.isNotEmpty) _usagesEnErreur = false;
              }),
            ),
            _Section(titre: l10n.fichePersoFormSectionCulture),
            DropdownButtonFormField<NiveauSoleil>(
              initialValue: _ensoleillement,
              isExpanded: true,
              decoration: _decoration(l10n.fichePersoFormEnsoleillement),
              items: [
                for (final s in NiveauSoleil.values)
                  DropdownMenuItem(value: s, child: Text(l10n.exposition(s))),
              ],
              onChanged: (v) => setState(() => _ensoleillement = v!),
            ),
            _espace(),
            DropdownButtonFormField<BesoinEau>(
              initialValue: _arrosage,
              isExpanded: true,
              decoration: _decoration(l10n.fichePersoFormArrosage),
              items: [
                for (final e in BesoinEau.values)
                  DropdownMenuItem(value: e, child: Text(l10n.besoinEau(e))),
              ],
              onChanged: (v) => setState(() => _arrosage = v!),
            ),
            _espace(),
            _ChampChips<QualiteSol>(
              label: l10n.fichePersoFormQualitesSol,
              valeurs: QualiteSol.values,
              selection: _qualitesSol,
              libelle: l10n.qualiteSol,
              enErreur: _qualitesEnErreur,
              messageErreur: l10n.fichePersoFormQualitesRequis,
              onToggle: (v, actif) => setState(() {
                actif ? _qualitesSol.add(v) : _qualitesSol.remove(v);
                if (_qualitesSol.isNotEmpty) _qualitesEnErreur = false;
              }),
            ),
            _espace(),
            _ChampPh(
              valeurs: _ph,
              onChanged: (v) => setState(() => _ph = v),
            ),
            _espace(),
            _champEntier(
              controller: _espacement,
              label: l10n.fichePersoFormEspacement,
            ),
            _espace(),
            _champEntier(
              controller: _recolteMin,
              label: l10n.fichePersoFormRecolteMin,
            ),
            _espace(),
            _champEntier(
              controller: _recolteMax,
              label: l10n.fichePersoFormRecolteMax,
              validateurSup: (n) {
                final min = int.tryParse(_recolteMin.text.trim());
                return (min != null && n < min)
                    ? l10n.fichePersoFormRecolteMaxInvalide
                    : null;
              },
            ),
            _espace(),
            DropdownButtonFormField<int?>(
              initialValue: _difficulte,
              isExpanded: true,
              decoration: _decoration(l10n.fichePersoFormDifficulte),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(l10n.fichePersoFormDifficulteNon),
                ),
                for (final n in [1, 2, 3])
                  DropdownMenuItem(
                    value: n,
                    child: Text(l10n.fichePersoFormDifficulteValeur(n)),
                  ),
              ],
              onChanged: (v) => setState(() => _difficulte = v),
            ),
            _espace(),
            _champTexte(
              controller: _description,
              label: l10n.fichePersoFormDescription,
              lignes: 3,
            ),
            const SizedBox(height: EspacementsApp.s6),
            FilledButton(
              onPressed: _enregistrement ? null : _enregistrer,
              child: Text(l10n.actionEnregistrer),
            ),
          ],
        ),
      ),
    );
  }

  // ---- small builders keeping the tree readable -------------------------------

  Widget _espace() => const SizedBox(height: EspacementsApp.s4);

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
      );

  Widget _champTexte({
    required TextEditingController controller,
    required String label,
    bool obligatoire = false,
    bool autofocus = false,
    int lignes = 1,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      textCapitalization: TextCapitalization.sentences,
      minLines: lignes,
      maxLines: lignes == 1 ? 1 : lignes + 1,
      decoration: _decoration(label).copyWith(alignLabelWithHint: lignes > 1),
      validator: obligatoire
          ? (v) => (v == null || v.trim().isEmpty) ? l10n.champObligatoire : null
          : null,
    );
  }

  Widget _champEntier({
    required TextEditingController controller,
    required String label,
    String? Function(int valeur)? validateurSup,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: _decoration(label),
      validator: (v) {
        final n = int.tryParse((v ?? '').trim());
        if (n == null || n <= 0) return l10n.champNombrePositif;
        return validateurSup?.call(n);
      },
    );
  }
}

/// A form section header with a little breathing room above it.
class _Section extends StatelessWidget {
  final String titre;

  const _Section({required this.titre});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: EspacementsApp.s3),
      child: Text(titre, style: theme.textTheme.titleMedium),
    );
  }
}

/// A labelled multi-select rendered as a wrap of [FilterChip]s, with an optional
/// inline error line when the selection is required but empty.
class _ChampChips<T> extends StatelessWidget {
  final String label;
  final List<T> valeurs;
  final Set<T> selection;
  final String Function(T) libelle;
  final bool enErreur;
  final String messageErreur;
  final void Function(T valeur, bool actif) onToggle;

  const _ChampChips({
    required this.label,
    required this.valeurs,
    required this.selection,
    required this.libelle,
    required this.enErreur,
    required this.messageErreur,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: EspacementsApp.s2),
        Wrap(
          spacing: EspacementsApp.s2,
          runSpacing: EspacementsApp.s1,
          children: [
            for (final v in valeurs)
              FilterChip(
                label: Text(libelle(v)),
                selected: selection.contains(v),
                onSelected: (actif) => onToggle(v, actif),
              ),
          ],
        ),
        if (enErreur) ...[
          const SizedBox(height: EspacementsApp.s1),
          Text(
            messageErreur,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.error),
          ),
        ],
      ],
    );
  }
}

/// A labelled soil-pH range picker (0..14, half-point steps).
class _ChampPh extends StatelessWidget {
  final RangeValues valeurs;
  final ValueChanged<RangeValues> onChanged;

  const _ChampPh({required this.valeurs, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.fichePersoFormPh(
            _formater(valeurs.start),
            _formater(valeurs.end),
          ),
          style: theme.textTheme.labelLarge,
        ),
        RangeSlider(
          values: valeurs,
          min: 0,
          max: 14,
          divisions: 28,
          labels: RangeLabels(
            _formater(valeurs.start),
            _formater(valeurs.end),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// Formats a pH value without a trailing `.0` (e.g. `7`, `6.5`).
  static String _formater(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}
