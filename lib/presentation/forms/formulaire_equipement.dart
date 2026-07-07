import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/dimensions_app.dart';
import '../../application/providers/horloge_provider.dart';
import '../../application/state/equipements_notifier.dart';
import '../../application/state/parcelles_notifier.dart';
import '../../domain/entities/equipement.dart';
import '../../domain/enums/etat_equipement.dart';
import '../../domain/enums/type_equipement.dart';
import '../../l10n/app_localizations.dart';
import '../glossaire/catalogue/outils.dart';
import '../glossaire/terme_cliquable.dart';
import '../glossaire/terme_glossaire.dart';
import '../widgets/libelles_enums.dart';

/// Opens the equipment form for [potagerId] and returns the saved [Equipement].
///
/// When [equipementInitial] is provided, the form opens in **edit** mode
/// (pre-filled, persists changes); otherwise it creates a new equipment.
/// [parcelleIdInitiale] pre-attaches a creation to a zone (e.g. opened from the
/// zone detail); it is ignored in edit mode.
Future<Equipement?> ouvrirFormulaireEquipement(
  BuildContext context,
  String potagerId, {
  Equipement? equipementInitial,
  String? parcelleIdInitiale,
}) {
  return Navigator.of(context).push<Equipement>(
    MaterialPageRoute(
      builder: (_) => FormulaireEquipement(
        potagerId: potagerId,
        equipementInitial: equipementInitial,
        parcelleIdInitiale: parcelleIdInitiale,
      ),
      fullscreenDialog: true,
    ),
  );
}

/// Equipment form scoped to a garden: name + type + location (whole garden or a
/// zone) + condition + optional brand/model, installation date, planned
/// replacement and notes. Creates an equipment, or edits [equipementInitial]
/// when provided. Persists via the family-scoped [equipementsProvider].
class FormulaireEquipement extends ConsumerStatefulWidget {
  /// Garden the equipment belongs to.
  final String potagerId;

  /// Equipment being edited (null = creation).
  final Equipement? equipementInitial;

  /// Zone to pre-attach a new equipment to (creation only).
  final String? parcelleIdInitiale;

  const FormulaireEquipement({
    super.key,
    required this.potagerId,
    this.equipementInitial,
    this.parcelleIdInitiale,
  });

  @override
  ConsumerState<FormulaireEquipement> createState() =>
      _FormulaireEquipementState();
}

class _FormulaireEquipementState extends ConsumerState<FormulaireEquipement> {
  final _cleForm = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _marqueModele = TextEditingController();
  final _notes = TextEditingController();

  TypeEquipement _type = TypeEquipement.oya;
  EtatEquipement _etat = EtatEquipement.bon;
  // null = transverse (attached to the whole garden, no parcelle).
  String? _parcelleId;
  late DateTime _dateInstallation;
  DateTime? _dateRemplacement;
  bool _enregistrement = false;

  bool get _edition => widget.equipementInitial != null;

  @override
  void initState() {
    super.initState();
    final e = widget.equipementInitial;
    if (e != null) {
      _nom.text = e.nom;
      _marqueModele.text = e.marqueModele ?? '';
      _notes.text = e.notes ?? '';
      _type = e.type;
      _etat = e.etat;
      _parcelleId = e.parcelleId;
      _dateInstallation = e.dateInstallation;
      _dateRemplacement = e.dateRemplacementPrevue;
    } else {
      _parcelleId = widget.parcelleIdInitiale;
      _dateInstallation = ref.read(horlogeProvider)();
    }
  }

