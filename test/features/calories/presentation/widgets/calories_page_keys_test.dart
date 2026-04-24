import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';

void main() {
  test('dynamic calorie page keys generate stable values', () {
    expect(
      CaloriesPageKeys.summaryActivityHint,
      const Key('calories_summary_activity_hint'),
    );
    expect(
      CaloriesPageKeys.diaryList,
      const Key('calories_diary_list'),
    );
    expect(
      CaloriesPageKeys.sectionCard('breakfast'),
      const Key('calories_section_card_breakfast'),
    );
    expect(
      CaloriesPageKeys.entryTile('entry-1'),
      const Key('calories_entry_tile_entry-1'),
    );
    expect(
      CaloriesPageKeys.entryImage('entry-1'),
      const Key('calories_entry_image_entry-1'),
    );
    expect(
      CaloriesPageKeys.bundleComponentImage('entry-1', 2),
      const Key('calories_bundle_component_image_entry-1_2'),
    );
    expect(
      CaloriesPageKeys.sectionAddButton('dinner'),
      const Key('calories_section_add_dinner'),
    );
    expect(
      CaloriesPageKeys.summaryModeOption('classic'),
      const Key('calories_summary_mode_classic'),
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
      CaloriesPageKeys.burnWeekMockOpenButton,
      const Key('calories_burn_week_open_button'),
    );
    expect(
      CaloriesPageKeys.calorieDebugDumpButton,
      const Key('calories_debug_dump_button'),
    );
    expect(
      CaloriesPageKeys.burnWeekMockQuickAction('+500'),
      const Key('calories_burn_week_quick_action_+500'),
    );
    expect(
      CaloriesPageKeys.weekBalanceDayColumn('2026-04-16'),
      const Key('calories_week_balance_day_2026-04-16'),
    );
    expect(
      CaloriesPageKeys.weekBalanceBar('2026-04-16'),
      const Key('calories_week_balance_bar_2026-04-16'),
    );
    expect(
      CaloriesPageKeys.dayNavigationPreview('2026-04-16'),
      const Key('calories_day_navigation_preview_2026-04-16'),
    );
    expect(
      CaloriesPageKeys.dayNavigationPreviewGoalLine('2026-04-16'),
      const Key('calories_day_navigation_preview_goal_line_2026-04-16'),
    );
    expect(
      CaloriesPageKeys.dayNavigationPreviewBar('2026-04-16'),
      const Key('calories_day_navigation_preview_bar_2026-04-16'),
    );
    expect(
      CalorieGoalCalculatorSheetKeys.activityLevelOption('high'),
      const Key('calorie_calculator_activity_level_option_high'),
    );
  });
}
