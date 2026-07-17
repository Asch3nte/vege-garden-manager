import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/state/acces_niveau_provider.dart';
import '../../../application/state/preferences_notifier.dart';
import '../../../domain/entities/preferences_utilisateur.dart';
import '../../../l10n/app_localizations.dart';
import 'widgets_parametres.dart';

/// A notification category: its stable storage key, icon and label resolver.
typedef CategorieNotif = ({
  String cle,
  IconData icone,
  String Function(AppLocalizations) label,
});

/// The notification categories (shared by the settings panel and the onboarding
/// notifications step). Each defaults to **on** when absent from the stored map.
const List<CategorieNotif> categoriesNotifications = [
  (cle: 'semis', icone: Icons.grain, label: _labelSemis),
  (cle: 'arrosage', icone: Icons.water_drop_outlined, label: _labelArrosage),
  (cle: 'recolte', icone: Icons.shopping_basket_outlined, label: _labelRecolte),
  (cle: 'meteo', icone: Icons.thunderstorm_outlined, label: _labelMeteo),
  (cle: 'entretien', icone: Icons.content_cut, label: _labelEntretien),
  (cle: 'rotation', icone: Icons.autorenew, label: _labelRotation),
];

/// Category 3 — **Notifications**: a master switch gating per-category toggles.
///
/// Per-category state lives in `PreferencesUtilisateur.notificationsParCategorie`
/// (a `String → bool` map); each category defaults to on when absent. When the
/// master switch is off, the categories are shown disabled (the master always
/// wins).
class PanneauNotifications extends ConsumerWidget {
  const PanneauNotifications({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(preferencesProvider).value;
    final notifier = ref.read(preferencesProvider.notifier);

    if (prefs == null) {
      return PanneauParametres(titre: l10n.categNotifications, enfants: const []);
    }

    final master = prefs.notificationsGlobalesActives;
    // Per-category toggles are an intermediate+ feature (ADR-0009): beginners
    // keep just the master switch. Hidden categories stay at their default (on),
    // so essential/safety notifications (e.g. critical weather) still fire.
    final parCategorie = ref.watch(accesNiveauProvider).notificationsParCategorie;

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
        if (parCategorie)
          ZoneParametres(
            titre: l10n.notifParCategorie,
            enfants: [
              for (final cat in categoriesNotifications)
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
        // Do-not-disturb quiet hours (intermediate+, same granularity gate).
        if (parCategorie)
          ZoneParametres(
            titre: l10n.notifDndTitre,
            enfants: [
              RangeeInterrupteur(
                icone: Icons.bedtime_outlined,
                label: l10n.notifDnd,
                sousTitre: l10n.notifDndSousTitre,
                valeur: prefs.nePasDerangerActif,
                onChanged: (v) => v
                    ? notifier.definirNePasDeranger(
                        _dndDebutDefaut, _dndFinDefaut)
                    : notifier.desactiverNePasDeranger(),
              ),
              if (prefs.nePasDerangerActif) ...[
                const Divider(height: 1),
                _LigneHeure(
                  label: l10n.notifDndDebut,
                  heure: prefs.nePasDerangerDebut ?? _dndDebutDefaut,
                  onChoisir: (h) => notifier.definirNePasDeranger(
                      h, prefs.nePasDerangerFin ?? _dndFinDefaut),
                ),
                _LigneHeure(
                  label: l10n.notifDndFin,
                  heure: prefs.nePasDerangerFin ?? _dndFinDefaut,
                  onChoisir: (h) => notifier.definirNePasDeranger(
                      prefs.nePasDerangerDebut ?? _dndDebutDefaut, h),
                ),
              ],
            ],
          ),
      ],
    );
  }

  /// A category is active unless explicitly turned off (default-on).
  static bool _estActive(PreferencesUtilisateur prefs, String cle) =>
      prefs.notificationsParCategorie[cle] ?? true;
}

/// Default quiet-hours window applied when the user first enables it.
const String _dndDebutDefaut = '22:00';
const String _dndFinDefaut = '07:00';

/// A tappable row showing a stored `HH:MM` time and opening a time picker.
class _LigneHeure extends StatelessWidget {
  final String label;
  final String heure; // `HH:MM`
  final ValueChanged<String> onChoisir;

  const _LigneHeure({
    required this.label,
    required this.heure,
    required this.onChoisir,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tod = _versTimeOfDay(heure);
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        leading: const Icon(Icons.schedule_outlined),
        title: Text(label),
        trailing: Text(
          tod.format(context),
          style: theme.textTheme.bodyLarge
              ?.copyWith(color: theme.colorScheme.primary),
        ),
        onTap: () async {
          final choisi =
              await showTimePicker(context: context, initialTime: tod);
          if (choisi != null) onChoisir(_depuisTimeOfDay(choisi));
        },
      ),
    );
  }

  /// Parses a `HH:MM` string into a [TimeOfDay] (falls back to midnight).
  static TimeOfDay _versTimeOfDay(String heure) {
    final parts = heure.split(':');
    final h = parts.length == 2 ? int.tryParse(parts[0]) ?? 0 : 0;
    final m = parts.length == 2 ? int.tryParse(parts[1]) ?? 0 : 0;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  /// Formats a [TimeOfDay] into a zero-padded `HH:MM` string for storage.
  static String _depuisTimeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

String _labelSemis(AppLocalizations l) => l.notifSemis;
String _labelArrosage(AppLocalizations l) => l.notifArrosage;
String _labelRecolte(AppLocalizations l) => l.notifRecolte;
String _labelMeteo(AppLocalizations l) => l.notifMeteo;
String _labelEntretien(AppLocalizations l) => l.notifEntretien;
String _labelRotation(AppLocalizations l) => l.notifRotation;
