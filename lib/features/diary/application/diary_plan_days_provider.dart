import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/diary/domain/diary_calendar_bounds.dart';

part 'diary_plan_days_provider.g.dart';

/// The days within [bounds] that hold open plans, for the calendar dots.
///
/// Accepting a plan deletes it, so every plan read here is still open.
@riverpod
Future<Set<DateTime>> diaryPlanDays(Ref ref, DiaryCalendarBounds bounds) {
  // Plan writes bump the revision.
  ref.watch(calorieOverviewRevisionProvider);
  return ref
      .watch(plannedEntryRepositoryProvider)
      .loadPlannedDays(bounds.earliestDay, bounds.latestDay);
}
