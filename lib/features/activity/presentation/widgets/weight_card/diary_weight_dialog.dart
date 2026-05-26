import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/widgets/weight_entry_dialog.dart';
import 'package:yamt/features/activity/application/diary_weight_actions.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_dialog_keys.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/l10n/app_localizations.dart';

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
  final l10n = AppLocalizations.of(context)!;

  return _showDiaryWeightEntryDialog(
    context: context,
    l10n: l10n,
    dayLabel: dayLabel,
    initialWeightKg: initialWeightKg,
    showClearAction: canClearWeight,
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

Future<void> _showDiaryWeightEntryDialog({
  required BuildContext context,
  required AppLocalizations l10n,
  required String dayLabel,
  required double? initialWeightKg,
  required bool showClearAction,
  required Future<bool> Function(double weightKg) onSaveWeight,
  required Future<bool> Function() onClearWeight,
}) async {
  final result = await showWeightEntryDialog(
    context: context,
    labels: WeightEntryDialogLabels(
      title: l10n.diaryWeightDialogTitle(dayLabel),
      fieldLabel: l10n.caloriesCalculatorWeightLabel,
      emptyErrorText: l10n.caloriesCalculatorWeightEmpty,
      invalidErrorText: l10n.caloriesCalculatorWeightInvalid,
      clearActionLabel: l10n.diaryWeightClearAction,
      cancelActionLabel: l10n.inventoryReceiptReviewCancelAction,
      saveActionLabel: l10n.diaryWeightSaveAction,
    ),
    keys: const WeightEntryDialogKeys(
      fieldKey: DiaryWeightDialogKeys.weightDialogField,
      clearButtonKey: DiaryWeightDialogKeys.weightDialogClearButton,
      saveButtonKey: DiaryWeightDialogKeys.weightDialogSaveButton,
    ),
    initialWeightKg: initialWeightKg,
    showClearAction: showClearAction,
  );
  if (!context.mounted || result == null) {
    return;
  }

  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  switch (result.action) {
    case WeightEntryDialogAction.save:
      final weightKg = result.weightKg;
      if (weightKg == null) {
        return;
      }
      final saved = await onSaveWeight(weightKg);
      if (context.mounted && !saved) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.diaryWeightSaveFailed)),
        );
      }
    case WeightEntryDialogAction.clear:
      final cleared = await onClearWeight();
      if (context.mounted && !cleared) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.diaryWeightClearFailed)),
        );
      }
  }
}
