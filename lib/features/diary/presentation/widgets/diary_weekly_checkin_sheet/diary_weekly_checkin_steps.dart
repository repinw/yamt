import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_weekly_checkin_sheet_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_number_format.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_review_step.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_sheet_frame.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_sheet_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_sheet_result.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_targets_step.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_training_step.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The three steps of a ready check-in in one frame.
class DiaryWeeklyCheckInSteps extends ConsumerWidget {
  /// Creates the steps of a ready check-in.
  const new({
    required this.state,
    required this.controllerProvider,
    required this.lowConfidence,
    required this.format,
    required this.onPop,
    super.key,
  });

  /// State of the sheet.
  final DiaryWeeklyCheckInSheetState state;

  /// The controller of this sheet.
  final DiaryWeeklyCheckInSheetControllerProvider controllerProvider;

  /// Whether the measurement had only few weights.
  final bool lowConfidence;

  /// Number formats.
  final DiaryWeeklyCheckInNumberFormat format;

  /// Closes the sheet with a decision.
  final void Function(
    DiaryWeeklyCheckInSheetAction action, [
    DiaryRunTrainingChoice? training,
  ])
  onPop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    DiaryWeeklyCheckInSheetController controller() =>
        ref.read(controllerProvider.notifier);
    final plan = state.plan;
    final targets = state.targets;

    return switch (state.step) {
      DiaryWeeklyCheckInStep.review => DiaryWeeklyCheckInSheetFrame(
        kicker: _reviewKicker(l10n),
        stepIndex: 0,
        onClose: () => onPop(DiaryWeeklyCheckInSheetAction.later),
        dock: [
          FilledButton.tonal(
            key: DiaryWeeklyCheckInSheetKeys.laterButton,
            onPressed: () => onPop(DiaryWeeklyCheckInSheetAction.later),
            child: Text(l10n.caloriesWeeklyCheckInLaterAction),
          ),
          FilledButton(
            key: DiaryWeeklyCheckInSheetKeys.nextButton,
            onPressed: () => controller().goTo(DiaryWeeklyCheckInStep.training),
            child: Text(l10n.diaryCheckInNext),
          ),
        ],
        children: [
          DiaryWeeklyCheckInReviewStep(
            plan: plan,
            useMeasured: state.useMeasured,
            lowConfidence: lowConfidence,
            format: format,
            onUseMeasured: (useMeasured) =>
                controller().setUseMeasured(useMeasured: useMeasured),
            onChangeGoal: () => onPop(DiaryWeeklyCheckInSheetAction.newGoal),
          ),
        ],
      ),
      DiaryWeeklyCheckInStep.training => DiaryWeeklyCheckInSheetFrame(
        kicker: _nextRunKicker(l10n),
        stepIndex: 1,
        onBack: () => controller().goTo(DiaryWeeklyCheckInStep.review),
        dock: [
          FilledButton(
            key: DiaryWeeklyCheckInSheetKeys.nextButton,
            onPressed: () => controller().goTo(DiaryWeeklyCheckInStep.targets),
            child: Text(l10n.diaryCheckInNext),
          ),
        ],
        children: [
          DiaryWeeklyCheckInTrainingStep(
            plan: plan,
            trainingDays: state.trainingDays,
            goalKcal: targets.goalKcal,
            onToggle: (day) => controller().toggleTrainingDay(day),
            onReset: () => controller().resetTrainingDays(),
            onClear: () => controller().clearTrainingDays(),
          ),
        ],
      ),
      DiaryWeeklyCheckInStep.targets => DiaryWeeklyCheckInSheetFrame(
        kicker: _nextRunKicker(l10n),
        stepIndex: 2,
        onBack: () => controller().goTo(DiaryWeeklyCheckInStep.training),
        dock: [
          FilledButton(
            key: DiaryWeeklyCheckInSheetKeys.startWeekButton,
            onPressed: () => onPop(
              state.useMeasured
                  ? DiaryWeeklyCheckInSheetAction.apply
                  : DiaryWeeklyCheckInSheetAction.reject,
              (
                runDay: plan.nextRunDays.first,
                trainingDays: state.trainingDays,
              ),
            ),
            child: Text(l10n.diaryCheckInStartWeek),
          ),
        ],
        children: [
          DiaryWeeklyCheckInTargetsStep(
            targets: targets,
            trainingDayCount: state.trainingDays.length,
            restDayCount:
                plan.nextRunDays.length -
                state.trainingDays.length -
                plan.pauseDays.difference(state.trainingDays).length,
            format: format,
          ),
        ],
      ),
    };
  }

  String _reviewKicker(AppLocalizations l10n) {
    final days = state.plan.reviewedDays;
    final range = format.range(days.start, days.end);
    final run = state.plan.reviewedRunNumber;
    return run == null
        ? l10n.diaryCheckInRangeKicker(range)
        : l10n.diaryCheckInRunKicker(run, range);
  }

  String _nextRunKicker(AppLocalizations l10n) {
    final days = state.plan.nextRunDays;
    final range = format.range(days.first, days.last);
    final run = state.plan.nextRunNumber;
    return run == null
        ? l10n.diaryCheckInRangeKicker(range)
        : l10n.diaryCheckInRunKicker(run, range);
  }
}
