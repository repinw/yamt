import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/calories/domain/calorie_goal_progress.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_weekly_checkin_sheet_controller.dart';
import 'package:yamt/features/diary/presentation/diary_weekly_checkin_messages.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_goal_reached_step.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_number_format.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_sheet_frame.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_sheet_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_sheet_result.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_steps.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _sheetHeightFactor = 0.94;

/// Shows the weekly check-in as a tall bottom sheet.
///
/// A reached goal cannot be dismissed; it asks for a new goal.
Future<DiaryWeeklyCheckInSheetResult?> showDiaryWeeklyCheckInSheet(
  BuildContext context, {
  required DiaryWeeklyCheckInData checkInData,
  bool goalReached = false,
}) {
  return showDiaryWeeklyCheckInSheetRoute(
    context,
    dismissible: !goalReached,
    child: DiaryWeeklyCheckInSheet(
      key: DiaryWeeklyCheckInSheetKeys.sheet,
      checkInData: checkInData,
      goalReached: goalReached,
    ),
  );
}

/// Shows [child] in the tall bottom sheet of the weekly check-in.
Future<DiaryWeeklyCheckInSheetResult?> showDiaryWeeklyCheckInSheetRoute(
  BuildContext context, {
  required Widget child,
  bool dismissible = true,
}) {
  return showModalBottomSheet<DiaryWeeklyCheckInSheetResult>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    isDismissible: dismissible,
    enableDrag: dismissible,
    backgroundColor: FoodLabelColors.of(context).paper,
    builder: (_) =>
        FractionallySizedBox(heightFactor: _sheetHeightFactor, child: child),
  );
}

/// The weekly check-in: review, training days, and new targets.
class DiaryWeeklyCheckInSheet extends ConsumerWidget {
  /// Creates the weekly check-in sheet.
  const new({
    required this.checkInData,
    required this.goalReached,
    this.preview = false,
    super.key,
  });

  /// Weekly check-in data.
  final DiaryWeeklyCheckInData checkInData;

  /// Whether the goal weight was reached.
  final bool goalReached;

  /// Whether the sheet shows the latest completed window as a debug preview.
  final bool preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final format = DiaryWeeklyCheckInNumberFormat(
      Localizations.localeOf(context).toLanguageTag(),
    );
    void pop(DiaryWeeklyCheckInSheetAction action, [Set<DateTime>? days]) {
      Navigator.of(context).pop<DiaryWeeklyCheckInSheetResult>((
        action: action,
        trainingDays: days,
      ));
    }

    return ref
        .watch(
          diaryWeeklyCheckInSheetControllerProvider(
            windowStart: checkInData.pendingWeeklyCheckIn?.windowStartDate,
            preview: preview,
          ),
        )
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          // A reached goal still asks for a new goal without its chart.
          error: (_, _) => goalReached
              ? _GoalReachedFrame(progress: null, format: format, onPop: pop)
              : _BlockedFrame(
                  checkInData: checkInData,
                  message: l10n.diaryCheckInLoadFailed,
                  onPop: pop,
                ),
          data: (state) {
            if (goalReached) {
              return _GoalReachedFrame(
                progress: state?.plan.progress,
                format: format,
                onPop: pop,
              );
            }
            if (state == null || !checkInData.isReady) {
              return _BlockedFrame(
                checkInData: checkInData,
                message: resolveDiaryWeeklyCheckInBlockedMessage(
                  l10n: l10n,
                  checkInData: checkInData,
                  locale: Localizations.localeOf(context).toLanguageTag(),
                  fallbackMessage: l10n.caloriesWeeklyCheckInDialogBlockedBody,
                ),
                onPop: pop,
              );
            }
            return DiaryWeeklyCheckInSteps(
              state: state,
              controllerProvider: diaryWeeklyCheckInSheetControllerProvider(
                windowStart: checkInData.pendingWeeklyCheckIn?.windowStartDate,
                preview: preview,
              ),
              lowConfidence: checkInData.lowConfidence,
              format: format,
              onPop: pop,
            );
          },
        );
  }
}

class _GoalReachedFrame extends StatelessWidget {
  const new({
    required this.progress,
    required this.format,
    required this.onPop,
  });

  final CalorieGoalProgress? progress;
  final DiaryWeeklyCheckInNumberFormat format;
  final void Function(DiaryWeeklyCheckInSheetAction action) onPop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DiaryWeeklyCheckInSheetFrame(
      kicker: l10n.diaryCheckInGoalReachedKicker,
      stepIndex: 0,
      dock: [
        FilledButton(
          key: DiaryWeeklyCheckInSheetKeys.newGoalButton,
          onPressed: () => onPop(DiaryWeeklyCheckInSheetAction.newGoal),
          child: Text(l10n.diaryCheckInStartNewGoal),
        ),
      ],
      children: [
        DiaryWeeklyCheckInGoalReachedStep(progress: progress, format: format),
      ],
    );
  }
}

class _BlockedFrame extends StatelessWidget {
  const new({
    required this.checkInData,
    required this.message,
    required this.onPop,
  });

  final DiaryWeeklyCheckInData checkInData;
  final String message;
  final void Function(DiaryWeeklyCheckInSheetAction action) onPop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pending = checkInData.pendingWeeklyCheckIn;
    final format = DiaryWeeklyCheckInNumberFormat(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return DiaryWeeklyCheckInSheetFrame(
      kicker: pending == null
          ? l10n.caloriesWeeklyCheckInDialogTitle
          : format.range(pending.windowStartDate, pending.windowEndDate),
      stepIndex: 0,
      onClose: () => onPop(DiaryWeeklyCheckInSheetAction.later),
      dock: [
        if (diaryCheckInCanTrackMissingWeight(checkInData))
          FilledButton.tonal(
            key: DiaryWeeklyCheckInSheetKeys.trackMissingWeightButton,
            onPressed: () =>
                onPop(DiaryWeeklyCheckInSheetAction.trackMissingWeight),
            child: Text(l10n.caloriesWeeklyCheckInTrackMissingWeightAction),
          ),
        FilledButton.tonal(
          key: DiaryWeeklyCheckInSheetKeys.laterButton,
          onPressed: () => onPop(DiaryWeeklyCheckInSheetAction.later),
          child: Text(l10n.caloriesWeeklyCheckInLaterAction),
        ),
      ],
      children: [
        DiaryWeeklyCheckInHeading(
          title: l10n.diaryCheckInBlockedTitle,
          subtitle: message,
        ),
      ],
    );
  }
}
