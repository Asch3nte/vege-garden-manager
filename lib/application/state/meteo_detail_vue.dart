import 'jour_meteo_vue.dart';
import 'meteo_accueil_vue.dart';

/// Full view-model for [EcranMeteoDetail] (ADR-0016 Lot 3).
///
/// When [disponible] is false (no position on the active garden) all other
/// fields carry zero/empty/null values — the screen shows a prompt instead.
class MeteoDetailVue {
  final bool disponible;
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

  /// Short French summary of today's conditions (generated text).
  final String resumeAujourdhui;

  /// Short French outlook for tomorrow, or `null` when no J+1 data.
  final String? resumeDemain;

  /// French explanation of why the current tasks were generated (generated text).
  final String explicationTaches;

  const MeteoDetailVue._({
    required this.disponible,
    required this.nomPotager,
    required this.nomStation,
    required this.elevation,
    required this.derniereMaj,
    required this.jours,
    required this.verdictArrosage,
    required this.resumeAujourdhui,
    required this.resumeDemain,
    required this.explicationTaches,
  });

  /// Weather data is available (a position is set on the active garden).
  factory MeteoDetailVue.disponible({
    required String nomPotager,
    required String? nomStation,
    required double? elevation,
    required DateTime derniereMaj,
    required List<JourMeteoVue> jours,
    required VerdictMeteo verdictArrosage,
    required String resumeAujourdhui,
    required String? resumeDemain,
    required String explicationTaches,
  }) =>
      MeteoDetailVue._(
        disponible: true,
        nomPotager: nomPotager,
        nomStation: nomStation,
        elevation: elevation,
        derniereMaj: derniereMaj,
        jours: List.unmodifiable(jours),
        verdictArrosage: verdictArrosage,
        resumeAujourdhui: resumeAujourdhui,
        resumeDemain: resumeDemain,
        explicationTaches: explicationTaches,
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
        resumeAujourdhui: '',
        resumeDemain: null,
        explicationTaches: '',
      );
}
