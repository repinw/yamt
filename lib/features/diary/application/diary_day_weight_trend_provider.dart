import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/application/diary_today_provider.dart';
import 'package:yamt/features/health/application/weight_series_provider.dart';
import 'package:yamt/features/health/domain/recent_weight_trend.dart';

part 'diary_day_weight_trend_provider.g.dart';

/// The weights of the recent days that end on the diary [day], from manual
/// entries and the Health samples of all devices.
///
/// A future day shows the trend of today.
@riverpod
Future<RecentWeightTrend> diaryDayWeightTrend(Ref ref, DateTime day) async {
  final today = ref.watch(diaryTodayProvider);
  final normalizedDay = normalizeLocalDay(day);
  return RecentWeightTrend.fromSeries(
    await ref.watch(weightSeriesProvider.future),
    today: normalizedDay.isAfter(today) ? today : normalizedDay,
  );
}
