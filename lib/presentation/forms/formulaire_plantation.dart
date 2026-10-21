import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../app/theme/dimensions_app.dart';
import '../../application/providers/unites_provider.dart';
import '../../application/state/catalogue_notifier.dart';
import '../../application/state/plantations_notifier.dart';
import '../../domain/entities/fiche_plante.dart';
import '../../domain/entities/plantation.dart';
import '../../domain/enums/methode_mise_en_place.dart';
import '../../domain/exceptions/surface_insuffisante_exception.dart';
import '../../domain/value_objects/surface.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/champ_deroulant_decrit.dart';
import '../widgets/formateur_mesures.dart';
import '../widgets/icones_communes.dart';
import '../widgets/langue_contexte.dart';
import '../widgets/libelles_enums.dart';
import '../glossaire/terme_glossaire.dart';
import 'enregistrement_formulaire.dart';
import 'saisie_mesures.dart';

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

class _FormulairePlantationState extends ConsumerState<FormulairePlantation>
    with EnregistrementFormulaire {
  final _cleForm = GlobalKey<FormState>();
  final _pieds = TextEditingController(text: '1');
  final _surface = TextEditingController();
  late final SaisieMesures _saisie = SaisieMesures(ref.read(unitesProvider));
  FichePlante? _plante;
  DateTime _date = DateTime.now();
  MethodeMiseEnPlace _methode = MethodeMiseEnPlace.semisDirect;
  bool _planteManquante = false;

  @override
  void initState() {
    super.initState();
    _plante = widget.planteInitiale;
    _surface.text = _saisie.surfacePourChamp(0.5);
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

    final l10n = AppLocalizations.of(context)!;
    // Read before the await: the form may be gone when the error comes back.
    final mesures = formateurMesuresLu(context, ref);
    await enregistrer(
        () => ref.read(plantationsProvider(widget.parcelleId).notifier).creer(
              planteId: _plante!.id,
              dateMiseEnPlace: _date,
              methode: _methode,
              surfaceOccupee: Surface.enMetresCarres(_saisie.surfaceVersM2(
                double.parse(_surface.text.trim().replaceAll(',', '.')),
              )),
              nombrePieds: int.parse(_pieds.text.trim()),
            ),
        messageErreur: (e) => e is SurfaceInsuffisanteException
            ? l10n.plantationSurfaceInsuffisante(
                mesures.surfaceM2(e.disponible.enMetresCarres))
            : null);
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
                      child: Text(widget.planteInitiale!.nomLocalise(context.langue)),
                    ),
                    const Icon(PhosphorIconsRegular.lock, size: TaillesIconesApp.sm),
                  ],
                ),
              )
            else
              DropdownButtonFormField<FichePlante>(
                icon: const IconeDeroulante(),
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
                    DropdownMenuItem(value: f, child: Text(f.nomLocalise(context.langue))),
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
                    icon: const Icon(PhosphorIconsRegular.calendarBlank, size: TaillesIconesApp.sm),
                    label: Text(l10n.formPlantationDate),
                  ),
                ],
              ),
            ),
            const SizedBox(height: EspacementsApp.s4),
            ChampDeroulantDecrit<MethodeMiseEnPlace>(
              value: _methode,
              options: MethodeMiseEnPlace.values,
              libelle: l10n.methode,
              description: l10n.methodeDescription,
              labelText: l10n.formPlantationMethode,
              idAideGlossaire: TermeGlossaire.idNotion('methode-mise-en-place'),
              onChanged: (v) => setState(() => _methode = v),
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
                labelText:
                    l10n.formPlantationSurface(_saisie.symboleSurface(l10n)),
                border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
              ),
              validator: (v) => _validerDecimalPositif(v, l10n),
            ),
            const SizedBox(height: EspacementsApp.s6),
            FilledButton(
              onPressed: enregistrementEnCours ? null : _enregistrer,
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
