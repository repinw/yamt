import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/activity/presentation/widgets/'
    'diary_weight_missing_prompt_section.dart';
import 'package:yamt/features/diary/application/diary_day_dashboard_data.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_section/diary_weekly_checkin_section.dart';

/// Renders the weekly check-in and today's missing-weight prompt below the
/// daily balance card.
///
/// The weight prompt stays hidden while the check-in hint offers its own
/// missing-weight action, so the diary never asks for a weight twice.
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
    final isToday = ref.watch(
      diaryCalendarControllerProvider.select(
        (state) => isSameCalendarDay(state.today, selectedDay),
      ),
    );
    final showWeightPrompt =
        isSelectedDay && isToday && !_checkInAsksForWeight(ref);

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
            if (showWeightPrompt)
              DiaryWeightMissingPromptSection(day: selectedDay),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  /// Whether the check-in hint asks for a weight, or may once it loads.
  bool _checkInAsksForWeight(WidgetRef ref) {
    return ref.watch(
      diaryWeeklyCheckInDataProvider.select(
        (checkIn) => switch (checkIn.value) {
          final data? =>
            data.showDiaryHint && diaryCheckInCanTrackMissingWeight(data),
          null => checkIn.isLoading,
        },
      ),
    );
  }
}
