import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'ecran_en_construction.dart';

/// Tab 4 — **Calendrier**: sowings, tasks, reminders, lunar calendar (opt-in,
/// V2) (docs/09 §6).
///
/// Placeholder for now; to be implemented from the `Calendrier.html` mock-up.
class EcranCalendrier extends StatelessWidget {
  const EcranCalendrier({super.key});

  @override
  Widget build(BuildContext context) {
    return EcranEnConstruction(
      titre: AppLocalizations.of(context)!.navCalendrier,
      icone: Icons.calendar_today_outlined,
    );
  }
}
