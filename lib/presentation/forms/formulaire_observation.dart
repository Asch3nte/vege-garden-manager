import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/dimensions_app.dart';
import '../../application/providers/horloge_provider.dart';
import '../../application/use_cases/creer_observation.dart';
import '../../domain/entities/observation.dart';
import '../../domain/enums/cible_observation.dart';
import '../../domain/enums/type_observation.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/libelles_enums.dart';

/// Opens the "record an observation" form for the plantation [plantationId] and
/// returns the created [Observation] (or `null` if cancelled).
Future<Observation?> ouvrirFormulaireObservation(
  BuildContext context,
  String plantationId, {
  String? plante,
}) {
  return Navigator.of(context).push<Observation>(
    MaterialPageRoute(
      builder: (_) =>
          FormulaireObservation(plantationId: plantationId, plante: plante),
      fullscreenDialog: true,
    ),
  );
}

/// Minimal observation form: type + title + date (+ optional description), for a
/// known plantation. Persists via [CreerObservation].
class FormulaireObservation extends ConsumerStatefulWidget {
  final String plantationId;
  final String? plante;

  const FormulaireObservation({
    required this.plantationId,
    this.plante,
    super.key,
  });

  @override
  ConsumerState<FormulaireObservation> createState() =>
      _FormulaireObservationState();
}

class _FormulaireObservationState extends ConsumerState<FormulaireObservation> {
  final _cleForm = GlobalKey<FormState>();
  final _titre = TextEditingController();
  final _description = TextEditingController();
  TypeObservation _type = TypeObservation.general;
  DateTime? _date;
  bool _enregistrement = false;

  @override
  void dispose() {
    _titre.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final base = _date ?? ref.read(horlogeProvider)();
    final choisie = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(base.year - 1),
      lastDate: DateTime(base.year + 1),
    );
    if (choisie != null) setState(() => _date = choisie);
  }

  Future<void> _enregistrer() async {
    if (!_cleForm.currentState!.validate()) return;
    setState(() => _enregistrement = true);
    final description = _description.text.trim();
    final observation = await ref.read(creerObservationProvider).executer(
          cible: CibleObservation.plantation,
          cibleId: widget.plantationId,
          date: _date ?? ref.read(horlogeProvider)(),
          type: _type,
          titre: _titre.text.trim(),
          description: description.isEmpty ? null : description,
        );
    if (mounted) Navigator.of(context).pop(observation);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateLabel =
        _date == null ? l10n.formTacheDateAujourdhui : _formaterDate(_date!);

    return Scaffold(
      appBar: AppBar(title: Text(widget.plante ?? l10n.formObservationTitre)),
      body: Form(
        key: _cleForm,
        child: ListView(
          padding: const EdgeInsets.all(EspacementsApp.s4),
          children: [
            DropdownButtonFormField<TypeObservation>(
              initialValue: _type,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.formObservationType,
                border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
              ),
              items: [
                for (final t in TypeObservation.values)
                  DropdownMenuItem(value: t, child: Text(l10n.typeObservation(t))),
              ],
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: EspacementsApp.s4),
            TextFormField(
              controller: _titre,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.formObservationNom,
                border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.champObligatoire : null,
            ),
            const SizedBox(height: EspacementsApp.s4),
            InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.formObservationDate,
                border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(dateLabel)),
                  TextButton.icon(
                    onPressed: _choisirDate,
                    icon: const Icon(Icons.calendar_today, size: TaillesIconesApp.sm),
                    label: Text(l10n.formObservationDate),
                  ),
                ],
              ),
            ),
            const SizedBox(height: EspacementsApp.s4),
            TextFormField(
              controller: _description,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.formObservationDescription,
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
