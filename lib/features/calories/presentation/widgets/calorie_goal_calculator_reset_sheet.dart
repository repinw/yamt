import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_flow.dart';

/// Show the full calorie goal calculator flow.
///
/// Completes with whether the flow saved a goal.
Future<bool> showCalorieGoalCalculatorResetSheet(
  BuildContext context, {
  required CalorieGoalSettings initialSettings,
  bool useRootNavigator = true,
  bool startsNewGoal = false,
  bool showBackButton = false,
}) async {
  Future<bool>? pendingSave;
  final saved = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: useRootNavigator,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return CalorieGoalCalculatorFlow(
        initialSettings: initialSettings,
        startsNewGoal: startsNewGoal,
        showBackButton: showBackButton,
        onSaveStarted: (save) => pendingSave = save,
      );
    },
  );
  // A sheet swiped away while it saves still reports the save.
  return saved ?? await pendingSave ?? false;
}
