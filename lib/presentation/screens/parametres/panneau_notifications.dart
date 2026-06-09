import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/state/preferences_notifier.dart';
import '../../../domain/entities/preferences_utilisateur.dart';
import '../../../l10n/app_localizations.dart';
import 'widgets_parametres.dart';

/// A notification category: its stable storage key, icon and label resolver.
typedef _CategorieNotif = ({String cle, IconData icone, String Function(AppLocalizations) label});

/// Category 3 — **Notifications**: a master switch gating per-category toggles.
///
/// Per-category state lives in `PreferencesUtilisateur.notificationsParCategorie`
/// (a `String → bool` map); each category defaults to on when absent. When the
/// master switch is off, the categories are shown disabled (the master always
/// wins).
class PanneauNotifications extends ConsumerWidget {
  const PanneauNotifications({super.key});

  static const List<_CategorieNotif> _categories = [
    (cle: 'semis', icone: Icons.grain, label: _labelSemis),
    (cle: 'arrosage', icone: Icons.water_drop_outlined, label: _labelArrosage),
    (cle: 'recolte', icone: Icons.shopping_basket_outlined, label: _labelRecolte),
    (cle: 'meteo', icone: Icons.thunderstorm_outlined, label: _labelMeteo),
    (cle: 'entretien', icone: Icons.content_cut, label: _labelEntretien),
    (cle: 'rotation', icone: Icons.autorenew, label: _labelRotation),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(preferencesProvider).value;
    final notifier = ref.read(preferencesProvider.notifier);

    if (prefs == null) {
      return PanneauParametres(titre: l10n.categNotifications, enfants: const []);
    }

    final master = prefs.notificationsGlobalesActives;

    return PanneauParametres(
      titre: l10n.categNotifications,
      enfants: [
        ZoneParametres(
          enfants: [
            RangeeInterrupteur(
              icone: Icons.notifications_active_outlined,
              label: l10n.notifMaster,
              sousTitre: master ? l10n.notifMasterOn : l10n.notifMasterOff,
              valeur: master,
              onChanged: notifier.definirNotificationsGlobales,
            ),
          ],
        ),
        ZoneParametres(
          titre: l10n.notifParCategorie,
          enfants: [
            for (final cat in _categories)
              RangeeInterrupteur(
                icone: cat.icone,
                label: cat.label(l10n),
                valeur: master && _estActive(prefs, cat.cle),
                // Disabled while the master switch is off.
                onChanged: master
                    ? (v) => notifier.definirNotificationCategorie(cat.cle, v)
                    : null,
              ),
          ],
        ),
      ],
    );
  }

  /// A category is active unless explicitly turned off (default-on).
  static bool _estActive(PreferencesUtilisateur prefs, String cle) =>
      prefs.notificationsParCategorie[cle] ?? true;
}

String _labelSemis(AppLocalizations l) => l.notifSemis;
String _labelArrosage(AppLocalizations l) => l.notifArrosage;
String _labelRecolte(AppLocalizations l) => l.notifRecolte;
String _labelMeteo(AppLocalizations l) => l.notifMeteo;
String _labelEntretien(AppLocalizations l) => l.notifEntretien;
String _labelRotation(AppLocalizations l) => l.notifRotation;
