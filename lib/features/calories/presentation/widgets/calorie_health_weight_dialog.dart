import 'package:flutter/material.dart';
import 'package:yamt/core/widgets/weight_entry_dialog.dart';
import 'package:yamt/features/calories/presentation/calorie_health_trends_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Show calorie health weight dialog.
Future<void> showCalorieHealthWeightDialog({
  required BuildContext context,
  required String dayLabel,
  required double? initialWeightKg,
  required bool hasManualWeight,
  required Future<bool> Function(double weightKg) onSaveWeight,
  required Future<bool> Function() onClearWeight,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showWeightEntryDialog(
    context: context,
    labels: WeightEntryDialogLabels(
      title: l10n.caloriesHealthTrendsWeightDialogTitle(dayLabel),
      fieldLabel: l10n.caloriesCalculatorWeightLabel,
      emptyErrorText: l10n.caloriesCalculatorWeightEmpty,
      invalidErrorText: l10n.caloriesCalculatorWeightInvalid,
      clearActionLabel: l10n.caloriesHealthTrendsWeightClearAction,
      cancelActionLabel: l10n.inventoryReceiptReviewCancelAction,
      saveActionLabel: l10n.caloriesHealthTrendsWeightSaveAction,
    ),
    keys: const WeightEntryDialogKeys(
      fieldKey: CalorieHealthTrendsKeys.weightDialogField,
      clearButtonKey: CalorieHealthTrendsKeys.weightDialogClearButton,
      saveButtonKey: CalorieHealthTrendsKeys.weightDialogSaveButton,
    ),
    initialWeightKg: initialWeightKg,
    showClearAction: hasManualWeight,
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
          SnackBar(content: Text(l10n.caloriesHealthTrendsWeightSaveFailed)),
        );
      }
    case WeightEntryDialogAction.clear:
      final cleared = await onClearWeight();
      if (context.mounted && !cleared) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.caloriesHealthTrendsWeightClearFailed)),
        );
      }
  }
}
