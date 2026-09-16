import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry_mutation.dart';
import 'package:yamt/features/calories/provider/calorie_entry_mutations.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_overview_revision_provider.dart';

part 'calorie_entry_deleter.g.dart';

/// Deletes a calorie entry through the Calories application boundary.
typedef CalorieEntryDeleter = Future<bool> Function(String entryId);

/// Provides calorie-entry deletion without exposing the Calories controller.
@riverpod
CalorieEntryDeleter calorieEntryDeleter(Ref ref) {
  final repository = ref.watch(calorieLogRepositoryProvider);
  final mutations = ref.watch(calorieEntryMutationsProvider);
  final overviewRevision = ref.read(calorieOverviewRevisionProvider.notifier);
  return (entryId) async {
    final deleted = await repository.deleteEntry(entryId);
    if (!deleted) {
      return false;
    }
    overviewRevision.markChanged();
    mutations.record(
      CalorieEntryMutation(
        kind: CalorieEntryMutationKind.deleted,
        entryId: entryId,
      ),
    );
    return true;
  };
}
