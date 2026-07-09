import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/dimensions_app.dart';
import '../../../application/state/acces_niveau_provider.dart';
import '../../../application/state/preferences_notifier.dart';
import '../../../domain/entities/preferences_utilisateur.dart';
import '../../../l10n/app_localizations.dart';
import 'widgets_parametres.dart';

/// Default quiet-hours window applied when the user first enables do-not-disturb.
const String _npdDebutDefaut = '22:00';
const String _npdFinDefaut = '07:00';

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
        // Do-not-disturb window (intermediate+, granular control). Gated by the
        // master switch: when notifications are off, the window is meaningless.
        if (parCategorie)
          _SectionNePasDeranger(prefs: prefs, master: master, notifier: notifier),
      ],
    );
  }

  /// A category is active unless explicitly turned off (default-on).
  static bool _estActive(PreferencesUtilisateur prefs, String cle) =>
      prefs.notificationsParCategorie[cle] ?? true;
}

/// Do-not-disturb section: a toggle plus, when active, two time selectors for
/// the quiet-hours window (`HH:MM` bounds persisted on the preferences).
class _SectionNePasDeranger extends StatelessWidget {
  final PreferencesUtilisateur prefs;
  final bool master;
  final PreferencesNotifier notifier;

  const _SectionNePasDeranger({
    required this.prefs,
    required this.master,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actif = prefs.nePasDerangerActif;
    final debut = prefs.nePasDerangerDebut ?? _npdDebutDefaut;
    final fin = prefs.nePasDerangerFin ?? _npdFinDefaut;

    return ZoneParametres(
      titre: l10n.notifNePasDeranger,
      note: actif ? l10n.notifNePasDerangerNote : null,
      enfants: [
        RangeeInterrupteur(
          icone: Icons.bedtime_outlined,
          label: l10n.notifNePasDeranger,
          sousTitre: l10n.notifNePasDerangerSousTitre,
          valeur: master && actif,
          // Disabled while the master switch is off (a quiet window is
          // meaningless when notifications are entirely off).
          onChanged: master
              ? (v) => v
                  ? notifier.definirNePasDeranger(debut, fin)
                  : notifier.desactiverNePasDeranger()
              : null,
        ),
        if (master && actif) ...[
          _LigneHeure(
            label: l10n.notifNePasDerangerDebut,
            valeur: debut,
            onChoisi: (h) => notifier.definirNePasDeranger(h, fin),
          ),
          _LigneHeure(
            label: l10n.notifNePasDerangerFin,
            valeur: fin,
            onChoisi: (h) => notifier.definirNePasDeranger(debut, h),
          ),
        ],
      ],
    );
  }
}

/// A tappable row showing a time (`HH:MM`) that opens the platform time picker.
class _LigneHeure extends StatelessWidget {
  final String label;
  final String valeur;
  final ValueChanged<String> onChoisi;

  const _LigneHeure({
    required this.label,
    required this.valeur,
    required this.onChoisi,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heure = _parseHeure(valeur);
    return InkWell(
      onTap: () async {
        final choix = await showTimePicker(context: context, initialTime: heure);
        if (choix != null) onChoisi(_formatHeure(choix));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: EspacementsApp.s3,
          vertical: EspacementsApp.s3,
        ),
        child: Row(
          children: [
            Icon(Icons.schedule,
                size: TaillesIconesApp.md, color: theme.colorScheme.primary),
            const SizedBox(width: EspacementsApp.s3),
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            Text(
              heure.format(context),
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
            const SizedBox(width: EspacementsApp.s1),
            Icon(Icons.edit_outlined,
                size: TaillesIconesApp.sm, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Parses an `HH:MM` string to a [TimeOfDay] (falls back to midnight if invalid).
TimeOfDay _parseHeure(String hhmm) {
  final parts = hhmm.split(':');
  final h = parts.length == 2 ? int.tryParse(parts[0]) : null;
  final m = parts.length == 2 ? int.tryParse(parts[1]) : null;
  return TimeOfDay(hour: h ?? 0, minute: m ?? 0);
}

/// Formats a [TimeOfDay] as a zero-padded `HH:MM` string for storage.
String _formatHeure(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String _labelSemis(AppLocalizations l) => l.notifSemis;
String _labelArrosage(AppLocalizations l) => l.notifArrosage;
String _labelRecolte(AppLocalizations l) => l.notifRecolte;
String _labelMeteo(AppLocalizations l) => l.notifMeteo;
String _labelEntretien(AppLocalizations l) => l.notifEntretien;
String _labelRotation(AppLocalizations l) => l.notifRotation;
