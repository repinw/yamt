import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/activity/presentation/widgets/'
    'activity_weight_section/diary_activity_weight_section.dart';
import 'package:yamt/features/diary/application/diary_day_dashboard_data.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_burn_week_card/diary_balance_card.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_burn_week_card/diary_weekly_balance_summary.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_calendar_strip.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_intro_banner_card.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_section/diary_weekly_checkin_section.dart';

/// Renders the diary calendar, balance, activity, and intro controls.
class DiaryPageHeader extends StatelessWidget {
  /// Creates the diary page header.
  const DiaryPageHeader({
    required this.calendarState,
    required this.dashboardData,
    required this.showIntroBanner,
    required this.onSelectDay,
    required this.onOpenIntro,
    required this.onDismissIntro,
    super.key,
  });

  /// Current calendar state.
  final DiaryCalendarState calendarState;

  /// Dashboard data for the selected day, when loaded.
  final DiaryDayDashboardData? dashboardData;

  /// Whether the intro banner should be shown.
  final bool showIntroBanner;

  /// Calendar selection callback.
  final ValueChanged<DateTime> onSelectDay;

  /// Intro-open callback.
  final VoidCallback onOpenIntro;

  /// Intro-dismiss callback.
  final VoidCallback onDismissIntro;

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
            DiaryCalendarStrip(
              today: calendarState.today,
              selectedDay: calendarState.selectedDay,
              todayRequest: calendarState.todayRequest,
              onSelectDay: onSelectDay,
            ),
            const SizedBox(height: AppSpacing.xs),
            DiaryBalanceCard(selectedDay: calendarState.selectedDay),
            const SizedBox(height: AppSpacing.xs),
            DiaryActivityWeightSection(
              selectedDay: calendarState.selectedDay,
              header: DiaryWeeklyBalanceSummary(
                selectedDay: calendarState.selectedDay,
              ),
            ),
            if (showIntroBanner) ...[
              const SizedBox(height: AppSpacing.sm),
              DiaryIntroBannerCard(
                onOpenIntro: onOpenIntro,
                onDismiss: onDismissIntro,
              ),
            ],
            if (dashboardData != null)
              DiaryWeeklyCheckInSection(
                selectedDay: calendarState.selectedDay,
              ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
