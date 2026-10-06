import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';

part 'calorie_entry_deleter.g.dart';

/// Deletes a calorie entry through the Calories application boundary.
typedef CalorieEntryDeleter = Future<bool> Function(String entryId);

/// Provides calorie-entry deletion without exposing the Calories controller.
@riverpod
CalorieEntryDeleter calorieEntryDeleter(Ref ref) {
  final repository = ref.watch(calorieLogRepositoryProvider);
  final overviewRevision = ref.read(calorieOverviewRevisionProvider.notifier);
  return (entryId) async {
    final deleted = await repository.deleteEntry(entryId);
    if (!deleted) {
      return false;
    }
    overviewRevision.markChanged();
    return true;
  };
}
