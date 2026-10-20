import 'package:riverpod/riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_goal_archive_provider.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';

part 'progress_scope_controller.g.dart';

/// Which goals the Fortschritt tab shows: the current one, all, or one past
/// goal.
@riverpod
class ProgressScopeController extends _$ProgressScopeController {
  @override
  ProgressScope build() {
    // A changed goal list may no longer hold the picked past goal, so the
    // tab goes back to the current goal.
    ref.listen(
      calorieGoalArchiveProvider.select((goals) => goals.value?.length),
      (_, _) {
        if (state is ProgressPastGoalScope) state = ProgressScope.goal;
      },
    );
    return ProgressScope.goal;
  }

  /// The shown scope.
  ProgressScope get scope => state;

  /// Shows the goals of the given scope.
  set scope(ProgressScope value) => state = value;
}
