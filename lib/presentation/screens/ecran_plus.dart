import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/dimensions_app.dart';
import '../../application/state/preferences_notifier.dart';
import '../../domain/entities/preferences_utilisateur.dart';
import '../../domain/services/acces_niveau.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/libelles_enums.dart';
import 'parametres/widgets_parametres.dart';

/// Tab 5 — **Plus** (`⋯`): settings root + secondary entries (docs/09 §7).
///
/// Reimplemented from `parametres.jsx`. The settings categories that map to real
/// `PreferencesUtilisateur` fields (general, privacy/opt-outs, notifications)
/// and the About page are built and persisted; Post-récolte and Communauté are
/// marked as upcoming/V2, and Transparency/Sync/Export are deferred (docs/15).
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

/// Settings root: profile header, category list, local-storage footer.
class _Racine extends StatelessWidget {
  final PreferencesUtilisateur prefs;

  const _Racine({required this.prefs});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Sub-panels are go_router sub-routes of /plus, so re-tapping the Plus tab
    // pops back to this root (docs/15 §6 — was an imperative push before).
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        EspacementsApp.s4,
        EspacementsApp.s4,
        EspacementsApp.s4,
        EspacementsApp.s6,
      ),
      children: [
        _EnteteProfil(prefs: prefs),
        const SizedBox(height: EspacementsApp.s5),
        LigneCategorie(
          icone: Icons.tune,
          titre: l10n.categGenerale,
          sousTitre: l10n.categGeneraleSub,
          onTap: () => context.go(RoutesApp.plusGeneral),
        ),
        LigneCategorie(
          icone: Icons.privacy_tip_outlined,
          titre: l10n.categConfidentialite,
          sousTitre: l10n.categConfidentialiteSub,
          onTap: () => context.go(RoutesApp.plusConfidentialite),
        ),
        LigneCategorie(
          icone: Icons.notifications_outlined,
          titre: l10n.categNotifications,
          sousTitre: l10n.categNotificationsSub,
          onTap: () => context.go(RoutesApp.plusNotifications),
        ),
        LigneCategorie(
          icone: Icons.school_outlined,
          titre: l10n.categNiveaux,
          sousTitre: l10n.categNiveauxSub,
          onTap: () => context.go(RoutesApp.plusNiveaux),
        ),
        // Association weighting — expert only (ADR-0011/0009).
        if (AccesNiveau(prefs.niveauExperience).ponderationAssociations)
          LigneCategorie(
            icone: Icons.tune_outlined,
            titre: l10n.categPonderation,
            sousTitre: l10n.categPonderationSub,
            onTap: () => context.go(RoutesApp.plusPonderation),
          ),
        LigneCategorie(
          icone: Icons.save_outlined,
          titre: l10n.categDonnees,
          sousTitre: l10n.categDonneesSub,
          onTap: () => context.go(RoutesApp.plusDonnees),
        ),
        LigneCategorie(
          icone: Icons.info_outline,
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
            child: Icon(Icons.eco, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: EspacementsApp.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mon carnet', style: theme.textTheme.titleLarge),
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
        Icon(Icons.lock_outline, size: TaillesIconesApp.sm, color: theme.colorScheme.onSurfaceVariant),
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
