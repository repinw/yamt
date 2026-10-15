import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/activity/application/diary_activity_weight_data_provider.dart';
import 'package:yamt/features/activity/application/diary_weight_actions.dart';
import 'package:yamt/features/activity/domain/diary_activity_weight_models.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/'
    'diary_weight_dialog.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/calorie_goal_reached_flow.dart';

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

  // Static, because callers read a new flow for every tap.
  static bool _isOpening = false;

  /// Opens the weight dialog for [day].
  ///
  /// The dialog offers to delete the weight when [day] has a manual weight
  /// or a Health weight that this app wrote, read from the weight data of
  /// [day]. A second call while that data loads does nothing, so a double
  /// tap opens one dialog.
  Future<void> showDialogForDay({
    required BuildContext context,
    required DateTime selectedDay,
    required DateTime day,
    double? initialWeightKg,
  }) async {
    if (_isOpening) {
      return;
    }
    _isOpening = true;
    final DiaryWeightDayData? weightDay;
    try {
      weightDay = await _loadWeightDay(context, day);
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
      hasManualWeight: weightDay?.hasManualWeight ?? false,
      canClearWeight: weightDay?.canDeleteWeight ?? false,
      healthSample: weightDay?.healthSample,
      onWeightSaved: ({required day, required weightKg}) =>
          handleRecordedWeight(context: context, day: day, weightKg: weightKg),
    );
  }

  /// The weight data of [day], or `null` when it has none or fails to
  /// load; the dialog then only adds a weight.
  Future<DiaryWeightDayData?> _loadWeightDay(
    BuildContext context,
    DateTime day,
  ) async {
    // Through the scope, because callers do not keep this flow's provider
    // alive; the listener keeps the auto-dispose weight data alive until it
    // has loaded.
    final subscription = ProviderScope.containerOf(context, listen: false)
        .listen(
          diaryActivityWeightDataProvider(normalizeDiaryDay(day)).future,
          (_, _) {},
        );
    try {
      final data = await subscription.read();
      return data.weightDays
          .where((weightDay) => isSameDiaryDay(weightDay.day, day))
          .firstOrNull;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to load the weight of the day; the dialog offers no delete.',
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
