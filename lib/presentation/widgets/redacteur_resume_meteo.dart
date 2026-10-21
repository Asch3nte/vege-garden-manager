import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../application/state/jour_meteo_vue.dart';
import '../../application/state/meteo_accueil_vue.dart';
import '../../domain/enums/etat_ciel_jour.dart';
import '../../l10n/app_localizations.dart';

/// Writes the weather-detail summaries in the user's language.
class RedacteurResumeMeteo {
  /// Rain probability from which rain is mentioned.
  static const double _seuilPluie = 0.30;

  final AppLocalizations _l10n;
  final NumberFormat _mm;

  RedacteurResumeMeteo(this._l10n, Locale locale)
      : _mm = NumberFormat('0.0', locale.toLanguageTag());

  /// Writer for the locale of [context].
  factory RedacteurResumeMeteo.de(BuildContext context) => RedacteurResumeMeteo(
      AppLocalizations.of(context)!, Localizations.localeOf(context));

  /// Summary of [jour]: sky, temperatures, alert, rain and wind.
  String resumeJour(JourMeteoVue jour) {
    final phrases = [
      _l10n.meteoResumeEtat(EtatCielJour.depuisWmo(jour.weathercode).name),
      _l10n.meteoResumeTemperatures(jour.tempMin.round(), jour.tempMax.round()),
      if (jour.risqueGel)
        _l10n.meteoResumeGel
      else if (jour.risqueCanicule)
        _l10n.meteoResumeCanicule,
      if (jour.probabilitePluie >= _seuilPluie)
        jour.precipitationsMm > 0
            ? _l10n.meteoResumePluieVolume(
                _pourcent(jour), _mm.format(jour.precipitationsMm))
            : _l10n.meteoResumePluie(_pourcent(jour)),
      _l10n.meteoResumeVent(_forceVent(jour.ventMaxKmh), jour.ventMaxKmh.round()),
    ];
    return phrases.join(' ');
  }

  /// Short outlook for [demain].
  String resumeDemain(JourMeteoVue demain) {
    final etat = _l10n
        .meteoDemainEtat(EtatCielJour.depuisWmo(demain.weathercode).name);
    final max = demain.tempMax.round();
    if (demain.probabilitePluie < _seuilPluie) {
      return _l10n.meteoDemain(etat, max);
    }
    return demain.precipitationsMm > 0
        ? _l10n.meteoDemainPluieVolume(
            etat, max, _pourcent(demain), _mm.format(demain.precipitationsMm))
        : _l10n.meteoDemainPluie(etat, max, _pourcent(demain));
  }

  /// Why the watering tasks follow the garden-level [verdict].
  String explicationTaches(VerdictMeteo verdict) =>
      _l10n.meteoExplicationTaches(verdict.name);

  int _pourcent(JourMeteoVue jour) => (jour.probabilitePluie * 100).round();

  String _forceVent(double kmh) {
    final arrondi = kmh.round();
    if (arrondi >= 50) return 'tresFort';
    if (arrondi >= 30) return 'fort';
    if (arrondi >= 20) return 'modere';
    return 'faible';
  }
}
