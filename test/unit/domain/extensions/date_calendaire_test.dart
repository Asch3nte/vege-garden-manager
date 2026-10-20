import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/extensions/date_calendaire.dart';

void main() {
  // 2026-03-29 and 2026-10-25 are DST changes in Europe; the cases only bite
  // when the suite runs in such a zone, and hold everywhere else.
  group('joursJusqua', () {
    test('counts calendar days across the spring DST change', () {
      expect(DateTime(2026, 3, 29).joursJusqua(DateTime(2026, 3, 30)), 1);
      expect(DateTime(2026, 3, 1).joursJusqua(DateTime(2026, 4, 1)), 31);
    });

    test('counts calendar days across the autumn DST change', () {
      expect(DateTime(2026, 10, 25).joursJusqua(DateTime(2026, 10, 26)), 1);
    });

    test('ignores the time of day', () {
      expect(
          DateTime(2026, 6, 1, 23, 59).joursJusqua(DateTime(2026, 6, 2, 0, 1)),
          1);
    });

    test('is negative for an earlier date', () {
      expect(DateTime(2026, 6, 2).joursJusqua(DateTime(2026, 6, 1)), -1);
    });
  });

  group('plusJours', () {
    test('lands on local midnight across the autumn DST change', () {
      expect(DateTime(2026, 10, 24).plusJours(2), DateTime(2026, 10, 26));
    });

    test('keeps a UTC date in UTC', () {
      expect(DateTime.utc(2026, 6, 1, 15).plusJours(1), DateTime.utc(2026, 6, 2));
    });

    test('drops the time of day', () {
      expect(DateTime(2026, 6, 1, 15, 30).plusJours(1), DateTime(2026, 6, 2));
    });
  });
}
