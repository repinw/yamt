import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/activity/application/diary_weight_actions.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/'
    'diary_weight_dialog.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';

part 'diary_weight_tracking_flow.g.dart';

/// Provides the Activity-owned diary weight tracking flow.
@riverpod
DiaryWeightTrackingFlow diaryWeightTrackingFlow(Ref ref) {
  return DiaryWeightTrackingFlow(
    weightActions: ref.watch(diaryWeightActionsProvider),
  );
}

/// Activity-owned flow for adding or editing diary weights.
class DiaryWeightTrackingFlow {
  /// Creates the diary weight tracking flow.
  const DiaryWeightTrackingFlow({
    required DiaryWeightActions weightActions,
  }) : _weightActions = weightActions;

  final DiaryWeightActions _weightActions;

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
    );
  }
}
