import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/activity/application/diary_weight_actions.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/'
    'diary_weight_dialog.dart';
import 'package:yamt/features/calories/presentation/calorie_goal_reached_flow.dart';
import 'package:yamt/features/health/application/weight_series_provider.dart';

part 'diary_weight_tracking_flow.g.dart';

/// Provides the Activity-owned diary weight tracking flow.
@riverpod
DiaryWeightTrackingFlow diaryWeightTrackingFlow(Ref ref) {
  return DiaryWeightTrackingFlow(
    weightActions: ref.watch(diaryWeightActionsProvider),
    onWeightRecorded: ref
        .watch(calorieGoalReachedFlowProvider)
        .handleRecordedWeight,
  );
}

/// Activity-owned flow for adding diary weights.
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

  // Static, because callers read a new flow for every tap.
  static bool _isOpening = false;

  /// Opens the weight dialog, which adds a weighing of [day], filled with
  /// the newest weighing. A second call while that weighing loads does
  /// nothing, so a double tap opens one dialog.
  Future<void> showDialogForDay({
    required BuildContext context,
    required DateTime selectedDay,
    required DateTime day,
  }) async {
    if (_isOpening) {
      return;
    }
    _isOpening = true;
    final double? initialWeightKg;
    try {
      initialWeightKg = await _loadLatestWeighingKg(context);
    } finally {
      _isOpening = false;
    }
    if (!context.mounted) {
      return;
    }
    await showDiaryWeightDialog(
      context: context,
      weightActions: _weightActions,
      selectedDay: selectedDay,
      day: day,
      initialWeightKg: initialWeightKg,
      onWeightSaved: ({required day, required weightKg}) =>
          handleRecordedWeight(context: context, day: day, weightKg: weightKg),
    );
  }

  /// The newest weighing, or `null` when there is none or it fails to load;
  /// the field then starts empty.
  Future<double?> _loadLatestWeighingKg(BuildContext context) async {
    // Through the scope, because callers do not keep this flow's provider
    // alive; the listener keeps the auto-dispose weighing alive until it has
    // loaded.
    final subscription = ProviderScope.containerOf(
      context,
      listen: false,
    ).listen(latestWeighingKgProvider.future, (_, _) {});
    try {
      return await subscription.read();
    } on Object catch (error, stackTrace) {
      log(
        'Failed to load the newest weighing; the field starts empty.',
        name: 'DiaryWeightTrackingFlow',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    } finally {
      subscription.close();
    }
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
