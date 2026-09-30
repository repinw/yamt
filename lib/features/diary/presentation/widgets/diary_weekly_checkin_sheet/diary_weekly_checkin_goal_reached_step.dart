import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/graphit_text_styles.dart';
import 'package:yamt/features/calories/domain/calorie_goal_progress.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_facts.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_number_format.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_progress_chart.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_sheet_frame.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Replaces the review when the goal weight is reached: start, now, and the
/// weight since the goal start.
class DiaryWeeklyCheckInGoalReachedStep extends StatelessWidget {
  /// Creates the goal reached step.
  const new({required this.progress, required this.format, super.key});

  /// Weight since the goal start, if known.
  final CalorieGoalProgress? progress;

  /// Number formats.
  final DiaryWeeklyCheckInNumberFormat format;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = this.progress;
    final weeks = progress == null || progress.weights.isEmpty
        ? 1
        : math.max(
            1,
            (diaryDaysBetween(progress.startDate, progress.weights.last.day) /
                    DateTime.daysPerWeek)
                .ceil(),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.diaryCheckInGoalReachedKicker.toUpperCase(),
          style: context.graphitKickerStyle,
        ),
        const SizedBox(height: AppSpacing.xs),
        DiaryWeeklyCheckInHeading(
          title: l10n.diaryCheckInGoalReachedTitle,
          subtitle: l10n.diaryCheckInGoalReachedBody(weeks),
        ),
        if (progress != null) ...[
          const SizedBox(height: AppSpacing.lg),
          DiaryWeeklyCheckInFacts(facts: _facts(l10n, progress, weeks)),
          const SizedBox(height: AppSpacing.lg),
          DiaryWeeklyCheckInProgressChart(
            progress: progress,
            formatKcal: format.kcal,
            showTdee: false,
            targetWeightKg: progress.targetWeightKg,
          ),
        ],
      ],
    );
  }

  List<DiaryWeeklyCheckInFact> _facts(
    AppLocalizations l10n,
    CalorieGoalProgress progress,
    int weeks,
  ) {
    final start = progress.startWeightKg;
    final now = progress.latestTrendWeightKg;
    final change = start == null || now == null ? null : now - start;
    String weight(double? kg) => kg == null ? '–' : format.kg(kg);
    return [
      (
        kicker: l10n.diaryCheckInStartFact,
        value: weight(start),
        unit: l10n.caloriesUnitKg,
        caption: format.day(progress.startDate),
      ),
      (
        kicker: l10n.diaryCheckInTodayFact,
        value: weight(now),
        unit: l10n.caloriesUnitKg,
        caption: l10n.diaryCheckInTrend,
      ),
      (
        kicker: l10n.diaryCheckInDoneFact,
        value: change == null ? '–' : format.signedKg(change),
        unit: l10n.caloriesUnitKg,
        caption: change == null
            ? ''
            : l10n.diaryCheckInPerWeek(format.signedKg(change / weeks)),
      ),
    ];
  }
}
