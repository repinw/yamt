import 'package:flutter/material.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shows the skipped-intake save failure snack bar.
void showSkippedCalorieIntakeSaveFailedSnackBar(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(l10n.caloriesGoalSaveFailed)));
}
