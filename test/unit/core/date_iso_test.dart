// Guards the storage round-trip for dates.
//
// Dates go to SQLite as UTC ISO-8601 but the whole domain reasons in local time.
// Reading them back without converting yields the right *instant* on the wrong
// *calendar day*, which silently breaks every "same day" comparison (task
// dedup, day grouping in the calendar…). These tests pin the symmetry.
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/core/utils/date_iso.dart';

void main() {
  test('a local date round-trips to the identical local date', () {
    final local = DateTime(2026, 6, 10);
    final relu = DateIso.depuisStockage(DateIso.versStockage(local));
    expect(relu, local);
    expect(relu.isUtc, isFalse);
    expect(relu.day, local.day);
  });

  test('a local date-time round-trips exactly', () {
    final local = DateTime(2026, 1, 3, 23, 45, 12, 34);
    expect(DateIso.depuisStockage(DateIso.versStockage(local)), local);
  });

  test('storage form is UTC ISO-8601 (sortable, timezone-free)', () {
    final iso = DateIso.versStockage(DateTime.utc(2026, 6, 10, 14, 30));
    expect(iso, '2026-06-10T14:30:00.000Z');
  });

  test('a UTC date read back is the same instant, expressed locally', () {
    final utc = DateTime.utc(2026, 6, 10, 14, 30);
    final relu = DateIso.depuisStockage(DateIso.versStockage(utc));
    expect(relu.isUtc, isFalse);
    expect(relu.toUtc(), utc);
  });

  test('nullable helpers pass null through', () {
    expect(DateIso.versStockageNullable(null), isNull);
    expect(DateIso.depuisStockageNullable(null), isNull);
    expect(
      DateIso.depuisStockageNullable(DateIso.versStockageNullable(DateTime(2026, 2, 1))),
      DateTime(2026, 2, 1),
    );
  });

  test('maintenant() is a local instant serialised for storage', () {
    final avant = DateTime.now();
    final relu = DateIso.depuisStockage(DateIso.maintenant());
    expect(relu.isUtc, isFalse);
    expect(relu.difference(avant).abs(), lessThan(const Duration(seconds: 5)));
  });
}
