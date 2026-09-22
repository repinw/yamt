import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/diary/application/diary_day_dashboard_data.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_section/diary_weekly_checkin_section.dart';

/// Renders the weekly check-in prompt below the daily balance card.
class DiaryPageHeader extends ConsumerWidget {
  /// Creates the diary page header.
  const new({
    required this.selectedDay,
    required this.dashboardData,
    required this.weeklyCheckInKey,
    super.key,
  });

  /// Selected diary day.
  final DateTime selectedDay;

  /// Dashboard data for the selected day, when loaded.
  final DiaryDayDashboardData? dashboardData;

  /// Key of the weekly check-in section, shared by all days.
  ///
  /// The section opens dialogs, so only the selected day shows it. The shared
  /// key moves it with its state to the next selected day.
  final GlobalKey weeklyCheckInKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelectedDay = ref.watch(
      diaryCalendarControllerProvider.select(
        (state) => isSameCalendarDay(state.selectedDay, selectedDay),
      ),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSizes.narrowContentMaxWidth,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (dashboardData != null && isSelectedDay)
              DiaryWeeklyCheckInSection(
                key: weeklyCheckInKey,
                selectedDay: selectedDay,
              ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
