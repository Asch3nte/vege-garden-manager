import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Locale-aware date labels.
class FormatDates {
  final Locale _locale;

  const FormatDates(this._locale);

  /// Formats for the locale of [context].
  factory FormatDates.de(BuildContext context) =>
      FormatDates(Localizations.localeOf(context));

  String get _nomLocale => _locale.toLanguageTag();

  /// Day and month, e.g. « 9 juin ».
  String jourMois(DateTime date) => DateFormat.MMMMd(_nomLocale).format(date);

  /// Day, month and year, e.g. « 9 juin 2026 ».
  String jourMoisAnnee(DateTime date) =>
      DateFormat.yMMMMd(_nomLocale).format(date);

  /// Month and year with a capital initial, e.g. « Juin 2026 ».
  String moisAnnee(DateTime date) {
    final texte = DateFormat.yMMMM(_nomLocale).format(date);
    return texte.isEmpty
        ? texte
        : '${texte[0].toUpperCase()}${texte.substring(1)}';
  }
}
