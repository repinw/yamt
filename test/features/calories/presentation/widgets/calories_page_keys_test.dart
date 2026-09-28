import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_keys.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';

void main() {
  test('dynamic calorie page keys generate stable values', () {
    expect(
      CaloriesPageKeys.summaryMacroCard('protein'),
      const Key('calories_summary_macro_card_protein'),
    );
    expect(
      CaloriesPageKeys.summaryMacroValue('protein'),
      const Key('calories_summary_macro_value_protein'),
    );
    expect(
      CaloriesPageKeys.summaryMacroBar('protein'),
      const Key('calories_summary_macro_bar_protein'),
    );
    expect(
      CalorieGoalCalculatorSheetKeys.activityLevelOption('high'),
      const Key('calorie_calculator_activity_level_option_high'),
    );
  });
}
