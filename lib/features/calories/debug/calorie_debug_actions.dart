import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/calories/debug/calorie_debug_action_results.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shows the calorie debug dump result.
void showCalorieDebugDumpResultSnackBar({
  required BuildContext context,
  required CalorieDebugDumpPrintResult result,
}) {
  final l10n = AppLocalizations.of(context)!;
  final (message, tone) = switch (result) {
    CalorieDebugDumpPrintSuccess(:final rowCount) => (
      l10n.caloriesDebugDumpPrinted(rowCount),
      AppSnackBarTone.success,
    ),
    CalorieDebugDumpPrintCanceled() => (
      l10n.caloriesDebugDumpCanceled,
      AppSnackBarTone.info,
    ),
    CalorieDebugDumpPrintFailure() => (
      l10n.caloriesDebugDumpFailed,
      AppSnackBarTone.error,
    ),
  };
  ScaffoldMessenger.of(context).showAppSnackBar(message, tone: tone);
}

/// Shows the calorie settings debug dump result.
void showCalorieSettingsDebugDumpResultSnackBar({
  required BuildContext context,
  required CalorieSettingsDebugDumpPrintResult result,
}) {
  final l10n = AppLocalizations.of(context)!;
  final (message, tone) = switch (result) {
    CalorieSettingsDebugDumpPrintSuccess(:final entryCount) => (
      l10n.caloriesSettingsDebugDumpPrinted(entryCount),
      AppSnackBarTone.success,
    ),
    CalorieSettingsDebugDumpPrintFailure() => (
      l10n.caloriesSettingsDebugDumpFailed,
      AppSnackBarTone.error,
    ),
  };
  ScaffoldMessenger.of(context).showAppSnackBar(message, tone: tone);
}

/// Shows the calorie weekly check-in debug dump result.
void showCalorieWeeklyCheckInDebugDumpResultSnackBar({
  required BuildContext context,
  required CalorieWeeklyCheckInDebugDumpPrintResult result,
}) {
  final l10n = AppLocalizations.of(context)!;
  final (message, tone) = switch (result) {
    CalorieWeeklyCheckInDebugDumpPrintSuccess() => (
      l10n.caloriesWeeklyCheckInDebugDumpPrinted,
      AppSnackBarTone.success,
    ),
    CalorieWeeklyCheckInDebugDumpPrintFailure() => (
      l10n.caloriesWeeklyCheckInDebugDumpFailed,
      AppSnackBarTone.error,
    ),
  };
  ScaffoldMessenger.of(context).showAppSnackBar(message, tone: tone);
}
