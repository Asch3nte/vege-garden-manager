import 'package:flutter/material.dart';

import '../../app/theme/dimensions_app.dart';
import '../../domain/enums/permission_localisation.dart';
import '../../domain/repositories/abstract_geolocalisation_service.dart';
import '../../domain/value_objects/localisation.dart';
import '../../l10n/app_localizations.dart';

/// Approximate world regions for the no-GPS picker: each maps to representative
/// coordinates (rough; the user confirms the derived climate). Shared so the
/// list lives in one place.
List<(String, double, double)> regionsLocalisation(AppLocalizations l10n) => [
      (l10n.regionEuropeOuest, 48, 2),
      (l10n.regionMediterranee, 38, 12),
      (l10n.regionEuropeNord, 60, 18),
      (l10n.regionTropiques, 5, 25),
      (l10n.regionAmeriqueNord, 42, -90),
      (l10n.regionHemisphereSud, -33, 18),
    ];

/// Captures the device position (opt-in): requests permission, reads the GPS
/// position, and surfaces a snackbar on refusal/failure. Returns `null` when it
/// could not be obtained.
Future<Localisation?> capterGps(
  BuildContext context,
  AbstractGeolocalisationService service,
) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final permission = await service.demanderPermission();
    if (permission != PermissionLocalisation.accordee) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.formPotagerPositionRefusee)),
      );
      return null;
    }
    return await service.positionActuelle();
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.formPotagerPositionErreur)),
    );
    return null;
  }
}

/// Lets the user pick an approximate world region (no GPS). Returns the
/// corresponding [Localisation], or `null` if dismissed.
Future<Localisation?> choisirRegion(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<Localisation>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(l10n.formPotagerChoisirRegion),
      children: [
        for (final (label, lat, lon) in regionsLocalisation(l10n))
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(
              Localisation.manuelle(ville: label, latitude: lat, longitude: lon),
            ),
            child: Text(label),
          ),
      ],
    ),
  );
}

/// Opens a bottom sheet to set a position — by GPS (opt-in) or by picking an
/// approximate region — and returns the chosen [Localisation] (or `null` if
/// dismissed). Used where no mode is imposed (e.g. the home weather prompt).
Future<Localisation?> ouvrirCaptureLocalisation(
  BuildContext context,
  AbstractGeolocalisationService service,
) {
  return showModalBottomSheet<Localisation>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _FeuilleCapture(service: service),
  );
}

class _FeuilleCapture extends StatefulWidget {
  final AbstractGeolocalisationService service;

  const _FeuilleCapture({required this.service});

  @override
  State<_FeuilleCapture> createState() => _FeuilleCaptureState();
}

class _FeuilleCaptureState extends State<_FeuilleCapture> {
  bool _detection = false;

  Future<void> _detecterGps() async {
    final navigator = Navigator.of(context);
    setState(() => _detection = true);
    final loc = await capterGps(context, widget.service);
    if (!mounted) return;
    setState(() => _detection = false);
    if (loc != null) navigator.pop(loc);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: EspacementsApp.s4),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              EspacementsApp.s5,
              0,
              EspacementsApp.s5,
              EspacementsApp.s3,
            ),
            child: Text(l10n.captureLocalisationTitre,
                style: theme.textTheme.titleLarge),
          ),
          ListTile(
            leading: _detection
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            title: Text(l10n.formPotagerDetecter),
            onTap: _detection ? null : _detecterGps,
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              EspacementsApp.s5,
              EspacementsApp.s2,
              EspacementsApp.s5,
              EspacementsApp.s1,
            ),
            child: Text(
              l10n.captureLocalisationOuRegion,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          for (final (label, lat, lon) in regionsLocalisation(l10n))
            ListTile(
              leading: const Icon(Icons.public_outlined),
              title: Text(label),
              onTap: () => Navigator.of(context).pop(
                Localisation.manuelle(
                  ville: label,
                  latitude: lat,
                  longitude: lon,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
