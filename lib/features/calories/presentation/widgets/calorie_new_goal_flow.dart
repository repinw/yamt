import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the calculator sheet that ends the active goal and starts a new one.
///
/// Loads the current goal settings itself, so callers need no Calories state.
/// When they cannot load, it shows an error instead of the sheet.
Future<void> showCalorieNewGoalSheet(
  BuildContext context, {
  double? currentWeightKg,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final messenger = ScaffoldMessenger.of(context);
  final failureMessage = AppLocalizations.of(context)!.calorieGoalLoadFailed;
  // Keeps the auto-dispose goal controller alive for the read.
  final subscription = container.listen(
    calorieGoalControllerProvider,
    (previous, next) {},
  );
  final CalorieGoalSettings settings;
  try {
    settings = await container
        .read(calorieGoalControllerProvider.notifier)
        .currentSettings();
  } on Object catch (error, stackTrace) {
    log(
      'Failed to load calorie settings for a new goal.',
      name: 'CalorieNewGoalFlow',
      error: error,
      stackTrace: stackTrace,
    );
    messenger.showAppSnackBar(failureMessage, tone: AppSnackBarTone.error);
    return;
  } finally {
    subscription.close();
  }
  if (!context.mounted) {
    return;
  }
  await showCalorieGoalCalculatorSheet(
    context,
    initialSettings: settings,
    startsNewGoal: true,
    currentWeightKg: currentWeightKg,
  );
}
