import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/calories/presentation/widgets/calorie_health_weight_dialog.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weight_card/diary_weight_actions.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';

/// Shows the diary weight dialog.
Future<void> showDiaryWeightDialog({
  required BuildContext context,
  required DiaryWeightActions weightActions,
  required DateTime selectedDay,
  required DateTime day,
  required double? initialWeightKg,
  required bool hasManualWeight,
  required bool canClearWeight,
  required HealthWeightSample? healthSample,
}) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final dayLabel = DateFormat.yMMMd(locale).format(day);

  return showCalorieHealthWeightDialog(
    context: context,
    dayLabel: dayLabel,
    initialWeightKg: initialWeightKg,
    hasManualWeight: canClearWeight,
    onSaveWeight: (weightKg) async {
      return weightActions.saveManualWeight(
        selectedDay: selectedDay,
        day: day,
        weightKg: weightKg,
      );
    },
    onClearWeight: () async {
      return weightActions.deleteWeight(
        selectedDay: selectedDay,
        day: day,
        hasManualWeight: hasManualWeight,
        healthSample: healthSample,
      );
    },
  );
}
