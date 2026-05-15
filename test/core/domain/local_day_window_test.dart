import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/local_day_window.dart';

void main() {
  group('local day window', () {
    test('normalizes timestamps to local calendar midnight', () {
      final normalized = normalizeLocalDay(DateTime(2026, 5, 14, 23, 59, 58));

      expect(normalized, DateTime(2026, 5, 14));
    });

    test('adds whole local days across month boundaries', () {
      expect(addLocalDays(DateTime(2026, 1, 31, 15), 1), DateTime(2026, 2));
      expect(addLocalDays(DateTime(2026, 3, 1, 15), -1), DateTime(2026, 2, 28));
    });

    test('adds whole local days across leap day', () {
      expect(addLocalDays(DateTime(2024, 2, 28, 12), 1), DateTime(2024, 2, 29));
      expect(addLocalDays(DateTime(2024, 2, 29, 12), 1), DateTime(2024, 3));
      expect(addLocalDays(DateTime(2025, 2, 28, 12), 1), DateTime(2025, 3));
    });

    test('stays on local midnights around DST transitions', () {
      expect(addLocalDays(DateTime(2026, 3, 29, 12), 1), DateTime(2026, 3, 30));
      expect(
        addLocalDays(DateTime(2026, 10, 25, 12), 1),
        DateTime(2026, 10, 26),
      );
      expect(
        addLocalDays(DateTime(2026, 3, 30, 12), -1),
        DateTime(2026, 3, 29),
      );
      expect(
        addLocalDays(DateTime(2026, 10, 26, 12), -1),
        DateTime(2026, 10, 25),
      );
    });

    test('resolves rolling window start from normalized end', () {
      expect(
        resolveRollingLocalWindowStart(anchorDay: DateTime(2026, 5, 14, 18)),
        DateTime(2026, 5, 8),
      );
      expect(
        buildRollingLocalDays(anchorDay: DateTime(2026, 5, 14, 18)),
        <DateTime>[
          DateTime(2026, 5, 8),
          DateTime(2026, 5, 9),
          DateTime(2026, 5, 10),
          DateTime(2026, 5, 11),
          DateTime(2026, 5, 12),
          DateTime(2026, 5, 13),
          DateTime(2026, 5, 14),
        ],
      );
    });

    test('compares and keys local calendar days', () {
      expect(
        isSameLocalDay(
          DateTime(2026, 5, 14, 0, 1),
          DateTime(2026, 5, 14, 23, 59),
        ),
        isTrue,
      );
      expect(localDayKey(DateTime(2026, 5, 14, 23, 59)), '2026-5-14');
    });
  });
}
