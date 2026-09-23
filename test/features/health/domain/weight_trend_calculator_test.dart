import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/health/domain/weight_trend_calculator.dart';

void main() {
  final start = DateTime(2026, 3);

  group('WeightTrendCalculator.fromDailyWeights', () {
    test('a single 3 kg spike moves the trend by 0.3 kg', () {
      final series = WeightTrendCalculator.fromDailyWeights({
        for (var day = 0; day < 10; day++) addLocalDays(start, day): 80,
        addLocalDays(start, 10): 83,
        addLocalDays(start, 11): 80,
      });

      expect(series.trendFor(addLocalDays(start, 9)), 80);
      expect(series.trendFor(addLocalDays(start, 10)), closeTo(80.3, 1e-9));
      expect(series.trendFor(addLocalDays(start, 11)), closeTo(80.27, 1e-9));
    });

    test('fills a gap with interpolated days', () {
      final series = WeightTrendCalculator.fromDailyWeights({
        start: 80,
        addLocalDays(start, 4): 78,
      });

      final trend = [
        for (var day = 0; day <= 4; day++)
          series.trendFor(addLocalDays(start, day)),
      ];
      expect(trend, everyElement(isNotNull));
      // Interpolated inputs: 79.5, 79, 78.5, 78.
      expect(trend[1], closeTo(79.95, 1e-9));
      for (var index = 1; index < trend.length; index++) {
        expect(trend[index], lessThan(trend[index - 1]!));
      }
    });

    test('has no trend before the first or after the last weigh-in', () {
      final series = WeightTrendCalculator.fromDailyWeights({
        addLocalDays(start, 1): 80,
        addLocalDays(start, 3): 79,
      });

      expect(series.trendFor(start), isNull);
      expect(series.trendFor(addLocalDays(start, 4)), isNull);
      expect(series.lastDay, addLocalDays(start, 3));
      expect(series.rawByDay, {
        localDayKey(addLocalDays(start, 1)): 80,
        localDayKey(addLocalDays(start, 3)): 79,
      });
    });

    test('keeps one value per day across daylight saving changes', () {
      // Germany switches to summer time on 2026-03-29.
      final series = WeightTrendCalculator.fromDailyWeights({
        DateTime(2026, 3, 27): 80,
        DateTime(2026, 3, 31): 80,
      });

      expect(series.trendByDay, hasLength(5));
    });
  });

  group('DailyWeightSeries.slopeKgPerDay', () {
    test('matches a steady loss after the trend settles', () {
      final series = WeightTrendCalculator.fromDailyWeights({
        for (var day = 0; day < 60; day++)
          addLocalDays(start, day): 90 - 0.1 * day,
      });

      expect(series.slopeKgPerDay(), closeTo(-0.1, 0.001));
    });

    test('is null with fewer than two trend values', () {
      final series = WeightTrendCalculator.fromDailyWeights({start: 80});

      expect(series.slopeKgPerDay(), isNull);
      expect(DailyWeightSeries.empty.slopeKgPerDay(), isNull);
    });
  });

  group('WeightTrendCalculator.fromSources', () {
    test('prefers manual entries and uses the Health median per day', () {
      final series = WeightTrendCalculator.fromSources(
        manualEntries: [ManualHealthWeightEntry(day: start, weightKg: 81)],
        healthSamples: [
          HealthWeightSample(recordedAt: start, weightKg: 79),
          for (final weight in [80.0, 83.0, 81.0])
            HealthWeightSample(
              recordedAt: addLocalDays(start, 1).add(const Duration(hours: 7)),
              weightKg: weight,
            ),
        ],
      );

      expect(series.rawByDay[localDayKey(start)], 81);
      expect(series.rawByDay[localDayKey(addLocalDays(start, 1))], 81);
    });
  });
}
