import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pot_a_gerer/presentation/widgets/format_dates.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
    await initializeDateFormatting('en');
  });

  const fr = FormatDates(Locale('fr'));
  const en = FormatDates(Locale('en'));
  final d = DateTime(2026, 6, 9);

  test('day and month', () {
    expect(fr.jourMois(d), '9 juin');
    expect(en.jourMois(d), 'June 9');
  });

  test('day, month and year', () {
    expect(fr.jourMoisAnnee(d), '9 juin 2026');
    expect(en.jourMoisAnnee(d), 'June 9, 2026');
  });

  test('capitalised month and year', () {
    expect(fr.moisAnnee(d), 'Juin 2026');
    expect(en.moisAnnee(d), 'June 2026');
  });
}