  @override
  void dispose() {
    _nom.dispose();
    _marqueModele.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _choisirDateInstallation() async {
    final choisie = await showDatePicker(
      context: context,
      initialDate: _dateInstallation,
      firstDate: DateTime(_dateInstallation.year - 20),
      lastDate: DateTime(_dateInstallation.year + 20),
    );
    if (choisie == null) return;
    setState(() {
      _dateInstallation = choisie;
      // Keep the invariant "replacement >= installation" (asserted by the
      // entity): clear a now-inconsistent replacement date.
      if (_dateRemplacement != null && _dateRemplacement!.isBefore(choisie)) {
        _dateRemplacement = null;
      }
    });
  }

  Future<void> _choisirDateRemplacement() async {
    final base = _dateRemplacement ?? _dateInstallation;
    final choisie = await showDatePicker(
      context: context,
      initialDate: base.isBefore(_dateInstallation) ? _dateInstallation : base,
      firstDate: _dateInstallation,
      lastDate: DateTime(_dateInstallation.year + 20),
    );
    if (choisie != null) setState(() => _dateRemplacement = choisie);
  }

  Future<void> _enregistrer() async {
    if (!_cleForm.currentState!.validate()) return;
    setState(() => _enregistrement = true);
    final notifier = ref.read(equipementsProvider(widget.potagerId).notifier);
    final marque = _marqueModele.text.trim();
    final notes = _notes.text.trim();

    final Equipement equipement;
    final initial = widget.equipementInitial;
    if (initial != null) {
      // Edit: rebuild with the same id, preserving the retirement date (edited
      // through its own action, not this form).
      equipement = Equipement(
        id: initial.id,
        nom: _nom.text.trim(),
        potagerId: initial.potagerId,
        type: _type,
        dateInstallation: _dateInstallation,
        parcelleId: _parcelleId,
        etat: _etat,
        marqueModele: marque.isEmpty ? null : marque,
        dateRemplacementPrevue: _dateRemplacement,
        dateRetrait: initial.dateRetrait,
        notes: notes.isEmpty ? null : notes,
      );
      await notifier.modifier(equipement);
    } else {
      equipement = await notifier.creer(
        nom: _nom.text.trim(),
        type: _type,
        dateInstallation: _dateInstallation,
        parcelleId: _parcelleId,
        etat: _etat,
        marqueModele: marque.isEmpty ? null : marque,
        dateRemplacementPrevue: _dateRemplacement,
        notes: notes.isEmpty ? null : notes,
      );
    }
    if (mounted) Navigator.of(context).pop(equipement);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Zones of the garden feed the location dropdown; empty while loading.
    final parcelles =
        ref.watch(parcellesProvider(widget.potagerId)).value ?? const [];
    // Only offer the current selection if it resolves to a loaded zone, so the
    // dropdown never asserts on an unknown value (the source of truth stays
    // `_parcelleId`, untouched until the user changes it).
    final valeurEmplacement =
        parcelles.any((p) => p.id == _parcelleId) ? _parcelleId : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_edition ? l10n.equipFormTitreModifier : l10n.equipFormTitre),
      ),
      body: Form(
        key: _cleForm,
        child: ListView(
          padding: const EdgeInsets.all(EspacementsApp.s4),
          children: [
            TextFormField(
              controller: _nom,
              autofocus: !_edition,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.equipFormNom,
                border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.champObligatoire : null,
            ),
            const SizedBox(height: EspacementsApp.s4),
            DropdownButtonFormField<TypeEquipement>(
              initialValue: _type,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.equipFormType,
                border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
                // The glossary help points to the selected type's page
                // (TypeEquipement.autre has no page — hide it then).
                suffixIcon: _type == TypeEquipement.autre
                    ? null
                    : AideGlossaire(
                        idTerme: idOutilEquipement(_type),
                        infobulle: l10n.typeEquipement(_type),
                      ),
              ),
              items: [
                for (final t in TypeEquipement.values)
                  DropdownMenuItem(
                    value: t,
                    child: Row(
                      children: [
                        Icon(iconeTypeEquipement(t), size: TaillesIconesApp.sm),
                        const SizedBox(width: EspacementsApp.s2),
                        Text(l10n.typeEquipement(t)),
                      ],
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: EspacementsApp.s4),
            DropdownButtonFormField<String?>(
              initialValue: valeurEmplacement,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.equipFormEmplacement,
                border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.equipTransverse)),
                for (final p in parcelles)
                  DropdownMenuItem(value: p.id, child: Text(p.nom)),
              ],
              onChanged: (v) => setState(() => _parcelleId = v),
            ),
            const SizedBox(height: EspacementsApp.s4),
            DropdownButtonFormField<EtatEquipement>(
              initialValue: _etat,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.equipFormEtat,
                border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
                suffixIcon: AideGlossaire(
                  idTerme: TermeGlossaire.idNotion('etat-equipement'),
                  infobulle: l10n.equipFormEtat,
                ),
              ),
              items: [
                for (final e in EtatEquipement.values)
                  DropdownMenuItem(
                      value: e, child: Text(l10n.etatEquipement(e))),
              ],
              onChanged: (v) => setState(() => _etat = v!),
            ),
            const SizedBox(height: EspacementsApp.s4),
            TextFormField(
              controller: _marqueModele,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.equipFormMarqueModele,
                border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
              ),
            ),
            const SizedBox(height: EspacementsApp.s4),
            _ChampDate(
              label: l10n.equipFormDateInstallation,
              valeur: _formaterDate(_dateInstallation),
              onChoisir: _choisirDateInstallation,
            ),
            const SizedBox(height: EspacementsApp.s4),
            _ChampDate(
              label: l10n.equipFormDateRemplacement,
              valeur: _dateRemplacement == null
                  ? l10n.equipFormDateNonDefinie
                  : _formaterDate(_dateRemplacement!),
              onChoisir: _choisirDateRemplacement,
              onEffacer: _dateRemplacement == null
                  ? null
                  : () => setState(() => _dateRemplacement = null),
            ),
            const SizedBox(height: EspacementsApp.s4),
            TextFormField(
              controller: _notes,
              textCapitalization: TextCapitalization.sentences,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.equipFormNotes,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
              ),
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

/// A read-only date field with a "pick" button, and an optional "clear" button
/// for nullable dates (the planned replacement).
class _ChampDate extends StatelessWidget {
  final String label;
  final String valeur;
  final VoidCallback onChoisir;
  final VoidCallback? onEffacer;

  const _ChampDate({
    required this.label,
    required this.valeur,
    required this.onChoisir,
    this.onEffacer,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
      ),
      child: Row(
        children: [
          Expanded(child: Text(valeur)),
          if (onEffacer != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.clear, size: TaillesIconesApp.sm),
              tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
              onPressed: onEffacer,
            ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.calendar_today, size: TaillesIconesApp.sm),
            tooltip: label,
            onPressed: onChoisir,
          ),
        ],
      ),
    );
  }
}
