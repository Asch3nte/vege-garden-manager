import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/dimensions_app.dart';
import '../../../application/state/acces_niveau_provider.dart';
import '../../../domain/enums/niveau_experience.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/libelles_enums.dart';
import 'widgets_parametres.dart';
import '../../glossaire/terme_glossaire.dart';
import '../../glossaire/terme_cliquable.dart';

/// One feature of the progressive-disclosure catalogue: the level that unlocks
/// it and its mini-tuto content (title → why → how).
typedef _Feature = ({
  NiveauExperience niveau,
  IconData icone,
  String Function(AppLocalizations) titre,
  String Function(AppLocalizations) pourquoi,
  String Function(AppLocalizations) comment,
});

/// The mini-tuto catalogue (ADR-0009 §4a). Only **built** gated features are
/// listed (those a user can actually use); reserved-but-unbuilt features
/// (multi-garden, equipment…) are added here as they ship. Closures resolve the
/// localized text at build time, so this is `final`, not `const`.
final List<_Feature> _features = [
  (
    niveau: NiveauExperience.intermediaire,
    icone: Icons.hub_outlined,
    titre: (l) => l.tutoVueReseauTitre,
    pourquoi: (l) => l.tutoVueReseauPourquoi,
    comment: (l) => l.tutoVueReseauComment,
  ),
  (
    niveau: NiveauExperience.intermediaire,
    icone: Icons.eco_outlined,
    titre: (l) => l.tutoVueSaisonTitre,
    pourquoi: (l) => l.tutoVueSaisonPourquoi,
    comment: (l) => l.tutoVueSaisonComment,
  ),
  (
    niveau: NiveauExperience.intermediaire,
    icone: Icons.visibility_outlined,
    titre: (l) => l.tutoObservationsTitre,
    pourquoi: (l) => l.tutoObservationsPourquoi,
    comment: (l) => l.tutoObservationsComment,
  ),
  (
    niveau: NiveauExperience.intermediaire,
    icone: Icons.grass_outlined,
    titre: (l) => l.tutoTechniquesSolTitre,
    pourquoi: (l) => l.tutoTechniquesSolPourquoi,
    comment: (l) => l.tutoTechniquesSolComment,
  ),
  (
    niveau: NiveauExperience.intermediaire,
    icone: Icons.nightlight_outlined,
    titre: (l) => l.tutoLunaireTitre,
    pourquoi: (l) => l.tutoLunairePourquoi,
    comment: (l) => l.tutoLunaireComment,
  ),
  (
    niveau: NiveauExperience.intermediaire,
    icone: Icons.notifications_outlined,
    titre: (l) => l.tutoNotifsCategTitre,
    pourquoi: (l) => l.tutoNotifsCategPourquoi,
    comment: (l) => l.tutoNotifsCategComment,
  ),
  (
    niveau: NiveauExperience.expert,
    icone: Icons.science_outlined,
    titre: (l) => l.tutoSolTexturePhTitre,
    pourquoi: (l) => l.tutoSolTexturePhPourquoi,
    comment: (l) => l.tutoSolTexturePhComment,
  ),
  (
    niveau: NiveauExperience.expert,
    icone: Icons.bar_chart_outlined,
    titre: (l) => l.tutoStatsTitre,
    pourquoi: (l) => l.tutoStatsPourquoi,
    comment: (l) => l.tutoStatsComment,
  ),
];

/// Settings category — **Guide des niveaux** (ADR-0009 §4a/§4b): a re-consultable
/// mini-tuto listing what each tier unlocks, why it exists and how to use it.
/// Features at or below the user's level are marked "unlocked"; higher ones act
/// as a level-up teaser.
class PanneauNiveaux extends ConsumerWidget {
  const PanneauNiveaux({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final niveauActuel = ref.watch(accesNiveauProvider).niveau;

    return PanneauParametres(
      titre: l10n.categNiveaux,
      // « ? » → the glossary page explaining the experience tiers (ADR-0017).
      actions: [
        AideGlossaire(
            idTerme: TermeGlossaire.idNotion('niveaux-experience'),
            infobulle: l10n.categNiveaux),
      ],
      enfants: [
        Padding(
          padding: const EdgeInsets.only(bottom: EspacementsApp.s4),
          child: Text(
            l10n.guideNiveauxIntro,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        for (final niveau in const [
          NiveauExperience.intermediaire,
          NiveauExperience.expert,
        ])
          ZoneParametres(
            titre: l10n.niveauExperience(niveau),
            enfants: [
              for (final (i, f)
                  in _features.where((f) => f.niveau == niveau).indexed) ...[
                if (i > 0) const Divider(height: 1),
                _CarteFeature(
                  feature: f,
                  // Unlocked when the user's level is at or above the feature's.
                  debloque: niveauActuel.index >= niveau.index,
                ),
              ],
            ],
          ),
      ],
    );
  }
}

/// One feature card: icon + title + a "unlocked / level X" badge, then the
/// why/how lines.
class _CarteFeature extends StatelessWidget {
  final _Feature feature;
  final bool debloque;

  const _CarteFeature({required this.feature, required this.debloque});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(EspacementsApp.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(feature.icone,
                  size: TaillesIconesApp.md, color: theme.colorScheme.primary),
              const SizedBox(width: EspacementsApp.s2),
              Expanded(
                child: Text(feature.titre(l10n),
                    style: theme.textTheme.titleMedium),
              ),
              if (debloque)
                _Badge(
                  texte: l10n.guideNiveauDebloque,
                  couleur: theme.colorScheme.primary,
                  fond: theme.colorScheme.primaryContainer,
                ),
            ],
          ),
          const SizedBox(height: EspacementsApp.s2),
          _LigneInfo(
              label: l10n.guidePourquoi, texte: feature.pourquoi(l10n)),
          const SizedBox(height: EspacementsApp.s1),
          _LigneInfo(label: l10n.guideComment, texte: feature.comment(l10n)),
        ],
      ),
    );
  }
}

class _LigneInfo extends StatelessWidget {
  final String label;
  final String texte;

  const _LigneInfo({required this.label, required this.texte});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        children: [
          TextSpan(
            text: '$label : ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: texte),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String texte;
  final Color couleur;
  final Color fond;

  const _Badge({required this.texte, required this.couleur, required this.fond});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: EspacementsApp.s2, vertical: 2),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: const BorderRadius.all(RayonsApp.full),
      ),
      child: Text(
        texte,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: couleur, fontWeight: FontWeight.w600),
      ),
    );
  }
}
