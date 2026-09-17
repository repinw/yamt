import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/application/diary_day_dashboard_data.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_intro_banner_card.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_section/diary_weekly_checkin_section.dart';

/// Renders the diary intro and weekly check-in prompts below the daily
/// balance card.
class DiaryPageHeader extends StatelessWidget {
  /// Creates the diary page header.
  const new({
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
            if (showIntroBanner) ...[
              const SizedBox(height: AppSpacing.sm),
              DiaryIntroBannerCard(
                onOpenIntro: onOpenIntro,
                onDismiss: onDismissIntro,
              ),
            ],
            if (dashboardData != null)
              DiaryWeeklyCheckInSection(selectedDay: selectedDay),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
