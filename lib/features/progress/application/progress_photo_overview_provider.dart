import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/application/recent_weight_trend_provider.dart';
import 'package:yamt/features/health/data/progress_photo_repository.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/features/progress/domain/progress_photo_overview.dart';

part 'progress_photo_overview_provider.g.dart';

/// The progress photos of [scope]: the current goal from its start on, or
/// all photos, also those from before the first goal.
@riverpod
Future<ProgressPhotoOverview> progressPhotoOverview(
  Ref ref,
  ProgressScope scope,
) async {
  final today = normalizeDiaryDay(ref.watch(clockProvider)());
  final photosFuture = ref.watch(progressPhotosProvider.future);
  final settings = await ref.watch(calorieGoalControllerProvider.future);
  final allPhotos = await photosFuture;
  final period = ProgressPeriod.of(
    settings: settings,
    scope: scope,
    today: today,
  );
  final photos = switch (scope) {
    ProgressScope.goal =>
      allPhotos.where((photo) => !photo.day.isBefore(period.start)).toList(),
    ProgressScope.all => allPhotos,
  };
  final oldest = photos.firstOrNull?.day ?? today;
  // shortcut: older photos show only their typed weight; raise the cap if
  // users miss the trend weight on old photos.
  final dayCount = (diaryDaysBetween(oldest, today) + 1).clamp(
    1,
    _maxTrendDays,
  );
  final trend = await ref.watch(
    recentWeightTrendProvider(dayCount: dayCount).future,
  );
  return ProgressPhotoOverview(
    photos: List.unmodifiable(photos),
    goalStarts: ProgressPeriod.of(
      settings: settings,
      scope: ProgressScope.all,
      today: today,
    ).goalStarts,
    dayWeightsKg: {for (final day in trend.days) day.day: ?day.trendWeightKg},
  );
}

/// Most days of weight history loaded for the photo weights.
const _maxTrendDays = 400;
