import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/dimensions_app.dart';
import '../../application/engine/derivateur_localisation.dart';
import '../../application/providers/service_providers.dart';
import '../../application/state/potagers_notifier.dart';
import '../../domain/entities/potager.dart';
import '../../domain/enums/permission_localisation.dart';
import '../../domain/enums/type_climat.dart';
import '../../domain/enums/type_emplacement.dart';
import '../../domain/enums/zone_rusticite.dart';
import '../../domain/value_objects/localisation.dart';
import '../../domain/value_objects/zone_climatique.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/capture_localisation.dart';
import '../widgets/libelles_enums.dart';

/// Opens the garden form as a full-screen route and returns the saved [Potager]
/// (or `null` if cancelled). When [potagerInitial] is provided, the form opens
/// in **edit** mode (pre-filled, persists changes).
Future<Potager?> ouvrirFormulairePotager(
  BuildContext context, {
  Potager? potagerInitial,
}) {
  return Navigator.of(context).push<Potager>(
    MaterialPageRoute(
      builder: (_) => FormulairePotager(potagerInitial: potagerInitial),
      fullscreenDialog: true,
    ),
  );
}

/// Minimal garden form: name + location type + climate + hardiness (+ position).
///
/// Climate and hardiness default to sensible values (oceanic / zone 8) so a
/// first-time user can create a garden in seconds; both are editable later.
/// Creates via [PotagersNotifier.creer], or edits [potagerInitial] in place.
class FormulairePotager extends ConsumerStatefulWidget {
  /// Garden being edited (null = creation).
  final Potager? potagerInitial;

  const FormulairePotager({super.key, this.potagerInitial});

  @override
  ConsumerState<FormulairePotager> createState() => _FormulairePotagerState();
}

class _FormulairePotagerState extends ConsumerState<FormulairePotager> {
  final _cleForm = GlobalKey<FormState>();
  final _nom = TextEditingController();
  TypeEmplacement _emplacement = TypeEmplacement.jardin;
  TypeClimat _climat = TypeClimat.oceanique;
  ZoneRusticite _rusticite = ZoneRusticite.zone8;
  Localisation _position = const Localisation.nonDefinie();
  bool _suggere = false; // climate/hardiness were pre-filled from the position
  bool _detection = false;
  bool _enregistrement = false;

  bool get _edition => widget.potagerInitial != null;

  @override
  void initState() {
    super.initState();
    final p = widget.potagerInitial;
    if (p != null) {
      _nom.text = p.nom;
      _emplacement = p.emplacement;
      _climat = p.zoneClimatique.type;
      _rusticite = p.zoneClimatique.rusticite;
      _position = p.localisation;
    }
  }

  @override
  void dispose() {
    _nom.dispose();
    super.dispose();
  }

  /// Captures the device position (opt-in), then pre-fills climate & hardiness
  /// from it (suggestions the user can still adjust). Hemisphere is implied by
  /// the stored position, so the Saison/calendar contexts become precise.
  Future<void> _detecterPosition() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(geolocalisationServiceProvider);

    setState(() => _detection = true);
    try {
      final permission = await service.demanderPermission();
      if (permission != PermissionLocalisation.accordee) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.formPotagerPositionRefusee)),
        );
        return;
      }
      _appliquerPosition(await service.positionActuelle());
      // The inline caption confirms the suggestion; no snackbar needed here.
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.formPotagerPositionErreur)),
      );
    } finally {
      if (mounted) setState(() => _detection = false);
    }
  }

  /// Stores [position] and pre-fills climate & hardiness from its derivation.
  void _appliquerPosition(Localisation position) {
    final suggestion = const DerivateurLocalisation().deriver(position);
    setState(() {
      _position = position;
      _climat = suggestion.climat;
      _rusticite = suggestion.rusticite;
      _suggere = true;
    });
  }

  /// Lets the user pick an approximate world region (no-GPS fallback): each
  /// region maps to representative coordinates, fed through the same derivation.
  Future<void> _choisirRegion() async {
    final choix = await choisirRegion(context);
    if (choix != null) _appliquerPosition(choix);
  }

  Future<void> _enregistrer() async {
    if (!_cleForm.currentState!.validate()) return;
    setState(() => _enregistrement = true);
    final notifier = ref.read(potagersProvider.notifier);
    final zone = ZoneClimatique(_climat, _rusticite);

    final Potager potager;
    final initial = widget.potagerInitial;
    if (initial != null) {
      // Edit: mutate the existing entity in place, then persist.
      initial
        ..renommer(_nom.text.trim())
        ..modifierEmplacement(_emplacement)
        ..mettreAJourZoneClimatique(zone)
        ..mettreAJourLocalisation(_position);
      await notifier.modifier(initial);
      potager = initial;
    } else {
      potager = await notifier.creer(
        nom: _nom.text.trim(),
        zoneClimatique: zone,
        emplacement: _emplacement,
        localisation: _position,
      );
    }
    if (mounted) Navigator.of(context).pop(potager);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_edition ? l10n.formPotagerTitreModifier : l10n.formPotagerTitre),
      ),
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
            OutlinedButton.icon(
              onPressed: _detection ? null : _detecterPosition,
              icon: _detection
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(l10n.formPotagerDetecter),
            ),
            TextButton.icon(
              onPressed: _detection ? null : _choisirRegion,
              icon: const Icon(Icons.public_outlined),
              label: Text(l10n.formPotagerChoisirRegion),
            ),
            if (_suggere)
              Padding(
                padding: const EdgeInsets.only(top: EspacementsApp.s2),
                child: Text(
                  l10n.formPotagerPositionDetectee,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
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
