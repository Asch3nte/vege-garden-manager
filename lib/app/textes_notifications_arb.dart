import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../domain/repositories/abstract_textes_notifications.dart';
import '../l10n/app_localizations.dart';

/// Notification texts read from the ARB files of the current language.
class TextesNotificationsArb implements AbstractTextesNotifications {
  /// Crop names spelled out in a title before the "+N" marker.
  static const int _maxNomsTitre = 3;

  final String Function() _langue;

  /// [_langue] is read on each call, so a language change applies at once.
  TextesNotificationsArb(this._langue);

  @override
  String get langue => _langue();

  AppLocalizations get _l10n => lookupAppLocalizations(Locale(langue));

  @override
  String titreRecapArrosage(List<String> noms, int total) {
    if (noms.isEmpty) return _l10n.notifArrosageTitreGenerique;
    final cites = math.min(noms.length, _maxNomsTitre);
    final visibles = noms.take(cites).join(', ');
    final reste = total - cites;
    return reste > 0
        ? _l10n.notifArrosageTitreReste(visibles, reste)
        : _l10n.notifArrosageTitre(visibles);
  }

  @override
  String corpsRecapArrosage(List<String> noms, int total) {
    if (noms.isEmpty) return _l10n.notifArrosageCorpsAnonyme(total);
    if (total == 1) return _l10n.notifArrosageCorpsUne(noms.first);
    return _l10n.notifArrosageCorpsListe(noms.join(', '));
  }
}
