import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/repository_providers.dart';
import '../../application/state/accueil_notifier.dart';
import '../../application/state/contexte_climat.dart';
import '../../application/state/meteo_accueil_notifier.dart';
import '../../application/state/potagers_notifier.dart';
import '../../application/state/saison_notifier.dart';
import '../../domain/entities/potager.dart';
import '../../domain/value_objects/localisation.dart';
import '../../domain/value_objects/zone_climatique.dart';

/// The active garden, exposed so the UI can read its current position.
final potagerActifProvider = FutureProvider<Potager?>((ref) async =>
    ref.watch(potagerRepositoryProvider).obtenirPotagerActif());

/// Stores [loc] on the active garden and refreshes the position-dependent views
/// (weather, season, climate context, dashboard).
Future<void> enregistrerPositionPotager(WidgetRef ref, Localisation loc) async {
  final potager =
      await ref.read(potagerRepositoryProvider).obtenirPotagerActif();
  if (potager == null) return;
  potager.mettreAJourLocalisation(loc);
  await ref.read(potagersProvider.notifier).modifier(potager);
  _invalider(ref);
}

/// Stores [zone] (climate + hardiness) on the active garden and refreshes the
/// climate-dependent views. Used by the settings panel to let the user adjust
/// climate/hardiness directly, independently of any position.
Future<void> enregistrerZoneClimatiquePotager(
    WidgetRef ref, ZoneClimatique zone) async {
  final potager =
      await ref.read(potagerRepositoryProvider).obtenirPotagerActif();
  if (potager == null) return;
  potager.mettreAJourZoneClimatique(zone);
  await ref.read(potagersProvider.notifier).modifier(potager);
  _invalider(ref);
}

/// Clears the active garden's position (back to undefined) and refreshes.
///
/// Used when the geolocation mode changes: switching modes resets the stored
/// position so the user re-picks one for the new mode.
Future<void> reinitialiserPositionPotager(WidgetRef ref) async {
  final potager =
      await ref.read(potagerRepositoryProvider).obtenirPotagerActif();
  if (potager == null) return;
  if (potager.localisation.estDefinie) {
    potager.mettreAJourLocalisation(const Localisation.nonDefinie());
    await ref.read(potagersProvider.notifier).modifier(potager);
  }
  _invalider(ref);
}

void _invalider(WidgetRef ref) {
  ref.invalidate(potagerActifProvider);
  ref.invalidate(meteoAccueilProvider);
  ref.invalidate(accueilProvider);
  ref.invalidate(saisonProvider);
  ref.invalidate(contexteClimatProvider);
}
