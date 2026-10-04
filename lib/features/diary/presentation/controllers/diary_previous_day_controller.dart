import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/data/closed_day_repository.dart';

part 'diary_previous_day_controller.g.dart';

/// Closes or reopens the day before a planned day, so the planned day counts
/// like a started day with its carryover.
@riverpod
class DiaryPreviousDayController extends _$DiaryPreviousDayController {
  @override
  FutureOr<void> build() {}

  /// Closes [day]. Returns false when the device did not save it.
  Future<bool> close(DateTime day) =>
      _save((repository) => repository.saveClosedDay(day));

  /// Opens the closed day again. Returns false when the device did not save
  /// it.
  Future<bool> reopen() => _save((repository) => repository.deleteClosedDay());

  Future<bool> _save(
    Future<void> Function(ClosedDayRepository repository) write,
  ) async {
    final repository = ref.read(closedDayRepositoryProvider);
    // Closing changes budgets without a calorie log, so the overviews and the
    // diary dashboards learn it from the revision.
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
