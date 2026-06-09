import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/dimensions_app.dart';
import '../../application/state/parcelles_notifier.dart';
import '../../domain/entities/parcelle.dart';
import '../../domain/enums/niveau_soleil.dart';
import '../../domain/enums/type_parcelle.dart';
import '../../domain/value_objects/surface.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/libelles_enums.dart';

/// Opens the "new zone" form for [potagerId] and returns the created [Parcelle].
Future<Parcelle?> ouvrirFormulaireZone(BuildContext context, String potagerId) {
  return Navigator.of(context).push<Parcelle>(
    MaterialPageRoute(
      builder: (_) => FormulaireZone(potagerId: potagerId),
      fullscreenDialog: true,
    ),
  );
}

/// Minimal zone-creation form: name + type + surface (m²) + sun exposure,
/// scoped to a garden. Persists via the family-scoped [parcellesProvider].
class FormulaireZone extends ConsumerStatefulWidget {
  /// Garden the zone belongs to.
  final String potagerId;

  const FormulaireZone({super.key, required this.potagerId});

  @override
  ConsumerState<FormulaireZone> createState() => _FormulaireZoneState();
}

class _FormulaireZoneState extends ConsumerState<FormulaireZone> {
  final _cleForm = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _surface = TextEditingController(text: '1');
  TypeParcelle _type = TypeParcelle.bacSureleve;
  NiveauSoleil _exposition = NiveauSoleil.pleinSoleil;
  bool _enregistrement = false;

  @override
  void dispose() {
    _nom.dispose();
    _surface.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_cleForm.currentState!.validate()) return;
    setState(() => _enregistrement = true);
    final surface = Surface.enMetresCarres(
      double.parse(_surface.text.trim().replaceAll(',', '.')),
    );
    final parcelle = await ref
        .read(parcellesProvider(widget.potagerId).notifier)
        .creer(
          nom: _nom.text.trim(),
          type: _type,
          surface: surface,
          exposition: _exposition,
        );
    if (mounted) Navigator.of(context).pop(parcelle);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.formZoneTitre)),
      body: Form(
        key: _cleForm,
        child: ListView(
          padding: const EdgeInsets.all(EspacementsApp.s4),
          children: [
            TextFormField(
              controller: _nom,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.formZoneNom,
                border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.champObligatoire : null,
            ),
            const SizedBox(height: EspacementsApp.s4),
            DropdownButtonFormField<TypeParcelle>(
              initialValue: _type,
              decoration: InputDecoration(
                labelText: l10n.formZoneType,
                border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
              ),
              items: [
                for (final t in TypeParcelle.values)
                  DropdownMenuItem(value: t, child: Text(l10n.typeParcelle(t))),
              ],
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: EspacementsApp.s4),
            TextFormField(
              controller: _surface,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.formZoneSurface,
                border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
              ),
              validator: (v) => _validerSurface(v, l10n),
            ),
            const SizedBox(height: EspacementsApp.s4),
            DropdownButtonFormField<NiveauSoleil>(
              initialValue: _exposition,
              decoration: InputDecoration(
                labelText: l10n.formZoneExposition,
                border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
              ),
              items: [
                for (final s in NiveauSoleil.values)
                  DropdownMenuItem(value: s, child: Text(l10n.exposition(s))),
              ],
              onChanged: (v) => setState(() => _exposition = v!),
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

  String? _validerSurface(String? v, AppLocalizations l10n) {
    if (v == null || v.trim().isEmpty) return l10n.champObligatoire;
    final n = double.tryParse(v.trim().replaceAll(',', '.'));
    if (n == null || n <= 0) return l10n.champNombrePositif;
    return null;
  }
}
