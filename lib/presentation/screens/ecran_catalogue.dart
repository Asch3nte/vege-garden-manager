import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'ecran_en_construction.dart';

/// Tab 3 — **Catalogue**: knowledge base, plant fiches, search & filters
/// (docs/09 §5).
///
/// Placeholder for now; to be implemented from the `Catalogue.html` mock-up and
/// wired to the YAML catalogue in the infrastructure layer.
class EcranCatalogue extends StatelessWidget {
  const EcranCatalogue({super.key});

  @override
  Widget build(BuildContext context) {
    return EcranEnConstruction(
      titre: AppLocalizations.of(context)!.navCatalogue,
      icone: Icons.menu_book_outlined,
    );
  }
}
