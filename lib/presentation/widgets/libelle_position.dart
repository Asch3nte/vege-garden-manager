import 'package:flutter/widgets.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../domain/enums/source_localisation.dart';
import '../../domain/value_objects/localisation.dart';
import '../../l10n/app_localizations.dart';

/// Display texts of a garden position: place, origin and coordinates.
class LibellePosition {
  final Localisation _localisation;
  final AppLocalizations _l10n;

  const LibellePosition(this._localisation, this._l10n);

  /// Compact coordinate label (e.g. `48.2° N, 2.4° E`). The cardinal letters
  /// are geographic notation, intentionally kept literal.
  static String coordonnees(double latitude, double longitude) {
    final ns = latitude >= 0 ? 'N' : 'S';
    final eo = longitude >= 0 ? 'E' : 'O';
    return '${latitude.abs().toStringAsFixed(1)}° $ns, '
        '${longitude.abs().toStringAsFixed(1)}° $eo';
  }

  /// Place name of a manual position, "GPS position" otherwise.
  String get titre => switch (_localisation.source) {
        SourceLocalisation.nonDefinie => _l10n.positionAucune,
        SourceLocalisation.gps => _l10n.positionGps,
        SourceLocalisation.manuelle => _lieu,
      };

  /// Origin and coordinates, or `null` without a position.
  String? get detail => switch (_localisation.source) {
        SourceLocalisation.nonDefinie => null,
        SourceLocalisation.gps => _coords,
        SourceLocalisation.manuelle => _lieu == _coords
            ? _l10n.positionOrigineManuelle
            : _l10n.positionDetailManuelle(_coords),
      };

  /// One-line status: place and origin.
  String get court => switch (_localisation.source) {
        SourceLocalisation.nonDefinie => _l10n.positionAucune,
        SourceLocalisation.gps => _l10n.positionCourtGps(_coords),
        SourceLocalisation.manuelle => _l10n.positionCourtManuelle(_lieu),
      };

  IconData get icone => switch (_localisation.source) {
        SourceLocalisation.gps => PhosphorIconsRegular.crosshair,
        _ => PhosphorIconsRegular.globe,
      };

  String get _lieu => _localisation.ville ?? _coords;

  String get _coords =>
      coordonnees(_localisation.latitude!, _localisation.longitude!);
}
