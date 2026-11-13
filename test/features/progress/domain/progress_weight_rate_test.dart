import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/health/domain/weight_trend_calculator.dart';
import 'package:yamt/features/progress/domain/progress_weight_rate.dart';

/// A trend that falls by 0.1 kg per day from 84 kg on 1 September 2026, with
/// a value on each of [days] of September.
DailyWeightSeries _series(Iterable<int> days) => DailyWeightSeries(
  rawByDay: const {},
  trendByDay: {
    for (final day in days)
      localDayKey(DateTime(2026, 9, day)): 84 - (day - 1) * 0.1,
  },
  lastDay: DateTime(2026, 9, days.max),
);

List<int> _days(int from, int to) => [
  for (var day = from; day <= to; day++) day,
];

void main() {
  test('the current goal counts from the day before its start to today', () {
    final rate = ProgressWeightRate.of(
      _series(_days(1, 24)),
      start: DateTime(2026, 9, 10),
      end: DateTime(2026, 9, 24),
    )!;

    expect(rate.since, DateTime(2026, 9, 10));
    expect(rate.until, DateTime(2026, 9, 24));
    expect(rate.kgPerWeek, closeTo(-0.7, 1e-9));
  });

  test('all data counts from the first weigh-in in the period', () {
    final rate = ProgressWeightRate.of(
      _series(_days(6, 24)),
      start: DateTime(2026, 9),
      end: DateTime(2026, 9, 24),
    )!;

    expect(rate.since, DateTime(2026, 9, 6));
    expect(rate.until, DateTime(2026, 9, 24));
    expect(rate.kgPerWeek, closeTo(-0.7, 1e-9));
  });

  test('a past goal leaves out the days before and after it', () {
    // Flat before 5 September and after 15 September, falling in between.
    final series = DailyWeightSeries(
      rawByDay: const {},
      trendByDay: {
        for (final day in _days(1, 24))
          localDayKey(DateTime(2026, 9, day)):
              84 - (day.clamp(4, 15) - 4) * 0.2,
      },
      lastDay: DateTime(2026, 9, 24),
    );

    final rate = ProgressWeightRate.of(
      series,
      start: DateTime(2026, 9, 5),
      end: DateTime(2026, 9, 15),
    )!;

    expect(rate.since, DateTime(2026, 9, 5));
    expect(rate.until, DateTime(2026, 9, 15));
    expect(rate.kgPerWeek, closeTo(-1.4, 1e-9));
  });

  test('ends on the last weigh-in before the end of the period', () {
    final rate = ProgressWeightRate.of(
      _series(_days(1, 18)),
      start: DateTime(2026, 9, 10),
      end: DateTime(2026, 9, 24),
    )!;

    expect(rate.until, DateTime(2026, 9, 18));
    expect(rate.kgPerWeek, closeTo(-0.7, 1e-9));
  });

  test('a goal with fewer than seven days of weights has no rate', () {
    final series = _series(_days(1, 24));

    expect(
      ProgressWeightRate.of(
        series,
        start: DateTime(2026, 9, 19),
        end: DateTime(2026, 9, 24),
      ),
      isNull,
    );
    expect(
      ProgressWeightRate.of(
        series,
        start: DateTime(2026, 9, 18),
        end: DateTime(2026, 9, 24),
      ),
      isNotNull,
    );
    // The goal is old enough, but its first weigh-in is not.
    expect(
      ProgressWeightRate.of(
        _series(_days(20, 24)),
        start: DateTime(2026, 9),
        end: DateTime(2026, 9, 24),
      ),
      isNull,
    );
  });

  test('a period without a weigh-in has no rate', () {
    expect(
      ProgressWeightRate.of(
        DailyWeightSeries.empty,
        start: DateTime(2026, 9),
        end: DateTime(2026, 9, 24),
      ),
      isNull,
    );
    expect(
      ProgressWeightRate.of(
        _series(_days(1, 5)),
        start: DateTime(2026, 9, 10),
        end: DateTime(2026, 9, 24),
      ),
      isNull,
    );
    expect(
      ProgressWeightRate.of(
        _series(_days(20, 24)),
        start: DateTime(2026, 9),
        end: DateTime(2026, 9, 10),
      ),
      isNull,
    );
  });
}
