import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers/unites_provider.dart';
import '../../domain/enums/grandeur_mesure.dart';
import '../../domain/enums/systeme_unites.dart';
import '../../domain/services/convertisseur_unites.dart';
import '../../domain/value_objects/dimensions_zone.dart';
import '../../domain/value_objects/preferences_unites.dart';
import '../../l10n/app_localizations.dart';

/// Formats metric measures in the unit the user chose for each quantity.
class FormateurMesures {
  static const _convertisseur = ConvertisseurUnites();
  static const int _poucesParPied = 12;
  static const double _oncesParLivre = 16;
  static const double _oncesLiquidesParGallon = 128;
  static const double _unitesParKilo = 1000;

  /// Shared by every formatter: patterns are parsed once per locale.
  static final Map<String, NumberFormat> _formats = {};

  final AppLocalizations _l10n;
  final PreferencesUnites _unites;

  const FormateurMesures(this._l10n, this._unites);

  bool _imperial(GrandeurMesure g) => _unites.pour(g) == SystemeUnites.imperial;

  /// [valeur] rounded half away from zero to [decimales] (0 to 2).
  static double _arrondi(double valeur, int decimales) {
    final facteur = [1, 10, 100][decimales];
    return (valeur * facteur).round() / facteur;
  }

  /// [valeur] rounded to [decimales] (0 to 2), in the locale.
  String _nombre(double valeur, [int decimales = 0]) {
    final motif = decimales == 0 ? '0' : '0.${'#' * decimales}';
    return _formats
        .putIfAbsent('${_l10n.localeName}|$motif',
            () => NumberFormat(motif, _l10n.localeName))
        .format(_arrondi(valeur, decimales));
  }

  String temperature(double celsius) => _imperial(GrandeurMesure.temperature)
      ? _l10n.mesureFahrenheit(
          _nombre(_convertisseur.celsiusVersFahrenheit(celsius)),
        )
      : _l10n.mesureCelsius(_nombre(celsius));

  /// The rounded number of degrees in the chosen scale, without symbol.
  String degres(double celsius) => _nombre(
    _imperial(GrandeurMesure.temperature)
        ? _convertisseur.celsiusVersFahrenheit(celsius)
        : celsius,
  );

  bool get temperatureEnFahrenheit => _imperial(GrandeurMesure.temperature);

  String get symboleTemperature => _imperial(GrandeurMesure.temperature)
      ? _l10n.symbolesFahrenheit
      : _l10n.symbolesCelsius;

  /// A temperature difference, such as the warmth a shelter adds.
  String ecartTemperature(double celsius) =>
      _imperial(GrandeurMesure.temperature)
      ? _l10n.mesureFahrenheit(
          _nombre(_convertisseur.ecartCelsiusVersFahrenheit(celsius), 1),
        )
      : _l10n.mesureCelsius(_nombre(celsius, 1));

  /// A range of temperature differences, such as a shelter's warmth.
  String plageEcartTemperature(double min, double max) =>
      _imperial(GrandeurMesure.temperature)
      ? _l10n.mesurePlageUnite(
          _nombre(_convertisseur.ecartCelsiusVersFahrenheit(min), 1),
          _nombre(_convertisseur.ecartCelsiusVersFahrenheit(max), 1),
          symboleTemperature,
        )
      : _l10n.mesurePlageUnite(
          _nombre(min, 1),
          _nombre(max, 1),
          symboleTemperature,
        );

  /// Inches (one decimal) under a foot, then feet and inches.
  String longueurCm(num cm) {
    if (!_imperial(GrandeurMesure.longueur)) {
      return _l10n.mesureCm(_nombre(cm.toDouble(), 1));
    }
    final enPouces = _convertisseur.centimetresVersPouces(cm.toDouble());
    if (_arrondi(enPouces, 1) < _poucesParPied) {
      return _l10n.mesurePouces(_nombre(enPouces, 1));
    }
    final pouces = enPouces.round();
    final pieds = pouces ~/ _poucesParPied;
    final reste = pouces % _poucesParPied;
    return reste == 0
        ? _l10n.mesurePieds('$pieds')
        : _l10n.mesurePiedsPouces('$pieds', '$reste');
  }

  String precipitations(double mm) => _imperial(GrandeurMesure.longueur)
      ? _l10n.mesurePouces(_nombre(_convertisseur.millimetresVersPouces(mm), 2))
      : _l10n.mesureMm(_nombre(mm, 1));

