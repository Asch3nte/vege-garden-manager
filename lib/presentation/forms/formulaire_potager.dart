import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/dimensions_app.dart';
import '../../application/state/potagers_notifier.dart';
import '../../domain/entities/potager.dart';
import '../../domain/enums/type_climat.dart';
import '../../domain/enums/type_emplacement.dart';
import '../../domain/enums/zone_rusticite.dart';
import '../../domain/value_objects/zone_climatique.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/libelles_enums.dart';

/// Opens the "new garden" form as a full-screen route and returns the created
/// [Potager] (or `null` if cancelled).
Future<Potager?> ouvrirFormulairePotager(BuildContext context) {
  return Navigator.of(context).push<Potager>(
    MaterialPageRoute(builder: (_) => const FormulairePotager(), fullscreenDialog: true),
  );
}

/// Minimal garden-creation form: name + location type + climate + hardiness.
///
/// Climate and hardiness default to sensible values (oceanic / zone 8) so a
/// first-time user can create a garden in seconds; both are editable later.
/// Persists through [PotagersNotifier.creer] and pops the created entity.
class FormulairePotager extends ConsumerStatefulWidget {
  const FormulairePotager({super.key});

  @override
  ConsumerState<FormulairePotager> createState() => _FormulairePotagerState();
}

class _FormulairePotagerState extends ConsumerState<FormulairePotager> {
  final _cleForm = GlobalKey<FormState>();
  final _nom = TextEditingController();
  TypeEmplacement _emplacement = TypeEmplacement.jardin;
  TypeClimat _climat = TypeClimat.oceanique;
  ZoneRusticite _rusticite = ZoneRusticite.zone8;
  bool _enregistrement = false;

  @override
  void dispose() {
    _nom.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_cleForm.currentState!.validate()) return;
    setState(() => _enregistrement = true);
    final potager = await ref.read(potagersProvider.notifier).creer(
          nom: _nom.text.trim(),
          zoneClimatique: ZoneClimatique(_climat, _rusticite),
          emplacement: _emplacement,
        );
    if (mounted) Navigator.of(context).pop(potager);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.formPotagerTitre)),
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
                labelText: l10n.formPotagerNom,
                border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.champObligatoire : null,
            ),
            const SizedBox(height: EspacementsApp.s4),
            DropdownButtonFormField<TypeEmplacement>(
              initialValue: _emplacement,
              decoration: InputDecoration(
                labelText: l10n.formPotagerEmplacement,
                border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
              ),
              items: [
                for (final e in TypeEmplacement.values)
                  DropdownMenuItem(value: e, child: Text(l10n.emplacement(e))),
              ],
              onChanged: (v) => setState(() => _emplacement = v!),
            ),
            const SizedBox(height: EspacementsApp.s4),
            DropdownButtonFormField<TypeClimat>(
              initialValue: _climat,
              decoration: InputDecoration(
                labelText: l10n.formPotagerClimat,
                border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
              ),
              items: [
                for (final c in TypeClimat.values)
                  DropdownMenuItem(value: c, child: Text(l10n.climat(c))),
              ],
              onChanged: (v) => setState(() => _climat = v!),
            ),
            const SizedBox(height: EspacementsApp.s4),
            DropdownButtonFormField<ZoneRusticite>(
              initialValue: _rusticite,
              decoration: InputDecoration(
                labelText: l10n.formPotagerRusticite,
                helperText: l10n.formPotagerRusticiteAide,
                helperMaxLines: 2,
                border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
              ),
              items: [
                for (final z in ZoneRusticite.values)
                  DropdownMenuItem(value: z, child: Text(l10n.rusticite(z))),
              ],
              onChanged: (v) => setState(() => _rusticite = v!),
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
}
