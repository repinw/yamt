import 'package:material_ui/material_ui.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shows skipped-intake save failure.
void showSkippedCalorieIntakeSaveFailedSnackBar(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(l10n.caloriesGoalSaveFailed)));
}