  String altitudeM(double m) => _imperial(GrandeurMesure.longueur)
      ? _l10n.mesurePieds(_nombre(_convertisseur.metresVersPieds(m)))
      : _l10n.mesureMetres(_nombre(m));

  String vent(double kmh) => _imperial(GrandeurMesure.longueur)
      ? _l10n.mesureMph(_nombre(_convertisseur.kmhVersMph(kmh)))
      : _l10n.mesureKmh(_nombre(kmh));

  /// A watering amount; in imperial, its depth of water (1 L/m² = 1 mm).
  String arrosage(double litresParM2) => _imperial(GrandeurMesure.longueur)
      ? _l10n.mesurePouces(
          _nombre(_convertisseur.millimetresVersPouces(litresParM2), 2),
        )
      : _l10n.mesureLitresM2(_nombre(litresParM2, 1));

  /// A range of lengths; metric keeps the compact « 15–30 cm ».
  String plageLongueurCm(int min, int max) =>
      _imperial(GrandeurMesure.longueur)
      ? _l10n.mesurePlage(longueurCm(min), longueurCm(max))
      : _l10n.mesurePlageCm('$min', '$max');

  /// A range of watering amounts, in L/m² or inches of water.
  String plageArrosage(double min, double max) =>
      _imperial(GrandeurMesure.longueur)
      ? _l10n.mesurePoucesPlage(
          _nombre(_convertisseur.millimetresVersPouces(min), 2),
          _nombre(_convertisseur.millimetresVersPouces(max), 2),
        )
      : _l10n.mesurePlageLitresM2(_nombre(min, 1), _nombre(max, 1));

  /// « 3 × 1,2 m », or in feet.
  String dimensionsZone(DimensionsZone d) {
    if (!_imperial(GrandeurMesure.longueur)) {
      return _l10n.mesureDimensionsMetres(
          _nombre(d.longueurCm / 100, 2), _nombre(d.largeurCm / 100, 2));
    }
    String pieds(int cm) =>
        _nombre(_convertisseur.metresVersPieds(cm / 100), 1);
    return _l10n.mesureDimensionsPieds(pieds(d.longueurCm), pieds(d.largeurCm));
  }

  String surfaceM2(double m2) => _imperial(GrandeurMesure.surface)
      ? _l10n.mesureFt2(_nombre(_convertisseur.m2VersFt2(m2), 1))
      : _l10n.mesureM2(_nombre(m2, 2));

  /// Grams or kilograms; ounces under a pound, then pounds. The unit is
  /// chosen on the rounded value, so 999.6 g reads « 1 kg ».
  String masseG(double grammes) {
    if (_imperial(GrandeurMesure.masse)) {
      final onces = _convertisseur.grammesVersOnces(grammes);
      return _arrondi(onces, 1) < _oncesParLivre
          ? _l10n.mesureOnces(_nombre(onces, 1))
          : _l10n.mesureLivres(_nombre(onces / _oncesParLivre, 1));
    }
    return _arrondi(grammes, 0) < _unitesParKilo
        ? _l10n.mesureGrammes(_nombre(grammes))
        : _l10n.mesureKilogrammes(_nombre(grammes / _unitesParKilo, 1));
  }

  /// Millilitres or litres; fluid ounces under a gallon, then gallons. The
  /// unit is chosen on the rounded value.
  String volumeMl(double ml) {
    if (_imperial(GrandeurMesure.volume)) {
      final onces = _convertisseur.millilitresVersOncesLiquides(ml);
      return _arrondi(onces, 1) < _oncesLiquidesParGallon
          ? _l10n.mesureOncesLiquides(_nombre(onces, 1))
          : _l10n.mesureGallons(_nombre(onces / _oncesLiquidesParGallon, 1));
    }
    return _arrondi(ml, 0) < _unitesParKilo
        ? _l10n.mesureMillilitres(_nombre(ml))
        : _l10n.mesureLitres(_nombre(ml / _unitesParKilo, 1));
  }
}

/// The measure formatter for [context]'s language and the chosen units; in
/// build, it rebuilds the widget when the units change.
FormateurMesures formateurMesures(BuildContext context, WidgetRef ref) =>
    FormateurMesures(AppLocalizations.of(context)!, ref.watch(unitesProvider));

/// The same, read once, for callbacks run outside build.
FormateurMesures formateurMesuresLu(BuildContext context, WidgetRef ref) =>
    FormateurMesures(AppLocalizations.of(context)!, ref.read(unitesProvider));
