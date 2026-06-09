import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'ecran_en_construction.dart';

/// Tab 2 — **Potager**: gardens, zones, plantations, plan, history. Hosts the
/// central FAB for quick creation (docs/09 §4).
///
/// Placeholder for now; to be implemented from the `Potager.html` mock-up.
class EcranPotager extends StatelessWidget {
  const EcranPotager({super.key});

  @override
  Widget build(BuildContext context) {
    return EcranEnConstruction(
      titre: AppLocalizations.of(context)!.navPotager,
      icone: Icons.local_florist_outlined,
    );
  }
}
