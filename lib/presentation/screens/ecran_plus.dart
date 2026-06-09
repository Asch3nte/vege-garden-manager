import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'ecran_en_construction.dart';

/// Tab 5 — **Plus** (`⋯`): settings (6 sub-sections), post-harvest, community
/// (V2), about, transparency (docs/09 §7). The `Paramètres.html` mock-up lives
/// under this tab.
///
/// Placeholder for now; to be implemented as a menu routing into the settings
/// sub-screens.
class EcranPlus extends StatelessWidget {
  const EcranPlus({super.key});

  @override
  Widget build(BuildContext context) {
    return EcranEnConstruction(
      titre: AppLocalizations.of(context)!.navPlus,
      icone: Icons.more_horiz_outlined,
    );
  }
}
