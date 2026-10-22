import 'package:riverpod/riverpod.dart';

import '../../domain/repositories/abstract_meteo_service.dart';
import '../../domain/value_objects/localisation.dart';
import '../engine/derivateur_localisation.dart';
import '../providers/service_providers.dart';
import '../state/preferences_notifier.dart';

/// Use case: suggest a climate and hardiness for a chosen position, refined by
/// its altitude when automatic network calls are allowed.
class SuggererClimatPosition {
  final AbstractMeteoService _meteo;
  final bool Function() _reseauAutorise;
  final DerivateurLocalisation _derivateur;

  SuggererClimatPosition(this._meteo, this._reseauAutorise,
      [this._derivateur = const DerivateurLocalisation()]);

  /// Suggestion for the defined [position], or `null` when the network opt-out
  /// forbids fetching the altitude or the altitude is unknown (the latitude-only
  /// suggestion then stands).
  Future<SuggestionClimat?> executer(Localisation position) async {
    if (!_reseauAutorise()) return null;
    final altitude = await _meteo.obtenirElevation(position);
    if (altitude == null) return null;
    return _derivateur.deriver(position, altitudeM: altitude);
  }
}

final suggererClimatPositionProvider = Provider<SuggererClimatPosition>(
  (ref) => SuggererClimatPosition(
    ref.watch(meteoServiceProvider),
    () => ref.read(preferencesProvider).value?.meteoAutoActive ?? false,
  ),
);
