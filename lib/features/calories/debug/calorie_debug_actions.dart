import 'package:flutter/material.dart';
import 'package:yamt/features/calories/debug/calorie_debug_action_controller.dart';
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

/// Shows the calorie settings debug dump result.
void showCalorieSettingsDebugDumpResultSnackBar({
  required BuildContext context,
  required CalorieSettingsDebugDumpPrintResult result,
}) {
  final message = switch (result) {
    CalorieSettingsDebugDumpPrintSuccess(:final entryCount) =>
      'Printed calorie settings debug dump ($entryCount goal entries).',
    CalorieSettingsDebugDumpPrintFailure() =>
      'Could not print calorie settings debug dump.',
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Shows the calorie weekly check-in debug dump result.
void showCalorieWeeklyCheckInDebugDumpResultSnackBar({
  required BuildContext context,
  required CalorieWeeklyCheckInDebugDumpPrintResult result,
}) {
  final message = switch (result) {
    CalorieWeeklyCheckInDebugDumpPrintSuccess() =>
      'Printed weekly check-in debug dump.',
    CalorieWeeklyCheckInDebugDumpPrintFailure() =>
      'Could not print weekly check-in debug dump.',
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
