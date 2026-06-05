import 'package:riverpod/riverpod.dart';

import '../../core/constants/constantes_moteur.dart';
import '../../domain/enums/type_alerte_meteo.dart';
import '../../domain/value_objects/prevision_meteo.dart';

/// One day flagged as risky by [EvaluateurAlertesMeteo].
typedef JourRisque = ({DateTime date, TypeAlerteMeteo type, double valeur});

/// Pure engine calculator that scans a forecast and flags the risky days.
///
/// Stateless and dependency-free. It re-derives frost/heatwave/heavy-rain risk
/// from each [PrevisionMeteo] using [SeuilsMeteo] — the forecast DTO carries the
/// raw temperatures/precipitation but not the pre-computed flags (those live
/// only on the observed-weather DTO). A single day may raise several risks.
class EvaluateurAlertesMeteo {
  const EvaluateurAlertesMeteo();

  /// Flags the risky days in [previsions]. The result is ordered as the input,
  /// with each day's risks in the order gel → canicule → fortePluie.
  List<JourRisque> evaluer(List<PrevisionMeteo> previsions) {
    final risques = <JourRisque>[];
    for (final p in previsions) {
      if (p.tempMin <= SeuilsMeteo.gelC) {
        risques.add((date: p.date, type: TypeAlerteMeteo.gel, valeur: p.tempMin));
      }
      if (p.tempMax >= SeuilsMeteo.caniculeC) {
        risques.add(
            (date: p.date, type: TypeAlerteMeteo.canicule, valeur: p.tempMax));
      }
      if (p.precipitationsMm >= SeuilsMeteo.fortePluieMmJour) {
        risques.add((
          date: p.date,
          type: TypeAlerteMeteo.fortePluie,
          valeur: p.precipitationsMm,
        ));
      }
    }
    return List.unmodifiable(risques);
  }
}

/// DI provider for the (stateless) [EvaluateurAlertesMeteo].
final evaluateurAlertesMeteoProvider = Provider<EvaluateurAlertesMeteo>(
  (ref) => const EvaluateurAlertesMeteo(),
);
