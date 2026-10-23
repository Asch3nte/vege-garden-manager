import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/router.dart';
import '../../../application/state/preferences_notifier.dart';
import '../../../domain/enums/grandeur_mesure.dart';
import '../../../domain/enums/langue.dart';
import '../../../domain/enums/niveau_experience.dart';
import '../../../domain/enums/sens_swipe.dart';
import '../../../domain/enums/systeme_unites.dart';
import '../../../domain/enums/theme_app.dart' as prefs_theme;
import '../../../domain/exceptions/preferences_illisibles_exception.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/libelles_enums.dart';
import 'enregistreur_preferences.dart';
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
    final enregistreur = EnregistreurPreferences.de(context);

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
                onChanged: enregistreur.pour(notifier.definirLangue),
              ),
            ),
            ChampEmpile(
              label: l10n.prefTheme,
              enfant: ChampSegmente<prefs_theme.ThemeApp>(
                valeur: prefs.theme,
                options: [
                  for (final v in prefs_theme.ThemeApp.values) (v, l10n.theme(v)),
                ],
                onChanged: enregistreur.pour(notifier.definirTheme),
              ),
            ),
            ChampEmpile(
              label: l10n.prefUnites,
              indication: prefs.unites.prereglage == null
                  ? l10n.unitesPersonnalise
                  : null,
              enfant: ChampSegmente<SystemeUnites>(
                valeur: prefs.unites.prereglage,
                options: [
                  for (final v in SystemeUnites.values) (v, l10n.unites(v)),
                ],
                onChanged: enregistreur.pour(notifier.definirPrereglageUnites),
              ),
            ),
            // Own Material: the zone's coloured box would hide the ink.
            Material(
              type: MaterialType.transparency,
              child: ExpansionTile(
                title: Text(l10n.unitesDetail),
                initiallyExpanded: prefs.unites.prereglage == null,
                children: [
                  for (final g in GrandeurMesure.values)
                    ChampEmpile(
                      label: l10n.grandeurMesure(g),
                      enfant: ChampSegmente<SystemeUnites>(
                        valeur: prefs.unites.pour(g),
                        options: [
                          for (final v in SystemeUnites.values)
                            (v, l10n.symbolesUnites(g, v)),
                        ],
                        onChanged: enregistreur
                            .pour((v) => notifier.definirUnite(g, v)),
                      ),
                    ),
                ],
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
                onChanged: enregistreur.pour(notifier.definirSensSwipe),
              ),
            ),
          ],
        ),
        ZoneParametres(
          enfants: [
            RangeeInterrupteur(
              icone: PhosphorIconsRegular.trash,
              label: l10n.prefConfirmerSuppressions,
              sousTitre: l10n.prefConfirmerSuppressionsSub,
              valeur: prefs.confirmerSuppressions,
              onChanged:
                  enregistreur.pour(notifier.definirConfirmerSuppressions),
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
                // Reaching a level nudges the user to the guide.
                onChanged: (n) async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await notifier.definirNiveau(n);
                  } on PreferencesIllisiblesException {
                    messenger.showSnackBar(SnackBar(
                        content: Text(l10n.preferencesIllisiblesRefus)));
                    return;
                  } on Exception catch (e) {
                    debugPrint('Level change failed: $e');
                    messenger.showSnackBar(SnackBar(
                        content: Text(l10n.formEnregistrementErreur)));
                    return;
                  }
                  if (!context.mounted) return;
                  messenger.showSnackBar(SnackBar(
                    content: Text(l10n.generalNiveauChangeSnack),
                    action: SnackBarAction(
                      label: l10n.generalNiveauChangeAction,
                      onPressed: () => context.go(RoutesApp.plusNiveaux),
                    ),
                  ));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
