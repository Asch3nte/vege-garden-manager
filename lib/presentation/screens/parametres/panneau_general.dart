import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/state/preferences_notifier.dart';
import '../../../domain/enums/langue.dart';
import '../../../domain/enums/niveau_experience.dart';
import '../../../domain/enums/sens_swipe.dart';
import '../../../domain/enums/systeme_unites.dart';
import '../../../domain/enums/theme_app.dart' as prefs_theme;
import '../../../l10n/app_localizations.dart';
import '../../widgets/libelles_enums.dart';
import 'widgets_parametres.dart';

/// Category 1 — **Préférences générales**: language, theme, units, swipe
/// direction, experience level. Every change is persisted immediately.
class PanneauGeneral extends ConsumerWidget {
  const PanneauGeneral({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(preferencesProvider).value;
    final notifier = ref.read(preferencesProvider.notifier);

    if (prefs == null) {
      return PanneauParametres(titre: l10n.categGenerale, enfants: const []);
    }

    return PanneauParametres(
      titre: l10n.categGenerale,
      enfants: [
        ZoneParametres(
          enfants: [
            ChampEmpile(
              label: l10n.prefLangue,
              enfant: ChampSegmente<Langue>(
                valeur: prefs.langue,
                options: [for (final v in Langue.values) (v, l10n.langue(v))],
                onChanged: notifier.definirLangue,
              ),
            ),
            ChampEmpile(
              label: l10n.prefTheme,
              enfant: ChampSegmente<prefs_theme.ThemeApp>(
                valeur: prefs.theme,
                options: [
                  for (final v in prefs_theme.ThemeApp.values) (v, l10n.theme(v)),
                ],
                onChanged: notifier.definirTheme,
              ),
            ),
            ChampEmpile(
              label: l10n.prefUnites,
              enfant: ChampSegmente<SystemeUnites>(
                valeur: prefs.systemeUnites,
                options: [
                  for (final v in SystemeUnites.values) (v, l10n.unites(v)),
                ],
                onChanged: notifier.definirUnites,
              ),
            ),
          ],
        ),
        ZoneParametres(
          titre: l10n.prefSensSwipe,
          note: l10n.prefSensSwipeSub,
          enfants: [
            ChampEmpile(
              label: l10n.prefSensSwipe,
              enfant: ChampSegmente<SensSwipe>(
                valeur: prefs.sensSwipe,
                options: [
                  for (final v in SensSwipe.values) (v, l10n.sensSwipe(v)),
                ],
                onChanged: notifier.definirSensSwipe,
              ),
            ),
          ],
        ),
        ZoneParametres(
          titre: l10n.prefNiveau,
          note: l10n.prefNiveauSub,
          enfants: [
            ChampEmpile(
              label: l10n.prefNiveau,
              enfant: ChampSegmente<NiveauExperience>(
                valeur: prefs.niveauExperience,
                options: [
                  for (final v in NiveauExperience.values)
                    (v, l10n.niveauExperience(v)),
                ],
                onChanged: notifier.definirNiveau,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
