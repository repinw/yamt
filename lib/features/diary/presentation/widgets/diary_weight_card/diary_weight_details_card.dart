import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/diary_activity_weight_service.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_card_helpers.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weight_card/diary_weight_actions.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weight_card/diary_weight_details_content.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weight_card/diary_weight_dialog.dart';

Future<bool> _deleteWeight({
  required DiaryWeightActions weightActions,
  required DateTime selectedDay,
  required DiaryWeightDayData weightDay,
}) {
  return weightActions.deleteWeight(
    selectedDay: selectedDay,
    day: weightDay.day,
    hasManualWeight: weightDay.hasManualWeight,
    healthSample: weightDay.healthSample,
  );
}

/// Expanded weight history card.
class DiaryWeightDetailsCard extends ConsumerWidget {
  /// Creates a weight details card.
  const DiaryWeightDetailsCard({
    required this.data,
    required this.selectedDay,
    super.key,
  });

  /// Loaded activity and weight data.
  final DiaryActivityWeightData data;

  /// Selected diary day.
  final DateTime selectedDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalizedSelectedDay = normalizeDiaryDay(selectedDay);
    final days = data.weightDays.reversed.toList(growable: false);
    final selectedWeightDay = data.weightDays.where((weightDay) {
      return isSameDiaryDay(weightDay.day, normalizedSelectedDay);
    }).firstOrNull;
    final weightActions = ref.read(diaryWeightActionsProvider);

    return DiaryDetailCardShell(
      child: DiaryWeightDetailsContent(
        days: days,
        onAdd: () => unawaited(
          showDiaryWeightDialog(
            context: context,
            weightActions: weightActions,
            selectedDay: normalizedSelectedDay,
            day: normalizedSelectedDay,
            initialWeightKg: data.selectedWeightKg,
            hasManualWeight: selectedWeightDay?.hasManualWeight ?? false,
            canClearWeight: selectedWeightDay?.canDeleteWeight ?? false,
            healthSample: selectedWeightDay?.healthSample,
          ),
        ),
        onEdit: (weightDay) => unawaited(
          showDiaryWeightDialog(
            context: context,
            weightActions: weightActions,
            selectedDay: normalizedSelectedDay,
            day: weightDay.day,
            initialWeightKg: weightDay.weightKg,
            hasManualWeight: weightDay.hasManualWeight,
            canClearWeight: weightDay.canDeleteWeight,
            healthSample: weightDay.healthSample,
          ),
        ),
        onDelete: (weightDay) => unawaited(
          _deleteWeight(
            weightActions: weightActions,
            selectedDay: normalizedSelectedDay,
            weightDay: weightDay,
          ),
        ),
      ),
    );
  }
}
