import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../app/theme/dimensions_app.dart';
import '../../application/providers/horloge_provider.dart';
import '../../application/providers/langue_provider.dart';
import '../../application/providers/unites_provider.dart';
import '../../application/use_cases/creer_recolte.dart';
import '../../domain/entities/recolte.dart';
import '../../domain/enums/destination_recolte.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/icones_communes.dart';
import '../widgets/libelles_enums.dart';
import 'enregistrement_formulaire.dart';
import 'saisie_mesures.dart';

/// Opens the "record a harvest" form for [plantationId] and returns the created
/// [Recolte] (or `null` if cancelled).
Future<Recolte?> ouvrirFormulaireRecolte(
  BuildContext context,
  String plantationId, {
  String? plante,
}) {
  return Navigator.of(context).push<Recolte>(
    MaterialPageRoute(
      builder: (_) => FormulaireRecolte(plantationId: plantationId, plante: plante),
      fullscreenDialog: true,
    ),
  );
}

/// Minimal harvest form: date + quantity (value + unit) + destination, for a
/// known plantation. Persists via [CreerRecolte].
class FormulaireRecolte extends ConsumerStatefulWidget {
  final String plantationId;
  final String? plante;

  const FormulaireRecolte({
    required this.plantationId,
    this.plante,
    super.key,
  });

  @override
  ConsumerState<FormulaireRecolte> createState() => _FormulaireRecolteState();
}

class _FormulaireRecolteState extends ConsumerState<FormulaireRecolte>
    with EnregistrementFormulaire {
  final _cleForm = GlobalKey<FormState>();
  final _valeur = TextEditingController(text: '1');
  late final SaisieMesures _saisie =
      SaisieMesures(ref.read(unitesProvider), ref.read(codeLangueProvider));
  late UniteSaisieRecolte _unite = _saisie.uniteRecolteParDefaut;
  DestinationRecolte _destination = DestinationRecolte.consommationFraiche;
  DateTime? _date;

  @override
  void dispose() {
    _valeur.dispose();
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
    await enregistrer(() => ref.read(creerRecolteProvider).executer(
          plantationId: widget.plantationId,
          date: _date ?? ref.read(horlogeProvider)(),
          quantite: _saisie.quantite(
            double.parse(_valeur.text.trim().replaceAll(',', '.')),
            _unite,
          ),
          destination: _destination,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateLabel =
        _date == null ? l10n.formTacheDateAujourdhui : _formaterDate(_date!);

    return Scaffold(
      appBar: AppBar(title: Text(widget.plante ?? l10n.formRecolteTitre)),
      body: Form(
        key: _cleForm,
        child: ListView(
          padding: const EdgeInsets.all(EspacementsApp.s4),
          children: [
            InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.formRecolteDate,
                border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(dateLabel)),
                  TextButton.icon(
                    onPressed: _choisirDate,
                    icon: const Icon(PhosphorIconsRegular.calendarBlank, size: TaillesIconesApp.sm),
                    label: Text(l10n.formRecolteDate),
                  ),
                ],
              ),
            ),
            const SizedBox(height: EspacementsApp.s4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _valeur,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.formRecolteQuantite,
                      border:
                          const OutlineInputBorder(borderRadius: RayonsApp.brMd),
                    ),
                    validator: (v) => _validerDecimalPositif(v, l10n),
                  ),
                ),
                const SizedBox(width: EspacementsApp.s3),
                Expanded(
                  child: DropdownButtonFormField<UniteSaisieRecolte>(
                    icon: const IconeDeroulante(),
                    initialValue: _unite,
                    decoration: InputDecoration(
                      labelText: l10n.formRecolteUnite,
                      border:
                          const OutlineInputBorder(borderRadius: RayonsApp.brMd),
                    ),
                    items: [
                      for (final u in _saisie.unitesRecolte)
                        DropdownMenuItem(
                            value: u,
                            child: Text(SaisieMesures.libelle(l10n, u))),
                    ],
                    onChanged: (v) => setState(() => _unite = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: EspacementsApp.s4),
            DropdownButtonFormField<DestinationRecolte>(
              icon: const IconeDeroulante(),
              initialValue: _destination,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.formRecolteDestination,
                border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
              ),
              items: [
                for (final d in DestinationRecolte.values)
                  DropdownMenuItem(
                      value: d, child: Text(l10n.destinationRecolte(d))),
              ],
              onChanged: (v) => setState(() => _destination = v!),
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
