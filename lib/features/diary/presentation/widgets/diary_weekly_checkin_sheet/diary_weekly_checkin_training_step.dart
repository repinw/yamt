import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/graphit_text_styles.dart';
import 'package:yamt/core/theme/intro_accent_colors.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin_plan.dart';
import 'package:yamt/features/calories/presentation/widgets/training_day_chips.dart';
import 'package:yamt/features/calories/presentation/widgets/training_week_depot_chart.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_sheet_frame.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_sheet_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Step 2: the training days of the next run.
class DiaryWeeklyCheckInTrainingStep extends StatelessWidget {
  /// Creates the training step.
  const new({
    required this.plan,
    required this.trainingDays,
    required this.goalKcal,
    required this.onToggle,
    required this.onReset,
    required this.onClear,
    super.key,
  });

  /// Plan of the check-in.
  final CalorieWeeklyCheckInPlan plan;

  /// The planned training days.
  final Set<DateTime> trainingDays;

  /// Average daily goal of the next run.
  final double goalKcal;

  /// Called with the tapped day.
  final ValueChanged<DateTime> onToggle;

  /// Plans the days of the reviewed run again.
  final VoidCallback onReset;

  /// Plans no training day.
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final weekday = DateFormat.E(locale);
    final date = DateFormat.d(locale);
    final days = plan.nextRunDays;
    final accent =
        theme.extension<IntroAccentColors>()?.amber ??
        IntroAccentColors.fallback.amber;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DiaryWeeklyCheckInHeading(
          title: l10n.diaryCheckInTrainingTitle,
          subtitle: l10n.diaryCheckInTrainingSubtitle,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.diaryCheckInSessions.toUpperCase(),
          style: context.graphitKickerStyle,
        ),
        Text(
          '${trainingDays.length}',
          style: context.graphitDisplayStyle(theme.textTheme.displaySmall),
        ),
        const SizedBox(height: AppSpacing.md),
        TrainingDayChips(
          days: [
            for (final (index, day) in days.indexed)
              (
                key: DiaryWeeklyCheckInSheetKeys.trainingDay(index),
                label: _shortLabel(weekday.format(day)),
                caption: date.format(day),
                isTraining: trainingDays.contains(day),
                isEnabled: plan.canChangeDay(day),
              ),
          ],
          onToggle: (index) => onToggle(days[index]),
        ),
        if (days.any((day) => !plan.canChangeDay(day))) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.diaryCheckInFixedDaysHint,
            key: DiaryWeeklyCheckInSheetKeys.fixedDaysHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: FoodLabelColors.of(context).muted,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        TrainingWeekDepotChart(
          days: [
            for (final day in days)
              (
                label: weekday.format(day),
                isTraining: trainingDays.contains(day),
              ),
          ],
          baseGoalKcal: goalKcal,
          sessionKcal: plan.sessionKcal,
          accent: accent,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            ActionChip(
              key: DiaryWeeklyCheckInSheetKeys.sameAsLastRunButton,
              label: Text(l10n.diaryCheckInSameAsLastRun),
              onPressed: onReset,
            ),
            ActionChip(
              key: DiaryWeeklyCheckInSheetKeys.noSessionButton,
              label: Text(l10n.diaryCheckInNoSession),
              onPressed: onClear,
            ),
          ],
        ),
      ],
    );
  }
}

String _shortLabel(String weekday) {
  return weekday.length <= 2 ? weekday : weekday.substring(0, 2);
}
