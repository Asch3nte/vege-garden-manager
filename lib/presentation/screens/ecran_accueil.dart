import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'ecran_en_construction.dart';

/// Tab 1 — **Accueil** (dashboard): weather, today's tasks, alerts, garden
/// overview. Read-only, no creation actions (docs/09 §3).
///
/// Placeholder for now; to be implemented from the `Accueil.html` mock-up and
/// wired to the existing application-layer providers.
class EcranAccueil extends StatelessWidget {
  const EcranAccueil({super.key});

  @override
  Widget build(BuildContext context) {
    return EcranEnConstruction(
      titre: AppLocalizations.of(context)!.navAccueil,
      icone: Icons.home_outlined,
    );
  }
}
