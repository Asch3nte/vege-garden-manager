import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/state/accueil_notifier.dart';
import '../../application/state/calendrier_notifier.dart';
import '../../application/state/contexte_climat.dart';
import '../../application/state/meteo_accueil_notifier.dart';
import '../../application/state/parcelles_notifier.dart';
import '../../application/state/potager_notifier.dart';
import '../../application/state/potagers_notifier.dart';
import '../../application/state/saison_notifier.dart';
import 'position_potager_actions.dart';

/// Invalidates every data-backed view model so they reload from the database.
///
/// Used after a **global** change — factory reset or onboarding completion —
/// where the tabs kept alive in the navigation shell's `IndexedStack` would
/// otherwise keep showing **stale cached data** (e.g. the previous garden's
/// zones on the dashboard until a manual refresh). Invalidating a family
/// provider ([parcellesProvider]) drops all of its instances.
void invaliderVuesDonnees(WidgetRef ref) {
  ref.invalidate(potagersProvider);
  ref.invalidate(potagerActifProvider);
  ref.invalidate(accueilProvider);
  ref.invalidate(potagerProvider);
  ref.invalidate(calendrierProvider);
  ref.invalidate(meteoAccueilProvider);
  ref.invalidate(saisonProvider);
  ref.invalidate(contexteClimatProvider);
  ref.invalidate(parcellesProvider);
}
