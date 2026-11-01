import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/data_export/domain/data_export_range.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';

import '../../../helpers/progress_source_overrides.dart';

void main() {
  // Goal 1: 1 to 9 September 2026; goal 2 (current) from 10 September.
  final settings = progressTwoGoalSettings();
  final today = DateTime(2026, 9, 24);

  DataExportDays resolve(DataExportRange range) =>
      range.resolve(settings: settings, today: today);

  group('DataExportGoalRange', () {
    test('goal runs from the start of the current goal to today', () {
      final days = resolve(const DataExportGoalRange(ProgressScope.goal));

      expect(days.from, DateTime(2026, 9, 10));
      expect(days.to, DateTime(2026, 9, 24));
    });

    test('all runs from the start of the first goal to today', () {
      final days = resolve(const DataExportGoalRange(ProgressScope.all));

      expect(days.from, DateTime(2026, 9));
      expect(days.to, DateTime(2026, 9, 24));
    });

    test('equals a range of the same scope only', () {
      expect(
        const DataExportGoalRange(ProgressScope.goal),
        const DataExportGoalRange(ProgressScope.goal),
      );
      expect(
        const DataExportGoalRange(ProgressScope.goal).hashCode,
        const DataExportGoalRange(ProgressScope.goal).hashCode,
      );
      expect(
        const DataExportGoalRange(ProgressScope.goal),
        isNot(const DataExportGoalRange(ProgressScope.all)),
      );
    });
  });

  group('DataExportGoalsRange', () {
    test('resolves a past goal from its start to its last day', () {
      final days = resolve(const DataExportGoalsRange(1, 1));

      expect(days.from, DateTime(2026, 9));
      expect(days.to, DateTime(2026, 9, 9));
    });

    test('a number past the past goals is the current goal', () {
      final days = resolve(const DataExportGoalsRange(2, 2));

      expect(days.from, DateTime(2026, 9, 10));
      expect(days.to, DateTime(2026, 9, 24));
    });

    test('resolves a span from the first goal start to the last goal end', () {
      final days = resolve(const DataExportGoalsRange(1, 2));

      expect(days.from, DateTime(2026, 9));
      expect(days.to, DateTime(2026, 9, 24));
    });

    test('contains the goals from first to last', () {
      const range = DataExportGoalsRange(2, 4);

      expect(range.contains(1), isFalse);
      expect(range.contains(2), isTrue);
      expect(range.contains(3), isTrue);
      expect(range.contains(4), isTrue);
      expect(range.contains(5), isFalse);
    });

    test('toggle adds a goal below and extends the span', () {
      expect(
        const DataExportGoalsRange(3, 4).toggle(1),
        const DataExportGoalsRange(1, 4),
      );
    });

    test('toggle adds a goal above and extends the span', () {
      expect(
        const DataExportGoalsRange(1, 2).toggle(4),
        const DataExportGoalsRange(1, 4),
      );
    });

    test('toggle takes off the first goal', () {
      expect(
        const DataExportGoalsRange(1, 3).toggle(1),
        const DataExportGoalsRange(2, 3),
      );
    });

    test('toggle takes off the last goal', () {
      expect(
        const DataExportGoalsRange(1, 3).toggle(3),
        const DataExportGoalsRange(1, 2),
      );
    });

    test('toggle on an inner goal shrinks the span to it', () {
      expect(
        const DataExportGoalsRange(1, 4).toggle(2),
        const DataExportGoalsRange(1, 2),
      );
    });

    test('toggle of the only goal gives null', () {
      expect(const DataExportGoalsRange(2, 2).toggle(2), isNull);
    });

    test('equals a range with the same first and last goal', () {
      expect(
        const DataExportGoalsRange(1, 2),
        const DataExportGoalsRange(1, 2),
      );
      expect(
        const DataExportGoalsRange(1, 2).hashCode,
        const DataExportGoalsRange(1, 2).hashCode,
      );
      expect(
        const DataExportGoalsRange(1, 2),
        isNot(const DataExportGoalsRange(1, 3)),
      );
      expect(
        const DataExportGoalsRange(1, 2),
        isNot(const DataExportGoalsRange(2, 2)),
      );
    });
  });

  group('DataExportLastDaysRange', () {
    test('offers 7 days, 4 weeks, and 3 months', () {
      expect(DataExportLastDaysRange.presets.map((range) => range.days), [
        7,
        28,
        91,
      ]);
    });

    test('resolves the days up to today, today included', () {
      final days = resolve(const DataExportLastDaysRange(7));

      expect(days.from, DateTime(2026, 9, 18));
      expect(days.to, DateTime(2026, 9, 24));
    });

    test('ignores the time of day of today', () {
      final days = const DataExportLastDaysRange(2)
          .resolve(settings: settings, today: DateTime(2026, 9, 24, 15, 30));

      expect(days.from, DateTime(2026, 9, 23));
      expect(days.to, DateTime(2026, 9, 24));
    });

    test('one day is today only', () {
      final days = resolve(const DataExportLastDaysRange(1));

      expect(days.from, DateTime(2026, 9, 24));
      expect(days.to, DateTime(2026, 9, 24));
    });

    test('equals a range of the same length', () {
      expect(
        const DataExportLastDaysRange(7),
        const DataExportLastDaysRange(7),
      );
      expect(
        const DataExportLastDaysRange(7).hashCode,
        const DataExportLastDaysRange(7).hashCode,
      );
      expect(
        const DataExportLastDaysRange(7),
        isNot(const DataExportLastDaysRange(28)),
      );
    });
  });

  group('DataExportCustomRange', () {
    test('resolves to the picked local days', () {
      final days = resolve(
        DataExportCustomRange(
          from: DateTime(2026, 9, 3, 18),
          to: DateTime(2026, 9, 5, 7),
        ),
      );

      expect(days.from, DateTime(2026, 9, 3));
      expect(days.to, DateTime(2026, 9, 5));
    });

    test('equals a range with the same days', () {
      final a = DataExportCustomRange(
        from: DateTime(2026, 9, 3),
        to: DateTime(2026, 9, 5),
      );
      final b = DataExportCustomRange(
        from: DateTime(2026, 9, 3),
        to: DateTime(2026, 9, 5),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(
          DataExportCustomRange(
            from: DateTime(2026, 9, 3),
            to: DateTime(2026, 9, 6),
          ),
        ),
      );
    });
  });

  test('ranges of different kinds are never equal', () {
    expect(
      const DataExportLastDaysRange(7),
      isNot(const DataExportGoalsRange(1, 1)),
    );
  });
}
