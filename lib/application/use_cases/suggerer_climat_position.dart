import 'package:riverpod/riverpod.dart';

import '../../domain/repositories/abstract_meteo_service.dart';
import '../../domain/value_objects/localisation.dart';
import '../engine/derivateur_localisation.dart';
import '../providers/service_providers.dart';

/// Use case: suggest a climate and hardiness for a chosen position, refined by
/// its altitude when the network may be used.
class SuggererClimatPosition {
  final AbstractMeteoService _meteo;
  final DerivateurLocalisation _derivateur;

  SuggererClimatPosition(this._meteo,
      [this._derivateur = const DerivateurLocalisation()]);

  /// Suggestion for the defined [position]. The altitude is fetched only when
  /// [reseauAutorise]; an unknown altitude falls back to the latitude alone.
  Future<SuggestionClimat> executer(Localisation position,
      {required bool reseauAutorise}) async {
    final altitude =
        reseauAutorise ? await _meteo.obtenirElevation(position) : null;
    return _derivateur.deriver(position, altitudeM: altitude);
  }
}

final suggererClimatPositionProvider = Provider<SuggererClimatPosition>(
    (ref) => SuggererClimatPosition(ref.watch(meteoServiceProvider)));
