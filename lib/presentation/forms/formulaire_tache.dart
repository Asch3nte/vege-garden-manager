import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/dimensions_app.dart';
import '../../application/providers/horloge_provider.dart';
import '../../application/providers/repository_providers.dart';
import '../../application/state/potager_notifier.dart';
import '../../application/use_cases/creer_tache.dart';
import '../../domain/entities/tache.dart';
import '../../domain/enums/cible_tache.dart';
import '../../domain/enums/type_tache.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/libelles_enums.dart';

/// Opens the task form and returns the saved [Tache] (or `null`). When
/// [tacheInitiale] is provided, the form opens in **edit** mode (pre-filled).
Future<Tache?> ouvrirFormulaireTache(
  BuildContext context, {
  Tache? tacheInitiale,
}) {
  return Navigator.of(context).push<Tache>(
    MaterialPageRoute(
      builder: (_) => FormulaireTache(tacheInitiale: tacheInitiale),
      fullscreenDialog: true,
    ),
  );
}

/// A possible target for a task: the whole garden or one of its zones.
///
/// Value equality (by [cible] + [id]) so the dropdown still matches the selected
/// option after a rebuild rebuilds the option list.
class _CibleOption {
  final CibleTache cible;
  final String id;
  final String label;

  const _CibleOption(this.cible, this.id, this.label);

  @override
  bool operator ==(Object other) =>
      other is _CibleOption && other.cible == cible && other.id == id;

  @override
  int get hashCode => Object.hash(cible, id);
}

/// Minimal task form: title + gesture type + due date + target (the whole
/// garden or a zone). Creates via [CreerTache], or edits [tacheInitiale].
class FormulaireTache extends ConsumerStatefulWidget {
  /// Task being edited (null = creation).
  final Tache? tacheInitiale;

  const FormulaireTache({super.key, this.tacheInitiale});

  @override
  ConsumerState<FormulaireTache> createState() => _FormulaireTacheState();
}

class _FormulaireTacheState extends ConsumerState<FormulaireTache> {
  final _cleForm = GlobalKey<FormState>();
  final _titre = TextEditingController();
  TypeTache _type = TypeTache.arrosage;
  DateTime? _date;
  _CibleOption? _cible;
  bool _enregistrement = false;

  bool get _edition => widget.tacheInitiale != null;

  @override
  void initState() {
    super.initState();
    final t = widget.tacheInitiale;
    if (t != null) {
      _titre.text = t.titre;
      _type = t.type;
      _date = t.datePrevue;
    }
  }

  @override
  void dispose() {
    _titre.dispose();
    super.dispose();
  }

  /// Targets available for the active garden: the whole garden, each zone, and
  /// each active crop (so a task can be tied to a specific plantation). Crops are
  /// listed under their zone, labelled `Zone › Culture` to disambiguate.
  List<_CibleOption> _cibles(AppLocalizations l10n) {
    final vue = ref.watch(potagerProvider).value;
    if (vue?.potagerId == null) return const [];
    return [
      _CibleOption(CibleTache.potager, vue!.potagerId!, l10n.formTacheCiblePotager),
      for (final zone in vue.zones) ...[
        _CibleOption(CibleTache.parcelle, zone.id, zone.nom),
        for (final culture in zone.cultures)
          _CibleOption(
            CibleTache.plantation,
            culture.plantationId,
            '${zone.nom} › ${culture.nom}',
          ),
      ],
    ];
  }

  Future<void> _choisirDate() async {
    final base = _date ?? ref.read(horlogeProvider)();
    final choisie = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(base.year - 1),
      lastDate: DateTime(base.year + 2),
    );
    if (choisie != null) setState(() => _date = choisie);
  }

  Future<void> _enregistrer() async {
    if (!_cleForm.currentState!.validate() || _cible == null) return;
    setState(() => _enregistrement = true);
    final datePrevue = _date ?? ref.read(horlogeProvider)();

    final Tache tache;
    final initial = widget.tacheInitiale;
    if (initial != null) {
      // Edit: rebuild with the same id, preserving the lifecycle fields (type
      // and target are final on the entity).
      tache = Tache(
        id: initial.id,
        titre: _titre.text.trim(),
        type: _type,
        cible: _cible!.cible,
        cibleId: _cible!.id,
        datePrevue: datePrevue,
        etat: initial.etat,
        priorite: initial.priorite,
        description: initial.description,
        dateRealisation: initial.dateRealisation,
        dureeReelleMinutes: initial.dureeReelleMinutes,
        rappelOrigineId: initial.rappelOrigineId,
        notes: initial.notes,
      );
      await ref.read(tacheRepositoryProvider).sauvegarder(tache);
    } else {
      tache = await ref.read(creerTacheProvider).executer(
            titre: _titre.text.trim(),
            type: _type,
            cible: _cible!.cible,
            cibleId: _cible!.id,
            datePrevue: datePrevue,
          );
    }
    if (mounted) Navigator.of(context).pop(tache);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cibles = _cibles(l10n);
    if (_cible == null && cibles.isNotEmpty) {
      final t = widget.tacheInitiale;
      _cible = t == null
          ? cibles.first
          : cibles.firstWhere(
              (c) => c.cible == t.cible && c.id == t.cibleId,
              orElse: () => cibles.first,
            );
    }
    final dateLabel =
        _date == null ? l10n.formTacheDateAujourdhui : _formaterDate(_date!);

    return Scaffold(
      appBar: AppBar(
        title: Text(_edition ? l10n.formTacheTitreModifier : l10n.formTacheTitre),
      ),
      body: cibles.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(EspacementsApp.s6),
                child: Text(
                  l10n.formTacheSansPotager,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          : Form(
              key: _cleForm,
              child: ListView(
                padding: const EdgeInsets.all(EspacementsApp.s4),
                children: [
                  TextFormField(
                    controller: _titre,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.formTacheNom,
                      border:
                          const OutlineInputBorder(borderRadius: RayonsApp.brMd),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.champObligatoire
                        : null,
                  ),
                  const SizedBox(height: EspacementsApp.s4),
                  DropdownButtonFormField<TypeTache>(
                    initialValue: _type,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.formTacheType,
                      border:
                          const OutlineInputBorder(borderRadius: RayonsApp.brMd),
                    ),
                    items: [
                      for (final t in TypeTache.values)
                        DropdownMenuItem(value: t, child: Text(l10n.typeTache(t))),
                    ],
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                  const SizedBox(height: EspacementsApp.s4),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.formTacheDate,
                      border:
                          const OutlineInputBorder(borderRadius: RayonsApp.brMd),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(dateLabel)),
                        TextButton.icon(
                          onPressed: _choisirDate,
                          icon: const Icon(Icons.calendar_today,
                              size: TaillesIconesApp.sm),
                          label: Text(l10n.formTacheDate),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: EspacementsApp.s4),
                  DropdownButtonFormField<_CibleOption>(
                    initialValue: _cible,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.formTacheCible,
                      border:
                          const OutlineInputBorder(borderRadius: RayonsApp.brMd),
                    ),
                    items: [
                      for (final c in cibles)
                        DropdownMenuItem(value: c, child: Text(c.label)),
                    ],
                    onChanged: (v) => setState(() => _cible = v),
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

  static String _formaterDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}
