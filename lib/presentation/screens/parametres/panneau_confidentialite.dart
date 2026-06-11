import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/dimensions_app.dart';
import '../../../application/providers/service_providers.dart';
import '../../../application/state/preferences_notifier.dart';
import '../../../domain/enums/mode_geolocalisation.dart';
import '../../../domain/enums/type_climat.dart';
import '../../../domain/enums/zone_rusticite.dart';
import '../../../domain/value_objects/localisation.dart';
import '../../../domain/value_objects/zone_climatique.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/capture_localisation.dart';
import '../../widgets/libelles_enums.dart';
import '../../widgets/position_potager_actions.dart';
import '../../widgets/selecteur_decrit.dart';
import 'widgets_parametres.dart';

/// Category 2 — **Confidentialité & opt-outs**: geolocation mode, the active
/// garden's position + climate + hardiness, local sync, lunar calendar, P2P
/// community (V2). Embodies the "golden rule": disabling anything keeps the app
/// working (a fallback always exists).
///
/// Climate & hardiness live on the garden (`ZoneClimatique`); this panel surfaces
/// them for the **active** garden so the user can always read and adjust them —
/// even with geolocation off (then they are set by hand, not derived).
class PanneauConfidentialite extends ConsumerWidget {
  const PanneauConfidentialite({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final prefs = ref.watch(preferencesProvider).value;
    final notifier = ref.read(preferencesProvider.notifier);

    if (prefs == null) {
      return PanneauParametres(titre: l10n.categConfidentialite, enfants: const []);
    }

    final mode = prefs.modeGeolocalisation;
    // The active garden carries the position + climate/hardiness shown & edited.
    final potager = ref.watch(potagerActifProvider).value;

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

    // Climate / hardiness pickers: reuse the lot-B descriptions, then persist
    // the new ZoneClimatique on the active garden (context used synchronously).
    Future<void> changerClimat() async {
      if (potager == null) return;
      final z = potager.zoneClimatique;
      final choix = await choisirOptionDecrite<TypeClimat>(
        context,
        titre: l10n.confidClimat,
        valeur: z.type,
        options: TypeClimat.values,
        libelle: l10n.climat,
        description: l10n.climatDescription,
      );
      if (choix != null) {
        await enregistrerZoneClimatiquePotager(
            ref, ZoneClimatique(choix, z.rusticite));
      }
    }

    Future<void> changerRusticite() async {
      if (potager == null) return;
      final z = potager.zoneClimatique;
      final choix = await choisirOptionDecrite<ZoneRusticite>(
        context,
        titre: l10n.confidRusticite,
        valeur: z.rusticite,
        options: ZoneRusticite.values,
        libelle: l10n.rusticite,
        description: l10n.rusticiteDescription,
      );
      if (choix != null) {
        await enregistrerZoneClimatiquePotager(
            ref, ZoneClimatique(z.type, choix));
      }
    }

    // Per-garden block (tabulated under the geolocation row). Always present so
    // climate/hardiness stay reachable even with geoloc off; a prompt replaces
    // it when there is no active garden to store them on.
    final List<Widget> groupePotager;
    if (potager == null) {
      groupePotager = [
        _LigneReglage(
          icone: Icons.eco_outlined,
          titre: l10n.confidClimatSansPotager,
          indent: true,
        ),
      ];
    } else {
      final z = potager.zoneClimatique;
      final positionActive = mode != ModeGeolocalisation.desactivee;
      groupePotager = [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(EspacementsApp.s6,
                EspacementsApp.s2, EspacementsApp.s3, EspacementsApp.s1),
            child: Text(
              potager.nom,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ),
        _LigneReglage(
          icone: Icons.public_outlined,
          titre: l10n.confidPosition,
          sousTitre: positionActive
              ? _statutPosition(l10n, potager.localisation)
              : l10n.confidPositionDesactivee,
          onTap: positionActive ? definirPosition : null,
          indent: true,
        ),
        _LigneReglage(
          icone: Icons.thermostat_outlined,
          titre: l10n.confidClimat,
          valeur: l10n.climat(z.type),
          onTap: changerClimat,
          indent: true,
        ),
        _LigneReglage(
          icone: Icons.ac_unit_outlined,
          titre: l10n.confidRusticite,
          valeur: l10n.rusticite(z.rusticite),
          onTap: changerRusticite,
          indent: true,
        ),
      ];
    }

    return PanneauParametres(
      titre: l10n.categConfidentialite,
      enfants: [
        ZoneParametres(
          note: l10n.confidRegleOr,
          enfants: [
            // Geolocation row (cycles the mode).
            _LigneReglage(
              icone: Icons.place_outlined,
              titre: l10n.confidGeoloc,
              sousTitre: l10n.geolocDescription(mode),
              valeur: l10n.geolocLabel(mode),
              onTap: cyclerGeoloc,
            ),
            ...groupePotager,
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

/// A tappable settings row: icon + title (+ optional subtitle) + optional
/// right-aligned value + chevron. Non-interactive (greyed, no chevron) when
/// [onTap] is null. [indent] tabulates it under a parent row.
class _LigneReglage extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String? sousTitre;
  final String? valeur;
  final VoidCallback? onTap;
  final bool indent;

  const _LigneReglage({
    required this.icone,
    required this.titre,
    this.sousTitre,
    this.valeur,
    this.onTap,
    this.indent = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final interactif = onTap != null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          indent ? EspacementsApp.s6 : EspacementsApp.s3,
          EspacementsApp.s2,
          EspacementsApp.s3,
          EspacementsApp.s2,
        ),
        child: Row(
          children: [
            Icon(
              icone,
              size: TaillesIconesApp.md,
              color: interactif
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
            const SizedBox(width: EspacementsApp.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: interactif
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (sousTitre != null)
                    Text(
                      sousTitre!,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            if (valeur != null)
              Text(
                valeur!,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            if (interactif) ...[
              const SizedBox(width: EspacementsApp.s1),
              Icon(Icons.chevron_right,
                  size: TaillesIconesApp.md,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ],
        ),
      ),
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
