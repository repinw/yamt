import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_overview_revision_provider.dart';

part 'diary_entries_provider.g.dart';

/// Provides calorie entries for one normalized diary day.
@riverpod
Stream<List<CalorieEntry>> diaryEntriesForDay(Ref ref, DateTime day) {
  // Trigger stream rebuild when calorie logs mutate through overview revision.
  ref.watch(calorieOverviewRevisionProvider);
  final normalizedDay = normalizeDiaryDay(day);
  return ref
      .watch(calorieLogRepositoryProvider)
      .watchEntriesForDay(
        normalizedDay,
      );
}
