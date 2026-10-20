import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/health/domain/recent_weight_trend.dart';
import 'package:yamt/features/health/domain/weight_trend_calculator.dart';

void main() {
  final today = DateTime(2026, 9, 27);

  test('lists the last 14 days up to today with weigh-ins and trend', () {
    final series = WeightTrendCalculator.fromDailyWeights({
      addLocalDays(today, -20): 82,
      addLocalDays(today, -10): 81,
      addLocalDays(today, -2): 80.4,
    });

    final trend = RecentWeightTrend.fromSeries(series, today: today);

    expect(trend.days, hasLength(RecentWeightTrend.chartDayCount));
    expect(trend.days.first.day, addLocalDays(today, -13));
    expect(trend.days.last.day, today);
    expect(trend.days[3].weightKg, 81);
    expect(trend.days[4].weightKg, isNull);
    expect(trend.days[4].trendWeightKg, isNotNull);
    // No trend after the last weigh-in.
    expect(trend.days.last.trendWeightKg, isNull);
    expect(trend.latestWeighInKg, 80.4);
    expect(trend.latestWeighInDay, addLocalDays(today, -2));
    expect(trend.trendWeightKg, series.trendFor(addLocalDays(today, -2)));
    expect(trend.trendKgPerWeek, lessThan(0));
  });

  test('is empty without weigh-ins', () {
    final trend = RecentWeightTrend.fromSeries(
      DailyWeightSeries.empty,
      today: today,
    );

    expect(trend.days, hasLength(RecentWeightTrend.chartDayCount));
    expect(trend.days.every((day) => day.weightKg == null), isTrue);
    expect(trend.latestWeighInKg, isNull);
    expect(trend.latestWeighInDay, isNull);
    expect(trend.trendWeightKg, isNull);
    expect(trend.trendKgPerWeek, isNull);
  });

  test('takes the slope up to a today before the last weigh-in', () {
    final series = WeightTrendCalculator.fromDailyWeights({
      addLocalDays(today, -20): 82,
      addLocalDays(today, -10): 81,
      addLocalDays(today, -2): 85,
    });
    final earlier = addLocalDays(today, -5);

    final trend = RecentWeightTrend.fromSeries(series, today: earlier);

    expect(trend.days.last.day, earlier);
    expect(trend.trendKgPerWeek, lessThan(0));
    expect(trend.trendKgPerWeek, isNot(series.slopeKgPerDay()! * 7));
  });

  test('leaves the days before notBefore out of the slope', () {
    final series = WeightTrendCalculator.fromDailyWeights({
      addLocalDays(today, -12): 90,
      addLocalDays(today, -6): 80,
      addLocalDays(today, -3): 80.3,
      today: 80.6,
    });

    final trend = RecentWeightTrend.fromSeries(
      series,
      today: today,
      notBefore: addLocalDays(today, -6),
    );

    expect(trend.trendKgPerWeek, isNot(series.slopeKgPerDay()! * 7));
    expect(
      trend.trendKgPerWeek,
      series.slopeKgPerDay(notBefore: addLocalDays(today, -6))! * 7,
    );
  });
}
