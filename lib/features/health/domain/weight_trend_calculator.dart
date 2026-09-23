import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

/// Raw daily weights and the smoothed trend weight derived from them.
class DailyWeightSeries {
  /// Creates a daily weight series.
  const new({
    required this.rawByDay,
    required this.trendByDay,
    required this.lastDay,
  });

  /// A series without any weigh-in.
  static const empty = DailyWeightSeries(
    rawByDay: <String, double>{},
    trendByDay: <String, double>{},
    lastDay: null,
  );

  /// One measured weight per day, keyed by `localDayKey`.
  final Map<String, double> rawByDay;

  /// Estimated real weight per day, keyed by `localDayKey`.
  ///
  /// Every day from the first to the last weigh-in has a value.
  final Map<String, double> trendByDay;

  /// Day of the last weigh-in.
  final DateTime? lastDay;

  /// Trend weight for [day], when it lies between two weigh-ins.
  double? trendFor(DateTime day) => trendByDay[localDayKey(day)];

  /// Trend slope in kg per day over the [windowDays] days up to [endDay].
  ///
  /// [endDay] defaults to the last weigh-in. Returns `null` when fewer than
  /// two trend values lie in that range.
  double? slopeKgPerDay({
    DateTime? endDay,
    int windowDays = WeightTrendCalculator.slopeWindowDays,
  }) {
    final end = endDay ?? lastDay;
    if (end == null) {
      return null;
    }
    final points = <({double x, double y})>[
      for (var offset = windowDays - 1; offset >= 0; offset--)
        if (trendFor(addLocalDays(end, -offset)) case final weight?)
          (x: -offset.toDouble(), y: weight),
    ];
    if (points.length < 2) {
      return null;
    }
    return WeightTrendCalculator.linearSlope(points);
  }
}

/// Builds an estimated real weight that ignores day-to-day water swings.
///
/// Days between two weigh-ins get a linearly interpolated weight. The daily
/// weights then feed an exponential moving average, so one high or low
/// weigh-in moves the trend by only [smoothing] of its difference.
abstract final class WeightTrendCalculator {
  /// Share of each day's weight that enters the trend.
  static const double smoothing = 0.1;

  /// Days of weight history to load before the first day a chart needs, so
  /// the trend is settled when that day starts.
  static const int warmUpDays = 60;

  /// Default number of days used for the trend slope.
  static const int slopeWindowDays = 14;

  /// Builds the series from manual entries and Health samples.
  ///
  /// A manual entry wins over Health samples on the same day. Several Health
  /// samples on one day count as their median.
  static DailyWeightSeries fromSources({
    List<ManualHealthWeightEntry> manualEntries =
        const <ManualHealthWeightEntry>[],
    List<HealthWeightSample> healthSamples = const <HealthWeightSample>[],
  }) {
    final samplesByDay = <DateTime, List<double>>{};
    for (final sample in healthSamples) {
      samplesByDay
          .putIfAbsent(normalizeLocalDay(sample.recordedAt), () => <double>[])
          .add(sample.weightKg);
    }
    return fromDailyWeights(<DateTime, double>{
      for (final entry in samplesByDay.entries) entry.key: _median(entry.value),
      for (final entry in manualEntries)
        normalizeLocalDay(entry.day): entry.weightKg,
    });
  }

  /// Builds the series from one measured weight per day.
  static DailyWeightSeries fromDailyWeights(Map<DateTime, double> weights) {
    if (weights.isEmpty) {
      return DailyWeightSeries.empty;
    }
    final weighIns = <({DateTime day, double weight})>[
      for (final entry in weights.entries)
        (day: normalizeLocalDay(entry.key), weight: entry.value),
    ]..sort((left, right) => left.day.compareTo(right.day));

    final trendByDay = <String, double>{};
    var trend = weighIns.first.weight;
    trendByDay[localDayKey(weighIns.first.day)] = trend;
    for (var index = 1; index < weighIns.length; index++) {
      final previous = weighIns[index - 1];
      final next = weighIns[index];
      final gapDays = _dayCount(previous.day, next.day);
      var day = previous.day;
      for (var step = 1; step <= gapDays; step++) {
        day = nextLocalDay(day);
        final input =
            previous.weight + (next.weight - previous.weight) * step / gapDays;
        trend += smoothing * (input - trend);
        trendByDay[localDayKey(day)] = trend;
      }
    }

    return DailyWeightSeries(
      rawByDay: <String, double>{
        for (final weighIn in weighIns)
          localDayKey(weighIn.day): weighIn.weight,
      },
      trendByDay: trendByDay,
      lastDay: weighIns.last.day,
    );
  }

  /// Least-squares slope of [points], or zero when all x values are equal.
  static double linearSlope(List<({double x, double y})> points) {
    final count = points.length;
    var sumX = 0.0;
    var sumY = 0.0;
    var sumXY = 0.0;
    var sumX2 = 0.0;
    for (final point in points) {
      sumX += point.x;
      sumY += point.y;
      sumXY += point.x * point.y;
      sumX2 += point.x * point.x;
    }
    final denominator = (count * sumX2) - (sumX * sumX);
    if (denominator == 0) {
      return 0;
    }
    return ((count * sumXY) - (sumX * sumY)) / denominator;
  }

  static int _dayCount(DateTime from, DateTime to) {
    var count = 0;
    for (var day = from; day.isBefore(to); day = nextLocalDay(day)) {
      count++;
    }
    return count;
  }

  static double _median(List<double> values) {
    final sorted = List<double>.of(values)..sort();
    final middle = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[middle]
        : (sorted[middle - 1] + sorted[middle]) / 2;
  }
}
