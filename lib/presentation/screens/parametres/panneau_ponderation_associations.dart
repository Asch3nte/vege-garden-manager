import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/state/preferences_notifier.dart';
import '../../../domain/enums/famille_effet_association.dart';
import '../../../domain/enums/famille_effet_conflit.dart';
import '../../../domain/enums/poids_association.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/libelles_enums.dart';
import 'widgets_parametres.dart';

/// Expert-only panel (ADR-0011) to weight each association **effect family**.
/// Every change persists immediately and reshapes the ranking/pruning of derived
/// suggestions in the Associations view and the reco bonus.
class PanneauPonderationAssociations extends ConsumerWidget {
  const PanneauPonderationAssociations({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(preferencesProvider).value;
    final notifier = ref.read(preferencesProvider.notifier);

    if (prefs == null) {
      return PanneauParametres(titre: l10n.categPonderation, enfants: const []);
    }

    final profil = prefs.ponderationAssociations;

    return PanneauParametres(
      titre: l10n.categPonderation,
      enfants: [
        ZoneParametres(
          note: l10n.ponderationNote,
          enfants: [
            for (final famille in FamilleEffetAssociation.values)
              ChampEmpile(
                label: l10n.familleEffet(famille),
                enfant: ChampSegmente<PoidsAssociation>(
                  valeur: profil.poids(famille),
                  options: [
                    for (final p in PoidsAssociation.values) (p, l10n.poids(p)),
                  ],
                  onChanged: (p) =>
                      notifier.definirPoidsAssociation(famille, p),
                ),
              ),
          ],
        ),
        // Conflict families are weightable too (ADR-0014): prioritise or ignore a
        // class of warnings.
        ZoneParametres(
          note: l10n.ponderationConflitsTitre,
          enfants: [
            for (final famille in FamilleEffetConflit.values)
              ChampEmpile(
                label: l10n.familleEffetConflit(famille),
                enfant: ChampSegmente<PoidsAssociation>(
                  valeur: profil.poidsConflit(famille),
                  options: [
                    for (final p in PoidsAssociation.values) (p, l10n.poids(p)),
                  ],
                  onChanged: (p) => notifier.definirPoidsConflit(famille, p),
                ),
              ),
          ],
        ),
        ZoneParametres(
          enfants: [
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: profil.estDefaut
                    ? null
                    : notifier.reinitialiserPonderationAssociations,
                icon: const Icon(Icons.restart_alt),
                label: Text(l10n.ponderationReinitialiser),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
