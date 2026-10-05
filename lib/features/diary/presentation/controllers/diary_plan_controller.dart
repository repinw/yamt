import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';

part 'diary_plan_controller.g.dart';

/// Deletes plans from the diary and brings them back on undo.
@riverpod
class DiaryPlanController extends _$DiaryPlanController {
  @override
  FutureOr<void> build() {}

  /// Deletes [plan]. Returns false when it failed.
  Future<bool> delete(CalorieEntry plan) =>
      _write((repository) => repository.deletePlannedEntry(plan.id));

  /// Saves [plan] again after a delete. Returns false when it failed.
  Future<bool> restore(CalorieEntry plan) =>
      _write((repository) => repository.savePlannedEntry(plan));

  Future<bool> _write(
    Future<void> Function(PlannedEntryRepository repository) write,
  ) async {
    final repository = ref.read(plannedEntryRepositoryProvider);
    // The diary dashboards learn about the change from the revision.
    final revision = ref.read(calorieOverviewRevisionProvider.notifier);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => write(repository));
    if (!result.hasError) {
      revision.markChanged();
    }
    if (ref.mounted) {
      state = result;
    }
    return !result.hasError;
  }
}
