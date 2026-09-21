import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_sheet.dart';

/// Opens the calculator sheet that ends the active goal and starts a new one.
///
/// Loads the current goal settings itself, so callers need no Calories state.
Future<void> showCalorieNewGoalSheet(
  BuildContext context, {
  double? currentWeightKg,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final settings = await container
      .read(calorieSettingsRepositoryProvider)
      .readSettings();
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
