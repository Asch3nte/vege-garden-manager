import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/dimensions_app.dart';
import '../../../application/providers/service_providers.dart';
import '../../../application/state/preferences_notifier.dart';
import '../../../domain/enums/mode_geolocalisation.dart';
import '../../../domain/value_objects/localisation.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/capture_localisation.dart';
import '../../widgets/libelles_enums.dart';
import '../../widgets/position_potager_actions.dart';
import 'widgets_parametres.dart';

/// Category 2 — **Confidentialité & opt-outs**: geolocation mode, local sync,
/// lunar calendar, P2P community (V2). Embodies the "golden rule": disabling
/// anything keeps the app working (a fallback always exists).
class PanneauConfidentialite extends ConsumerWidget {
  const PanneauConfidentialite({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(preferencesProvider).value;
    final notifier = ref.read(preferencesProvider.notifier);

    if (prefs == null) {
      return PanneauParametres(titre: l10n.categConfidentialite, enfants: const []);
    }

    final mode = prefs.modeGeolocalisation;
    // The active garden's current position (to show its status + offer editing).
    final localisation = ref.watch(potagerActifProvider).value?.localisation;

    // Geolocation cycles off → manual → GPS → off (matches the mock-up).
    // Changing the mode resets the stored position so the user re-picks one.
    Future<void> cyclerGeoloc() async {
      const ordre = ModeGeolocalisation.values;
      final suivant = ordre[(mode.index + 1) % ordre.length];
      await notifier.definirGeolocalisation(suivant);
      await reinitialiserPositionPotager(ref);
    }

    // Sets the garden position with the mode-appropriate capture. The capture
    // call uses `context` synchronously (before any await), then we await it.
    Future<void> definirPosition() async {
      final Future<Localisation?> capture = switch (mode) {
        ModeGeolocalisation.gps =>
          capterGps(context, ref.read(geolocalisationServiceProvider)),
        ModeGeolocalisation.manuelle => choisirRegion(context),
        ModeGeolocalisation.desactivee => Future.value(null),
      };
      final loc = await capture;
      if (loc != null) await enregistrerPositionPotager(ref, loc);
    }

    return PanneauParametres(
      titre: l10n.categConfidentialite,
      enfants: [
        ZoneParametres(
          note: l10n.confidRegleOr,
          enfants: [
            // Geolocation tappable row (cycles the mode).
            InkWell(
              onTap: cyclerGeoloc,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EspacementsApp.s3,
                  vertical: EspacementsApp.s2,
                ),
                child: Row(
                  children: [
                    Icon(Icons.place_outlined, size: TaillesIconesApp.md, color: theme.colorScheme.primary),
                    const SizedBox(width: EspacementsApp.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.confidGeoloc, style: theme.textTheme.bodyMedium),
                          Text(
                            l10n.geolocDescription(prefs.modeGeolocalisation),
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      l10n.geolocLabel(prefs.modeGeolocalisation),
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: EspacementsApp.s1),
                    Icon(Icons.chevron_right, size: TaillesIconesApp.md, color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            // Position row: shown when geolocation is enabled; the action
            // depends on the mode (GPS detect vs region pick).
            if (mode != ModeGeolocalisation.desactivee)
              InkWell(
                onTap: definirPosition,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EspacementsApp.s3,
                    vertical: EspacementsApp.s2,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        mode == ModeGeolocalisation.gps
                            ? Icons.my_location
                            : Icons.public_outlined,
                        size: TaillesIconesApp.md,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: EspacementsApp.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.confidPosition,
                                style: theme.textTheme.bodyMedium),
                            Text(
                              _statutPosition(l10n, localisation),
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          size: TaillesIconesApp.md,
                          color: theme.colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            RangeeInterrupteur(
              icone: Icons.wifi,
              label: l10n.confidSync,
              sousTitre: l10n.confidSyncSub,
              valeur: prefs.syncLocaleActive,
              onChanged: notifier.definirSyncLocale,
            ),
            RangeeInterrupteur(
              icone: Icons.nightlight_outlined,
              label: l10n.confidLunaire,
              sousTitre: l10n.confidLunaireSub,
              valeur: prefs.calendrierLunaireOptIn,
              onChanged: notifier.definirCalendrierLunaire,
            ),
            // Community is V2: shown but disabled (off, non-interactive).
            RangeeInterrupteur(
              icone: Icons.groups_outlined,
              label: l10n.confidCommunaute,
              sousTitre: l10n.confidCommunauteSub,
              valeur: false,
              onChanged: null,
            ),
          ],
        ),
      ],
    );
  }
}

/// Subtitle for the position row: the region/city when set, else a prompt.
String _statutPosition(AppLocalizations l10n, Localisation? localisation) {
  if (localisation == null || !localisation.estDefinie) {
    return l10n.confidPositionAucune;
  }
  return localisation.ville ?? l10n.confidPositionDefinie;
}
