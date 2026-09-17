import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/activity/presentation/widgets/'
    'activity_weight_section/diary_activity_weight_section.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_burn_week_card/diary_weekly_balance_summary.dart';

/// Weekly calorie budget, activity, and weight of the week around
/// [selectedDay], as one card.
class DiaryWeeklyProgressSection extends StatelessWidget {
  /// Creates the weekly progress section.
  const new({required this.selectedDay, super.key});

  /// Day whose week is shown.
  final DateTime selectedDay;

  @override
  Widget build(BuildContext context) {
    return DiaryActivityWeightSection(
      selectedDay: selectedDay,
      header: DiaryWeeklyBalanceSummary(selectedDay: selectedDay),
    );
  }
}
