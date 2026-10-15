import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/health/application/weight_series_provider.dart';
import 'package:yamt/features/health/domain/recent_weight_trend.dart';

part 'recent_weight_trend_provider.g.dart';

/// The weights of the last [dayCount] days from manual entries and the
/// Health samples of all devices.
@riverpod
Future<RecentWeightTrend> recentWeightTrend(
  Ref ref, {
  int dayCount = RecentWeightTrend.chartDayCount,
}) async {
  final today = normalizeLocalDay(ref.watch(clockProvider)());
  return RecentWeightTrend.fromSeries(
    await ref.watch(weightSeriesProvider.future),
    today: today,
    dayCount: dayCount,
  );
}
