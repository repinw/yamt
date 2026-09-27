import 'package:meta/meta.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/health/domain/weight_trend_calculator.dart';

/// One day of the recent weight chart.
@immutable
class RecentWeightDay {
  /// Creates one chart day.
  const new({required this.day, this.weightKg, this.trendWeightKg});

  /// The local day.
  final DateTime day;

  /// The measured weight of the day, or `null` without a weigh-in.
  final double? weightKg;

  /// The trend weight of the day, or `null` before the first weigh-in.
  final double? trendWeightKg;
}

/// The weights of the last days: measured weigh-ins, the trend weight, and
/// how fast the trend moves.
@immutable
class RecentWeightTrend {
  /// Creates a recent weight trend.
  const new({
    required this.days,
    required this.latestWeighInKg,
    required this.latestWeighInDay,
    required this.trendWeightKg,
    required this.trendKgPerWeek,
  });

  /// Builds the trend of the [dayCount] days up to [today] from [series].
  factory fromSeries(
    DailyWeightSeries series, {
    required DateTime today,
    int dayCount = chartDayCount,
  }) {
    final lastDay = series.lastDay;
    final slope = series.slopeKgPerDay();
    return RecentWeightTrend(
      days: List<RecentWeightDay>.unmodifiable([
        for (var offset = dayCount - 1; offset >= 0; offset--)
          if (addLocalDays(today, -offset) case final day)
            RecentWeightDay(
              day: day,
              weightKg: series.rawByDay[localDayKey(day)],
              trendWeightKg: series.trendFor(day),
            ),
      ]),
      latestWeighInKg: lastDay == null
          ? null
          : series.rawByDay[localDayKey(lastDay)],
      latestWeighInDay: lastDay,
      trendWeightKg: series.trendOnOrBefore(today),
      trendKgPerWeek: slope == null ? null : slope * DateTime.daysPerWeek,
    );
  }

  /// Number of days the profile chart shows.
  static const chartDayCount = 14;

  /// One entry per day, oldest first, ending today.
  final List<RecentWeightDay> days;

  /// The last measured weight.
  final double? latestWeighInKg;

  /// The day of [latestWeighInKg].
  final DateTime? latestWeighInDay;

  /// The trend weight today, or on the last weigh-in before today.
  final double? trendWeightKg;

  /// How fast the trend weight changes, in kg per week.
  final double? trendKgPerWeek;
}
