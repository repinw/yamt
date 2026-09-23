import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shows the skipped-intake save failure snack bar.
void showSkippedCalorieIntakeSaveFailedSnackBar(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(
    context,
  ).showAppSnackBar(l10n.caloriesGoalSaveFailed, tone: AppSnackBarTone.error);
}
