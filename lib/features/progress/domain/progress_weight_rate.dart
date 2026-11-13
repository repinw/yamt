import 'package:meta/meta.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/health/domain/weight_trend_calculator.dart';

/// Fewest days a weekly rate covers; over fewer days the trend weight still
/// follows single weigh-ins too closely.
const int progressMinRateDays = 7;

/// How fast the trend weight changed on average over a period.
@immutable
class ProgressWeightRate {
  /// Creates a rate.
  const new({
    required this.since,
    required this.until,
    required this.kgPerWeek,
  });

  /// The average change of the trend weight of [series] per week from
  /// [start] to [end].
  ///
  /// It counts from the trend of the day before [start], or from the first
  /// weigh-in in the period without one, up to [end] or the last weigh-in
  /// before it. Returns `null` when that covers fewer than
  /// [progressMinRateDays] days.
  static ProgressWeightRate? of(
    DailyWeightSeries series, {
    required DateTime start,
    required DateTime end,
  }) {
    final lastDay = series.lastDay;
    if (lastDay == null) return null;
    final until = lastDay.isBefore(end) ? lastDay : end;
    final toKg = series.trendFor(until);
    if (toKg == null) return null;

    var since = start;
    var from = addLocalDays(start, -1);
    var fromKg = series.trendFor(from);
    while (fromKg == null && from.isBefore(until)) {
      from = nextLocalDay(from);
      since = from;
      fromKg = series.trendFor(from);
    }
    final days = localDaysBetween(from, until);
    if (fromKg == null || days < progressMinRateDays) return null;
    return ProgressWeightRate(
      since: since,
      until: until,
      kgPerWeek: (toKg - fromKg) / days * DateTime.daysPerWeek,
    );
  }

  /// First day the rate covers: the start of the period, or the first
  /// weigh-in in it.
  final DateTime since;

  /// Last day the rate covers: the end of the period, or the last weigh-in
  /// before it.
  final DateTime until;

  /// Average change of the trend weight in kg per week.
  final double kgPerWeek;
}
