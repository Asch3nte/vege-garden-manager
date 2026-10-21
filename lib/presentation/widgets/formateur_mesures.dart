import 'package:intl/intl.dart';

import '../../domain/enums/grandeur_mesure.dart';
import '../../domain/enums/systeme_unites.dart';
import '../../domain/services/convertisseur_unites.dart';
import '../../domain/value_objects/preferences_unites.dart';
import '../../l10n/app_localizations.dart';

/// Formats metric measures in the unit the user chose for each quantity.
class FormateurMesures {
  static const _convertisseur = ConvertisseurUnites();
  static const int _poucesParPied = 12;
  static const double _oncesParLivre = 16;
  static const double _oncesLiquidesParGallon = 128;
  static const double _unitesParKilo = 1000;

  final AppLocalizations _l10n;
  final PreferencesUnites _unites;

  const FormateurMesures(this._l10n, this._unites);

  bool _imperial(GrandeurMesure g) => _unites.pour(g) == SystemeUnites.imperial;

  /// [valeur] rounded half away from zero to [decimales], in the locale.
  String _nombre(double valeur, [int decimales = 0]) {
    final facteur = [1, 10, 100][decimales];
    final arrondi = (valeur * facteur).round() / facteur;
    return NumberFormat(
      decimales == 0 ? '0' : '0.${'#' * decimales}',
      _l10n.localeName,
    ).format(arrondi);
  }

  String temperature(double celsius) => _imperial(GrandeurMesure.temperature)
      ? _l10n.mesureFahrenheit(
          _nombre(_convertisseur.celsiusVersFahrenheit(celsius)),
        )
      : _l10n.mesureCelsius(_nombre(celsius));

  /// Degree sign only, for compact weather readings.
  String temperatureCourte(double celsius) => _l10n.mesureDegres(
    _nombre(
      _imperial(GrandeurMesure.temperature)
          ? _convertisseur.celsiusVersFahrenheit(celsius)
          : celsius,
    ),
  );

  /// A temperature difference, such as the warmth a shelter adds.
  String ecartTemperature(double celsius) =>
      _imperial(GrandeurMesure.temperature)
      ? _l10n.mesureFahrenheit(
          _nombre(_convertisseur.ecartCelsiusVersFahrenheit(celsius), 1),
        )
      : _l10n.mesureCelsius(_nombre(celsius, 1));

  /// Inches under a foot, then feet and inches.
  String longueurCm(num cm) {
    if (!_imperial(GrandeurMesure.longueur)) {
      return _l10n.mesureCm(_nombre(cm.toDouble()));
    }
    final pouces = _convertisseur.centimetresVersPouces(cm.toDouble()).round();
    if (pouces < _poucesParPied) return _l10n.mesurePouces('$pouces');
    final pieds = pouces ~/ _poucesParPied;
    final reste = pouces % _poucesParPied;
    return reste == 0
        ? _l10n.mesurePieds('$pieds')
        : _l10n.mesurePiedsPouces('$pieds', '$reste');
  }

  String precipitations(double mm) => _imperial(GrandeurMesure.longueur)
      ? _l10n.mesurePouces(_nombre(_convertisseur.millimetresVersPouces(mm), 2))
      : _l10n.mesureMm(_nombre(mm, 1));

  String vent(double kmh) => _imperial(GrandeurMesure.longueur)
      ? _l10n.mesureMph(_nombre(_convertisseur.kmhVersMph(kmh)))
      : _l10n.mesureKmh(_nombre(kmh));

  /// A watering amount; in imperial, its depth of water (1 L/m² = 1 mm).
  String arrosage(double litresParM2) => _imperial(GrandeurMesure.longueur)
      ? _l10n.mesurePouces(
          _nombre(_convertisseur.millimetresVersPouces(litresParM2), 2),
        )
      : _l10n.mesureLitresM2(_nombre(litresParM2, 1));

  String surfaceM2(double m2) => _imperial(GrandeurMesure.surface)
      ? _l10n.mesureFt2(_nombre(_convertisseur.m2VersFt2(m2), 1))
      : _l10n.mesureM2(_nombre(m2, 1));

  /// Grams or kilograms; ounces under a pound, then pounds.
  String masseG(double grammes) {
    if (_imperial(GrandeurMesure.masse)) {
      final onces = _convertisseur.grammesVersOnces(grammes);
      return onces < _oncesParLivre
          ? _l10n.mesureOnces(_nombre(onces, 1))
          : _l10n.mesureLivres(
              _nombre(
                _convertisseur.kilogrammesVersLivres(grammes / _unitesParKilo),
                1,
              ),
            );
    }
    return grammes < _unitesParKilo
        ? _l10n.mesureGrammes(_nombre(grammes))
        : _l10n.mesureKilogrammes(_nombre(grammes / _unitesParKilo, 1));
  }

  /// Millilitres or litres; fluid ounces under a gallon, then gallons.
  String volumeMl(double ml) {
    if (_imperial(GrandeurMesure.volume)) {
      final onces = _convertisseur.millilitresVersOncesLiquides(ml);
      return onces < _oncesLiquidesParGallon
          ? _l10n.mesureOncesLiquides(_nombre(onces, 1))
          : _l10n.mesureGallons(
              _nombre(_convertisseur.litresVersGallons(ml / _unitesParKilo), 1),
            );
    }
    return ml < _unitesParKilo
        ? _l10n.mesureMillilitres(_nombre(ml))
        : _l10n.mesureLitres(_nombre(ml / _unitesParKilo, 1));
  }
}
