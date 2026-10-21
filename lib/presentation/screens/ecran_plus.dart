import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../app/router.dart';
import '../../app/theme/dimensions_app.dart';
import '../../application/state/preferences_notifier.dart';
import '../../domain/entities/preferences_utilisateur.dart';
import '../../domain/services/acces_niveau.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/libelles_enums.dart';
import 'parametres/widgets_parametres.dart';

/// Tab 5 — **Plus** (`⋯`): settings root + secondary entries.
///
/// The settings categories that map to real `PreferencesUtilisateur` fields
/// (general, privacy/opt-outs, notifications) and the About page are built and
/// persisted. Post-récolte and Communauté are not offered yet (the
/// `plusPostRecolte(Sub)` ARB keys are reserved).
class EcranPlus extends ConsumerWidget {
  const EcranPlus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(preferencesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.parametresTitre)),
      body: prefs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.accueilErreurChargement)),
        data: (data) => _Racine(prefs: data),
      ),
    );
  }
}

/// Warning shown while the stored preferences cannot be read.
class _BandeauPreferencesIllisibles extends ConsumerWidget {
  const _BandeauPreferencesIllisibles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(preferencesIllisiblesProvider).value != true) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: EspacementsApp.s4),
      child: Card.outlined(
        child: ListTile(
          leading: Icon(PhosphorIconsRegular.warning,
              color: theme.colorScheme.error),
          title: Text(AppLocalizations.of(context)!.preferencesIllisibles),
        ),
      ),
    );
  }
}

/// Settings root: profile header, category list, local-storage footer.
class _Racine extends StatelessWidget {
  final PreferencesUtilisateur prefs;

  const _Racine({required this.prefs});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Sub-panels are go_router sub-routes of /plus, so re-tapping the Plus tab
    // pops back to this root (was an imperative push before).
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        EspacementsApp.s4,
        EspacementsApp.s4,
        EspacementsApp.s4,
        EspacementsApp.s6,
      ),
      children: [
        const _BandeauPreferencesIllisibles(),
        _EnteteProfil(prefs: prefs),
        const SizedBox(height: EspacementsApp.s5),
        LigneCategorie(
          icone: PhosphorIconsRegular.slidersHorizontal,
          titre: l10n.categGenerale,
          sousTitre: l10n.categGeneraleSub,
          onTap: () => context.go(RoutesApp.plusGeneral),
        ),
        LigneCategorie(
          icone: PhosphorIconsRegular.shieldCheck,
          titre: l10n.categConfidentialite,
          sousTitre: l10n.categConfidentialiteSub,
          onTap: () => context.go(RoutesApp.plusConfidentialite),
        ),
        LigneCategorie(
          icone: PhosphorIconsRegular.bell,
          titre: l10n.categNotifications,
          sousTitre: l10n.categNotificationsSub,
          onTap: () => context.go(RoutesApp.plusNotifications),
        ),
        LigneCategorie(
          icone: PhosphorIconsRegular.graduationCap,
          titre: l10n.categNiveaux,
          sousTitre: l10n.categNiveauxSub,
          onTap: () => context.go(RoutesApp.plusNiveaux),
        ),
        // « Aide & lexique » — the gardener's reference.
        LigneCategorie(
          icone: PhosphorIconsRegular.bookOpenText,
          titre: l10n.categAide,
          sousTitre: l10n.categAideSub,
          onTap: () => context.go(RoutesApp.plusAide),
        ),
        // Association weighting — expert only.
        if (AccesNiveau(prefs.niveauExperience).ponderationAssociations)
          LigneCategorie(
            icone: PhosphorIconsRegular.slidersHorizontal,
            titre: l10n.categPonderation,
            sousTitre: l10n.categPonderationSub,
            onTap: () => context.go(RoutesApp.plusPonderation),
          ),
        LigneCategorie(
          icone: PhosphorIconsRegular.floppyDisk,
          titre: l10n.categDonnees,
          sousTitre: l10n.categDonneesSub,
          onTap: () => context.go(RoutesApp.plusDonnees),
        ),
        LigneCategorie(
          icone: PhosphorIconsRegular.info,
          titre: l10n.categApropos,
          sousTitre: l10n.categAproposSub,
          onTap: () => context.go(RoutesApp.plusAPropos),
        ),
        const SizedBox(height: EspacementsApp.s5),
        _PiedLocal(),
      ],
    );
  }
}

/// Profile header: "Mon carnet" + level + 100 % local mention.
class _EnteteProfil extends StatelessWidget {
  final PreferencesUtilisateur prefs;

  const _EnteteProfil({required this.prefs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(EspacementsApp.s4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.all(RayonsApp.lg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.3),
            child: Icon(PhosphorIconsBold.leaf, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: EspacementsApp.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.parametresMonCarnet, style: theme.textTheme.titleLarge),
                Text(
                  '${l10n.parametresNiveauMention(l10n.niveauExperience(prefs.niveauExperience))}'
                  ' · ${l10n.parametresLocal}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Footer reminding everything is stored locally.
class _PiedLocal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(PhosphorIconsRegular.lock, size: TaillesIconesApp.sm, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: EspacementsApp.s2),
        Expanded(
          child: Text(
            l10n.parametresPiedLocal,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
