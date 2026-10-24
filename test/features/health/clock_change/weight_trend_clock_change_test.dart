// These tests check the autumn clock change on 2026-10-25. CI runs them once
// more with TZ=Europe/Berlin; in UTC they pass without a clock change.
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/health/domain/weight_trend_calculator.dart';

void main() {
  test('a gap across the clock change fills every day once', () {
    final series = WeightTrendCalculator.fromDailyWeights({
      DateTime(2026, 10, 24): 80,
      DateTime(2026, 10, 27): 79,
    });

    expect(series.trendByDay.keys, [
      '2026-10-24',
      '2026-10-25',
      '2026-10-26',
      '2026-10-27',
    ]);
    expect(series.trendFor(DateTime(2026, 10, 25)), closeTo(79.96667, 1e-5));
    expect(series.trendFor(DateTime(2026, 10, 26)), closeTo(79.90333, 1e-5));
    expect(series.trendFor(DateTime(2026, 10, 27)), closeTo(79.813, 1e-5));
  });

  test('weigh-ins on the day of the clock change and the day after', () {
    final series = WeightTrendCalculator.fromDailyWeights({
      DateTime(2026, 10, 25, 9): 80,
      DateTime(2026, 10, 26, 7): 81,
    });

    expect(series.trendByDay.keys, ['2026-10-25', '2026-10-26']);
    expect(series.trendFor(DateTime(2026, 10, 26)), closeTo(80.1, 1e-9));
  });
}
