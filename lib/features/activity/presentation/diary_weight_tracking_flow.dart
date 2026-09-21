import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/activity/application/diary_weight_actions.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/'
    'diary_weight_dialog.dart';
import 'package:yamt/features/calories/presentation/'
    'calorie_goal_reach_coordinator.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';

part 'diary_weight_tracking_flow.g.dart';

/// Provides the Activity-owned diary weight tracking flow.
@riverpod
DiaryWeightTrackingFlow diaryWeightTrackingFlow(Ref ref) {
  return DiaryWeightTrackingFlow(
    weightActions: ref.watch(diaryWeightActionsProvider),
    onWeightRecorded: ref
        .watch(calorieGoalReachCoordinatorProvider)
        .handleRecordedWeight,
  );
}

/// Activity-owned flow for adding or editing diary weights.
class DiaryWeightTrackingFlow {
  /// Creates the diary weight tracking flow.
  const new({required this._weightActions, required this._onWeightRecorded});

  final DiaryWeightActions _weightActions;
  final Future<void> Function({
    required BuildContext context,
    required DateTime day,
    required double weightKg,
  })
  _onWeightRecorded;

  /// Opens the weight dialog for [day].
  Future<void> showDialogForDay({
    required BuildContext context,
    required DateTime selectedDay,
    required DateTime day,
    double? initialWeightKg,
    bool hasManualWeight = false,
    bool canClearWeight = false,
    HealthWeightSample? healthSample,
  }) {
    return showDiaryWeightDialog(
      context: context,
      weightActions: _weightActions,
      selectedDay: selectedDay,
      day: day,
      initialWeightKg: initialWeightKg,
      hasManualWeight: hasManualWeight,
      canClearWeight: canClearWeight,
      healthSample: healthSample,
      onWeightSaved: ({required day, required weightKg}) =>
          handleRecordedWeight(context: context, day: day, weightKg: weightKg),
    );
  }

  /// Detects a newly reached goal for manual or synchronized weight data and
  /// offers to continue the run or start a new goal.
  Future<void> handleRecordedWeight({
    required BuildContext context,
    required DateTime day,
    required double weightKg,
  }) {
    return _onWeightRecorded(context: context, day: day, weightKg: weightKg);
  }
}
