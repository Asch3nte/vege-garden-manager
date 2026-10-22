import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../domain/enums/source_localisation.dart';
import '../../domain/value_objects/localisation.dart';
import '../../l10n/app_localizations.dart';

/// Display texts of a garden position: place, origin and coordinates.
class LibellePosition {
  /// Shape of [libelleStocke], also matching labels saved by older versions.
  static final RegExp _motifStocke =
      RegExp(r'^\d+[.,]\d° [NS], \d+[.,]\d° [EOW]$');

  final Localisation _localisation;
  final AppLocalizations _l10n;

  const LibellePosition(this._localisation, this._l10n);

  /// Locale-neutral coordinate label stored as the name of a manual position
  /// that has no place name (e.g. `48.2° N, 2.4° E`).
  static String libelleStocke(double latitude, double longitude) {
    final (lat, ns) = _hemisphere(latitude, 'N', 'S');
    final (lon, eo) = _hemisphere(longitude, 'E', 'O');
    return '${lat.toStringAsFixed(1)}° $ns, ${lon.toStringAsFixed(1)}° $eo';
  }

  /// Coordinates formatted for display in the locale of [l10n].
  static String coordonnees(
      AppLocalizations l10n, double latitude, double longitude) {
    final nombre = NumberFormat('0.0', l10n.localeName);
    final (lat, ns) = _hemisphere(latitude, l10n.positionNord, l10n.positionSud);
    final (lon, eo) = _hemisphere(longitude, l10n.positionEst, l10n.positionOuest);
    return l10n.positionCoordonnees(
        nombre.format(lat), ns, nombre.format(lon), eo);
  }

  /// Place name of a named manual position, its coordinates for an unnamed
  /// one, "GPS position" or "No position" otherwise.
  String get titre => switch (_localisation.source) {
        SourceLocalisation.nonDefinie => _l10n.positionAucune,
        SourceLocalisation.gps => _l10n.positionGps,
        SourceLocalisation.manuelle => _nom ?? _coords,
      };

  /// Origin and coordinates, or `null` without a position.
  String? get detail => switch (_localisation.source) {
        SourceLocalisation.nonDefinie => null,
        SourceLocalisation.gps => _coords,
        SourceLocalisation.manuelle => _nom == null
            ? _l10n.positionOrigineManuelle
            : _l10n.positionDetailManuelle(_coords),
      };

  /// One-line status: place and origin.
  String get court => switch (_localisation.source) {
        SourceLocalisation.nonDefinie => _l10n.positionAucune,
        SourceLocalisation.gps => _l10n.positionCourtGps(_coords),
        SourceLocalisation.manuelle =>
          _l10n.positionCourtManuelle(_nom ?? _coords),
      };

  /// Icon of the position origin.
  IconData get icone => switch (_localisation.source) {
        SourceLocalisation.gps => PhosphorIconsRegular.crosshair,
        _ => PhosphorIconsRegular.globe,
      };

  /// Place name, or `null` when the stored name is only coordinates.
  String? get _nom {
    final ville = _localisation.ville;
    return ville == null || _motifStocke.hasMatch(ville) ? null : ville;
  }

  String get _coords => coordonnees(
      _l10n, _localisation.latitude!, _localisation.longitude!);

  /// Absolute value rounded to the displayed precision, with its letter: the
  /// sign is read after rounding so that `-0.04` is not shown as south.
  static (double, String) _hemisphere(
      double valeur, String positif, String negatif) {
    final arrondi = (valeur * 10).roundToDouble() / 10;
    return (arrondi.abs(), arrondi < 0 ? negatif : positif);
  }
}
