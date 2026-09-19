import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/application/diary_day_dashboard_data.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_section/diary_weekly_checkin_section.dart';

/// Renders the weekly check-in prompt below the daily balance card.
class DiaryPageHeader extends StatelessWidget {
  /// Creates the diary page header.
  const new({
    required this.selectedDay,
    required this.dashboardData,
    super.key,
  });

  /// Selected diary day.
  final DateTime selectedDay;

  /// Dashboard data for the selected day, when loaded.
  final DiaryDayDashboardData? dashboardData;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSizes.narrowContentMaxWidth,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (dashboardData != null)
              DiaryWeeklyCheckInSection(selectedDay: selectedDay),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
