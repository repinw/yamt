import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';

void main() {
  test('dynamic calorie page keys generate stable values', () {
    expect(
      CaloriesPageKeys.entryImage('entry-1'),
      const Key('calories_entry_image_entry-1'),
    );
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
    expect(
      CalorieEntryDetailKeys.ingredientNameCell(2),
      const Key('calorie_entry_detail_ingredient_name_2'),
    );
    expect(
      CalorieEntryDetailKeys.ingredientAmountCell(2),
      const Key('calorie_entry_detail_ingredient_amount_2'),
    );
    expect(
      CalorieEntryDetailKeys.ingredientKcalCell(2),
      const Key('calorie_entry_detail_ingredient_kcal_2'),
    );
  });
}
