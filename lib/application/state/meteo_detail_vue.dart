import 'jour_meteo_vue.dart';
import 'meteo_accueil_vue.dart';

/// Full view-model for [EcranMeteoDetail] (ADR-0016 Lot 3).
///
/// When [disponible] is false (no position on the active garden, or
/// [meteoDesactivee]) all other fields carry zero/empty/null values — the screen
/// shows a prompt instead.
class MeteoDetailVue {
  final bool disponible;

  /// The auto weather opt-out is on: no weather service was called.
  final bool meteoDesactivee;
  final String nomPotager;

  /// Nearest locality name from Nominatim, or `null` when unavailable.
  final String? nomStation;

  /// Ground elevation (metres) from Open-Meteo, or `null` when unavailable.
  final double? elevation;

  /// When the data was last fetched (local time).
  final DateTime derniereMaj;

  /// Daily forecasts, ordered by date (today first).
  final List<JourMeteoVue> jours;

  final VerdictMeteo verdictArrosage;

  const MeteoDetailVue._({
    required this.disponible,
    this.meteoDesactivee = false,
    required this.nomPotager,
    required this.nomStation,
    required this.elevation,
    required this.derniereMaj,
    required this.jours,
    required this.verdictArrosage,
  });

  /// Weather data is available (a position is set on the active garden).
  factory MeteoDetailVue.disponible({
    required String nomPotager,
    required String? nomStation,
    required double? elevation,
    required DateTime derniereMaj,
    required List<JourMeteoVue> jours,
    required VerdictMeteo verdictArrosage,
  }) =>
      MeteoDetailVue._(
        disponible: true,
        nomPotager: nomPotager,
        nomStation: nomStation,
        elevation: elevation,
        derniereMaj: derniereMaj,
        jours: List.unmodifiable(jours),
        verdictArrosage: verdictArrosage,
      );

  /// No usable position — the screen invites the user to set one.
  factory MeteoDetailVue.indisponible({required String nomPotager}) =>
      MeteoDetailVue._(
        disponible: false,
        nomPotager: nomPotager,
        nomStation: null,
        elevation: null,
        derniereMaj: DateTime.now(),
        jours: const [],
        verdictArrosage: VerdictMeteo.clement,
      );

  /// Auto weather opted out — no weather service is called.
  factory MeteoDetailVue.desactivee({required String nomPotager}) =>
      MeteoDetailVue._(
        disponible: false,
        meteoDesactivee: true,
        nomPotager: nomPotager,
        nomStation: null,
        elevation: null,
        derniereMaj: DateTime.now(),
        jours: const [],
        verdictArrosage: VerdictMeteo.clement,
      );
}
