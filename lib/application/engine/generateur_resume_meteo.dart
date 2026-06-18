import '../../domain/enums/etat_ciel_jour.dart';
import '../state/jour_meteo_vue.dart';
import '../state/meteo_accueil_vue.dart';

/// Pure engine that turns weather data into short French summary strings.
///
/// No Flutter dependency, no Riverpod — fully unit-testable. Called by
/// [MeteoDetailNotifier] to populate [MeteoDetailVue.resumeAujourdhui],
/// [MeteoDetailVue.resumeDemain] and [MeteoDetailVue.explicationTaches].
/// See ADR-0016 Lot 3.
class GenerateurResumeMeteo {
  const GenerateurResumeMeteo();

  // ── WMO mapping ───────────────────────────────────────────────────────────

  /// Converts a WMO weather interpretation code (0–99) to a sky-condition
  /// category. Unknown or out-of-range codes default to [EtatCielJour.couvert].
  EtatCielJour wmoVersEtatCiel(int code) {
    if (code <= 1) return EtatCielJour.ensoleille;
    if (code == 2) return EtatCielJour.nuageux;
    if (code == 3) return EtatCielJour.couvert;
    if (code == 45 || code == 48) return EtatCielJour.brouillard;
    if (code >= 51 && code <= 67) return EtatCielJour.pluie;
    if (code >= 71 && code <= 77) return EtatCielJour.neige;
    if (code >= 80 && code <= 82) return EtatCielJour.pluie;
    if (code == 85 || code == 86) return EtatCielJour.neige;
    if (code >= 95 && code <= 99) return EtatCielJour.orage;
    return EtatCielJour.couvert;
  }

  // ── Text generation ───────────────────────────────────────────────────────

  /// Short summary of [jour]'s conditions (today or any selected day).
  ///
  /// Format: «[etat]. Min X°, max Y°[. alerte]. [P % de pluie (Z mm)].
  /// Vent [fort/modere/faible] (W km/h).»
  String resumeJour(JourMeteoVue jour) {
    final buf = StringBuffer(_libelleEtat(wmoVersEtatCiel(jour.weathercode)));
    buf.write('. Min ${jour.tempMin.round()}°, max ${jour.tempMax.round()}°');

    if (jour.risqueGel) {
      buf.write('. ⚠ Risque de gel');
    } else if (jour.risqueCanicule) {
      buf.write('. ⚠ Risque de canicule');
    }

    if (jour.probabilitePluie >= 0.30) {
      final proba = (jour.probabilitePluie * 100).round();
      buf.write('. $proba % de risque de pluie');
      if (jour.precipitationsMm > 0) {
        buf.write(' (${jour.precipitationsMm.toStringAsFixed(1)} mm)');
      }
    }

    final vent = jour.ventMaxKmh.round();
    if (vent >= 50) {
      buf.write('. Vent très fort ($vent km/h)');
    } else if (vent >= 30) {
      buf.write('. Vent fort ($vent km/h)');
    } else if (vent >= 20) {
      buf.write('. Vent modéré ($vent km/h)');
    } else {
      buf.write('. Vent faible ($vent km/h)');
    }

    buf.write('.');
    return buf.toString();
  }

  /// Short outlook for [demain] (tomorrow). Returns `null` when [demain] is
  /// null (no J+1 forecast available).
  String? resumeDemain(JourMeteoVue? demain) {
    if (demain == null) return null;
    final etat = wmoVersEtatCiel(demain.weathercode);
    final buf = StringBuffer(_libelleEtatCourt(etat));
    buf.write(', max ${demain.tempMax.round()}°');

    if (demain.probabilitePluie >= 0.30) {
      final proba = (demain.probabilitePluie * 100).round();
      buf.write(', $proba % de risque de pluie');
      if (demain.precipitationsMm > 0) {
        buf.write(' (${demain.precipitationsMm.toStringAsFixed(1)} mm)');
      }
    }
    buf.write('.');
    return buf.toString();
  }

  /// French explanation of why tasks were generated as they were, derived from
  /// the garden-level [VerdictMeteo].
  String explicationTaches(VerdictMeteo verdict) => switch (verdict) {
        VerdictMeteo.pluieAVenir =>
          "Pluie prévue prochainement — vos tâches d'arrosage sont automatiquement différées.",
        VerdictMeteo.solHumide =>
          "Sol encore humide après les pluies récentes — pas d'arrosage nécessaire pour l'instant.",
        VerdictMeteo.arroserConseille =>
          "Temps chaud et sec — certaines cultures peuvent nécessiter un arrosage. Consultez le conseil par plantation.",
        VerdictMeteo.clement =>
          "Conditions clémentes — les tâches sont générées selon le besoin en eau de chaque plante.",
      };

  // ── Private helpers ───────────────────────────────────────────────────────

  String _libelleEtat(EtatCielJour etat) => switch (etat) {
        EtatCielJour.ensoleille => 'Temps ensoleillé',
        EtatCielJour.nuageux    => 'Ciel partiellement nuageux',
        EtatCielJour.couvert    => 'Ciel couvert',
        EtatCielJour.brouillard => 'Brouillard',
        EtatCielJour.pluie      => 'Pluie',
        EtatCielJour.neige      => 'Chutes de neige',
        EtatCielJour.orage      => 'Orages',
      };

  String _libelleEtatCourt(EtatCielJour etat) => switch (etat) {
        EtatCielJour.ensoleille => 'Ensoleillé',
        EtatCielJour.nuageux    => 'Partiellement nuageux',
        EtatCielJour.couvert    => 'Couvert',
        EtatCielJour.brouillard => 'Brouillard',
        EtatCielJour.pluie      => 'Pluvieux',
        EtatCielJour.neige      => 'Neige',
        EtatCielJour.orage      => 'Orages',
      };
}
