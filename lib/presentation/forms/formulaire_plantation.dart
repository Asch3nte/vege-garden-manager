import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/dimensions_app.dart';
import '../../application/state/catalogue_notifier.dart';
import '../../application/state/plantations_notifier.dart';
import '../../domain/entities/fiche_plante.dart';
import '../../domain/entities/plantation.dart';
import '../../domain/enums/methode_mise_en_place.dart';
import '../../domain/value_objects/surface.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/libelles_enums.dart';

/// Opens the "new plantation" form for [parcelleId] and returns the created
/// [Plantation].
///
/// When [planteInitiale] is provided (e.g. the user picked a plant from the
/// catalogue), the plant is pre-selected and locked, so only the planting
/// details remain to fill.
Future<Plantation?> ouvrirFormulairePlantation(
  BuildContext context,
  String parcelleId, {
  FichePlante? planteInitiale,
}) {
  return Navigator.of(context).push<Plantation>(
    MaterialPageRoute(
      builder: (_) => FormulairePlantation(
        parcelleId: parcelleId,
        planteInitiale: planteInitiale,
      ),
      fullscreenDialog: true,
    ),
  );
}

/// Minimal plantation-creation form: pick a plant from the catalogue, set the
/// date, method, number of plants and occupied surface. Scoped to a zone.
///
/// If [planteInitiale] is set, the plant choice is fixed (shown read-only) — the
/// caller already chose it from the catalogue.
class FormulairePlantation extends ConsumerStatefulWidget {
  /// Zone the plantation belongs to.
  final String parcelleId;

  /// Pre-selected, locked plant (null = let the user pick from a dropdown).
  final FichePlante? planteInitiale;

  const FormulairePlantation({
    super.key,
    required this.parcelleId,
    this.planteInitiale,
  });

  @override
  ConsumerState<FormulairePlantation> createState() =>
      _FormulairePlantationState();
}

class _FormulairePlantationState extends ConsumerState<FormulairePlantation> {
  final _cleForm = GlobalKey<FormState>();
  final _pieds = TextEditingController(text: '1');
  final _surface = TextEditingController(text: '0.5');
  FichePlante? _plante;
  DateTime _date = DateTime.now();
  MethodeMiseEnPlace _methode = MethodeMiseEnPlace.semisDirect;
  bool _enregistrement = false;
  bool _planteManquante = false;

  @override
  void initState() {
    super.initState();
    _plante = widget.planteInitiale;
  }

  @override
  void dispose() {
    _pieds.dispose();
    _surface.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final choisie = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(_date.year - 2),
      lastDate: DateTime(_date.year + 2),
    );
    if (choisie != null) setState(() => _date = choisie);
  }

  Future<void> _enregistrer() async {
    final formOk = _cleForm.currentState!.validate();
    setState(() => _planteManquante = _plante == null);
    if (!formOk || _plante == null) return;

    setState(() => _enregistrement = true);
    final plantation =
        await ref.read(plantationsProvider(widget.parcelleId).notifier).creer(
              planteId: _plante!.id,
              dateMiseEnPlace: _date,
              methode: _methode,
              surfaceOccupee: Surface.enMetresCarres(
                double.parse(_surface.text.trim().replaceAll(',', '.')),
              ),
              nombrePieds: int.parse(_pieds.text.trim()),
            );
    if (mounted) Navigator.of(context).pop(plantation);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fiches = ref.watch(catalogueProvider).value?.fiches ?? const <FichePlante>[];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.formPlantationTitre)),
      body: Form(
        key: _cleForm,
        child: ListView(
          padding: const EdgeInsets.all(EspacementsApp.s4),
          children: [
            // Plant choice: locked when pre-selected from the catalogue,
            // otherwise a dropdown over the catalogue.
            if (widget.planteInitiale != null)
              InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.formPlantationPlante,
                  border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(widget.planteInitiale!.nomLocalise('fr')),
                    ),
                    const Icon(Icons.lock_outline, size: TaillesIconesApp.sm),
                  ],
                ),
              )
            else
              DropdownButtonFormField<FichePlante>(
                initialValue: _plante,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.formPlantationPlante,
                  hintText: l10n.formPlantationPlanteChoisir,
                  errorText: _planteManquante ? l10n.champObligatoire : null,
                  border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
                ),
                items: [
                  for (final f in fiches)
                    DropdownMenuItem(value: f, child: Text(f.nomLocalise('fr'))),
                ],
                onChanged: (v) => setState(() {
                  _plante = v;
                  _planteManquante = false;
                }),
              ),
            const SizedBox(height: EspacementsApp.s4),
            // Date row (label + value, tap to pick).
            InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.formPlantationDate,
                border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(_formaterDate(_date))),
                  TextButton.icon(
                    onPressed: _choisirDate,
                    icon: const Icon(Icons.calendar_today, size: TaillesIconesApp.sm),
                    label: Text(l10n.formPlantationDate),
                  ),
                ],
              ),
            ),
            const SizedBox(height: EspacementsApp.s4),
            DropdownButtonFormField<MethodeMiseEnPlace>(
              initialValue: _methode,
              decoration: InputDecoration(
                labelText: l10n.formPlantationMethode,
                border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
              ),
              items: [
                for (final m in MethodeMiseEnPlace.values)
                  DropdownMenuItem(value: m, child: Text(l10n.methode(m))),
              ],
              onChanged: (v) => setState(() => _methode = v!),
            ),
            const SizedBox(height: EspacementsApp.s4),
            TextFormField(
              controller: _pieds,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.formPlantationPieds,
                border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
              ),
              validator: (v) => _validerEntierPositif(v, l10n),
            ),
            const SizedBox(height: EspacementsApp.s4),
            TextFormField(
              controller: _surface,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.formPlantationSurface,
                border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
              ),
              validator: (v) => _validerDecimalPositif(v, l10n),
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

  String? _validerEntierPositif(String? v, AppLocalizations l10n) {
    if (v == null || v.trim().isEmpty) return l10n.champObligatoire;
    final n = int.tryParse(v.trim());
    if (n == null || n <= 0) return l10n.champNombrePositif;
    return null;
  }

  String? _validerDecimalPositif(String? v, AppLocalizations l10n) {
    if (v == null || v.trim().isEmpty) return l10n.champObligatoire;
    final n = double.tryParse(v.trim().replaceAll(',', '.'));
    if (n == null || n <= 0) return l10n.champNombrePositif;
    return null;
  }

  static String _formaterDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}
