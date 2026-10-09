import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin_plan.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_choice_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_facts.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_number_format.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_progress_chart.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_sheet_frame.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_sheet_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Step 1: weight and TDEE since the goal start, and the TDEE to go on with.
class DiaryWeeklyCheckInReviewStep extends StatelessWidget {
  /// Creates the review step.
  const new({
    required this.plan,
    required this.useMeasured,
    required this.lowConfidence,
    required this.format,
    required this.onUseMeasured,
    required this.onChangeGoal,
    super.key,
  });

  /// Plan of the check-in.
  final CalorieWeeklyCheckInPlan plan;

  /// Whether the measured TDEE is picked.
  final bool useMeasured;

  /// Whether the measurement had only few weights.
  final bool lowConfidence;

  /// Number formats.
  final DiaryWeeklyCheckInNumberFormat format;

  /// Called with the picked TDEE.
  final ValueChanged<bool> onUseMeasured;

  /// Opens the goal calculator.
  final VoidCallback onChangeGoal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = plan.progress;
    final measurement = plan.measurement;
    final previousTargets = plan.targetsFor(
      useMeasured: false,
      trainingDays: plan.previousTrainingDayCount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DiaryWeeklyCheckInHeading(
          title: l10n.diaryCheckInReviewTitle,
          subtitle: _subtitle(l10n),
        ),
        const SizedBox(height: AppSpacing.lg),
        DiaryWeeklyCheckInFacts(facts: _facts(l10n)),
        if (progress != null) ...[
          const SizedBox(height: AppSpacing.lg),
          DiaryWeeklyCheckInProgressChart(
            progress: progress,
            formatKcal: format.kcal,
            targetWeightKg: progress.targetWeightKg,
          ),
        ],
        if (measurement != null) ...[
          const SizedBox(height: AppSpacing.lg),
          DiaryWeeklyCheckInChoiceTile(
            key: DiaryWeeklyCheckInSheetKeys.useMeasuredChoice,
            isSelected: useMeasured,
            leading: DiaryWeeklyCheckInRadioMark(isSelected: useMeasured),
            title: l10n.diaryCheckInUseMeasured,
            detail: l10n.diaryCheckInUseMeasuredDetail(
              format.kcal(measurement.tdeeKcal),
            ),
            trailing: DiaryWeeklyCheckInChoiceValue(
              value: format.kcal(measurement.goalKcal),
              caption: l10n.diaryCheckInGoalKcalCaption,
            ),
            onTap: () => onUseMeasured(true),
          ),
          const SizedBox(height: AppSpacing.sm),
          DiaryWeeklyCheckInChoiceTile(
            key: DiaryWeeklyCheckInSheetKeys.keepPreviousChoice,
            isSelected: !useMeasured,
            leading: DiaryWeeklyCheckInRadioMark(isSelected: !useMeasured),
            title: l10n.diaryCheckInKeepPrevious,
            detail: l10n.diaryCheckInKeepPreviousDetail(
              format.kcal(plan.previousTdeeKcal),
            ),
            trailing: DiaryWeeklyCheckInChoiceValue(
              value: format.kcal(previousTargets.goalKcal),
              caption: l10n.diaryCheckInGoalKcalCaption,
            ),
            onTap: () => onUseMeasured(false),
          ),
          if (lowConfidence) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.caloriesWeeklyCheckInDialogLowConfidence,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: FoodLabelColors.of(context).muted),
            ),
          ],
        ],
        const SizedBox(height: AppSpacing.lg),
        DiaryWeeklyCheckInChoiceTile(
          key: DiaryWeeklyCheckInSheetKeys.changeGoalButton,
          leading: const Icon(Icons.track_changes_rounded),
          title: l10n.diaryCheckInChangeGoal,
          detail: l10n.diaryCheckInChangeGoalDetail,
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onChangeGoal,
        ),
      ],
    );
  }

  String _subtitle(AppLocalizations l10n) {
    final progress = plan.progress;
    final start = format.day(progress?.startDate ?? plan.reviewedDays.start);
    final target = progress?.targetWeightKg;
    return target == null
        ? l10n.diaryCheckInSince(start)
        : l10n.diaryCheckInGoalSince(format.kg(target), start);
  }

  List<DiaryWeeklyCheckInFact> _facts(AppLocalizations l10n) {
    final progress = plan.progress;
    final trend = progress?.latestTrendWeightKg;
    final startWeight = progress?.startWeightKg;
    final measurement = plan.measurement;
    return [
      (
        kicker: l10n.diaryCheckInTrendFact,
        value: trend == null ? '–' : format.kg(trend),
        unit: trend == null ? null : l10n.caloriesUnitKg,
        caption: trend == null || startWeight == null
            ? ''
            : l10n.diaryCheckInTrendChange(
                format.signedKg(trend - startWeight),
              ),
      ),
      (
        kicker: l10n.diaryCheckInEatenFact,
        value: measurement == null
            ? '–'
            : format.kcal(measurement.averageIntakeKcal),
        unit: null,
        caption: l10n.diaryCheckInPerDay,
      ),
      (
        kicker: l10n.diaryCheckInTrainingFact,
        value: '${plan.previousTrainingDayCount}',
        unit: null,
        caption: l10n.diaryCheckInTrainingDaysCaption,
      ),
    ];
  }
}
