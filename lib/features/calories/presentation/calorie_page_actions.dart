import 'package:flutter/material.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_page_action_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shows the calorie debug dump result.
void showCalorieDebugDumpResultSnackBar({
  required BuildContext context,
  required CalorieDebugDumpPrintResult result,
}) {
  final l10n = AppLocalizations.of(context)!;
  final message = switch (result) {
    CalorieDebugDumpPrintSuccess(:final rowCount) =>
      l10n.caloriesDebugDumpPrinted(rowCount),
    CalorieDebugDumpPrintFailure() => l10n.caloriesDebugDumpFailed,
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Shows skipped-intake save failure.
void showSkippedCalorieIntakeSaveFailedSnackBar(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(l10n.caloriesGoalSaveFailed)));
}
