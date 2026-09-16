import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/activity/presentation/widgets/'
    'activity_weight_section/diary_activity_weight_section.dart';
import 'package:yamt/features/diary/application/diary_day_dashboard_data.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_burn_week_card/diary_weekly_balance_summary.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_intro_banner_card.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_section/diary_weekly_checkin_section.dart';

/// Renders the diary activity, intro, and weekly check-in controls below the
/// daily balance card.
class DiaryPageHeader extends StatelessWidget {
  /// Creates the diary page header.
  const DiaryPageHeader({
    required this.selectedDay,
    required this.dashboardData,
    required this.showIntroBanner,
    required this.onOpenIntro,
    required this.onDismissIntro,
    super.key,
  });

  /// Selected diary day.
  final DateTime selectedDay;

  /// Dashboard data for the selected day, when loaded.
  final DiaryDayDashboardData? dashboardData;

  /// Whether the intro banner should be shown.
  final bool showIntroBanner;

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
            DiaryActivityWeightSection(
              selectedDay: selectedDay,
              header: DiaryWeeklyBalanceSummary(
                selectedDay: selectedDay,
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
                selectedDay: selectedDay,
              ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
