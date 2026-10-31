import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/diary/application/diary_day_weight_trend_provider.dart';
import 'package:yamt/features/health/application/weight_series_provider.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/health/domain/recent_weight_trend.dart';
import 'package:yamt/features/health/domain/weight_trend_calculator.dart';

final _now = DateTime(2026, 4, 27, 12);

final DailyWeightSeries _series = WeightTrendCalculator.fromSources(
  manualEntries: [
    ManualHealthWeightEntry(day: DateTime(2026, 4, 10), weightKg: 80),
    ManualHealthWeightEntry(day: DateTime(2026, 4, 20), weightKg: 79),
    ManualHealthWeightEntry(day: DateTime(2026, 4, 25), weightKg: 78),
  ],
);

ProviderContainer _container() {
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => _now),
      weightSeriesProvider.overrideWith((ref) async => _series),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<RecentWeightTrend> _read(ProviderContainer container, DateTime day) {
  final provider = diaryDayWeightTrendProvider(day);
  final subscription = container.listen(provider, (_, _) {});
  addTearDown(subscription.close);
  return container.read(provider.future);
}

void main() {
  test('the chart ends on a past day and ends with its weight', () async {
    final container = _container();

    final trend = await _read(container, DateTime(2026, 4, 20));

    expect(trend.days, hasLength(RecentWeightTrend.chartDayCount));
    expect(trend.days.last.day, DateTime(2026, 4, 20));
    expect(trend.days.last.weightKg, 79);
    expect(trend.days.first.day, DateTime(2026, 4, 7));
    expect(trend.trendWeightKg, closeTo(79, 1));
  });

  test('a future day shows the trend of today', () async {
    final container = _container();

    final trend = await _read(container, DateTime(2026, 5, 3));

    expect(trend.days.last.day, DateTime(2026, 4, 27));
    expect(trend.days.last.weightKg, isNull);
  });

  test('the time of day of the day does not matter', () async {
    final container = _container();

    final trend = await _read(container, DateTime(2026, 4, 20, 18));

    expect(trend.days.last.day, DateTime(2026, 4, 20));
  });

  test('a day before the first weighing has no weights', () async {
    final container = _container();

    final trend = await _read(container, DateTime(2026, 4));

    expect(trend.days.every((day) => day.weightKg == null), isTrue);
    expect(trend.trendWeightKg, isNull);
  });
}
