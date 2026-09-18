import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_state.dart';

/// Everything the intro input pages share: chapter styling and the form.
@immutable
class IntroInputPageArgs {
  /// Creates intro input page arguments.
  const new({
    required this.kicker,
    required this.accent,
    required this.state,
    required this.notifier,
    this.showErrors = false,
  });

  /// Kicker above the headline.
  final String kicker;

  /// Accent color of this chapter.
  final Color accent;

  /// Current calculator form state.
  final CalorieGoalCalculatorFormState state;

  /// Calculator form notifier.
  final CalorieGoalCalculatorFormController notifier;

  /// Whether validation errors should be shown.
  final bool showErrors;
}
