import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_scroll_wheel.dart';
import 'package:yamt/core/widgets/app_wheel_selection_band.dart';
import 'package:yamt/features/calories/domain/calorie_goal_pace.dart';

/// Wheel that picks the goal pace with the onboarding's range and steps.
class CalorieGoalPaceWheel extends StatelessWidget {
  /// Creates the pace wheel.
  const new({
    required this.paceKgPerWeek,
    required this.unit,
    required this.onChanged,
    super.key,
  });

  /// Pace the wheel shows, in kilograms per week.
  final double paceKgPerWeek;

  /// Unit shown next to every value.
  final String unit;

  /// Called with the picked pace, formatted with two decimals.
  final ValueChanged<String> onChanged;

  static final int _itemCount =
      ((maximumGoalPaceKgPerWeek - minimumGoalPaceKgPerWeek) /
              goalPaceStepKgPerWeek)
          .round() +
      1;

  static double _valueAt(int index) =>
      minimumGoalPaceKgPerWeek + index * goalPaceStepKgPerWeek;

  @override
  Widget build(BuildContext context) {
    final index =
        ((paceKgPerWeek - minimumGoalPaceKgPerWeek) / goalPaceStepKgPerWeek)
            .round()
            .clamp(0, _itemCount - 1);
    return AppWheelSelectionBand(
      child: AppScrollWheel(
        itemCount: _itemCount,
        selectedIndex: index,
        labelBuilder: (index) => '${_valueAt(index).toStringAsFixed(2)} $unit',
        onSelected: (index) => onChanged(_valueAt(index).toStringAsFixed(2)),
      ),
    );
  }
}
