import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart';

part 'diary_weekly_checkin_sheet_controller.g.dart';

/// The steps of the weekly check-in sheet.
enum DiaryWeeklyCheckInStep {
  /// Look back since the goal start and pick the TDEE.
  review,

  /// Plan the training days of the next run.
  training,

  /// Show the new daily targets.
  targets,
}

/// State of the weekly check-in sheet.
@immutable
class DiaryWeeklyCheckInSheetState {
  /// Creates the sheet state.
  const new({
    required this.plan,
    required this.step,
    required this.useMeasured,
    required this.trainingDays,
  });

  /// The plan of the pending check-in.
  final DiaryWeeklyCheckInPlan plan;

  /// The current step.
  final DiaryWeeklyCheckInStep step;

  /// Whether the measured TDEE applies from now on.
  final bool useMeasured;

  /// The planned training days of the next run.
  final Set<DateTime> trainingDays;

  /// Targets of the next run for the current choices.
  DiaryWeeklyCheckInTargets get targets => plan.targetsFor(
    useMeasured: useMeasured,
    trainingDays: trainingDays.length,
  );

  /// Returns a copy with the given fields replaced.
  DiaryWeeklyCheckInSheetState copyWith({
    DiaryWeeklyCheckInStep? step,
    bool? useMeasured,
    Set<DateTime>? trainingDays,
  }) {
    return DiaryWeeklyCheckInSheetState(
      plan: plan,
      step: step ?? this.step,
      useMeasured: useMeasured ?? this.useMeasured,
      trainingDays: trainingDays ?? this.trainingDays,
    );
  }
}

/// Holds the step and the choices of the weekly check-in sheet.
///
/// One controller per check-in window (`windowStart`). With `preview`, it
/// plans the latest completed window for the debug preview instead of the
/// pending one.
@riverpod
class DiaryWeeklyCheckInSheetController
    extends _$DiaryWeeklyCheckInSheetController {
  @override
  Future<DiaryWeeklyCheckInSheetState?> build({
    required DateTime? windowStart,
    bool preview = false,
  }) async {
    // A reload, for example after the app resumes, keeps the step and the
    // choices. A plan of another window leaves this sheet as it is.
    final previous = state.value;
    final plan = await ref.watch(
      preview
          ? diaryWeeklyCheckInPreviewPlanProvider.future
          : diaryWeeklyCheckInPlanProvider.future,
    );
    if (plan == null) {
      return null;
    }
    if (windowStart != null &&
        plan.reviewedDays.start != normalizeDiaryDay(windowStart)) {
      return previous;
    }
    if (previous != null) {
      return DiaryWeeklyCheckInSheetState(
        plan: plan,
        step: previous.step,
        useMeasured: previous.useMeasured && plan.measurement != null,
        trainingDays: Set<DateTime>.unmodifiable(
          previous.trainingDays.where(
            (day) =>
                plan.nextRunDays.contains(day) && !plan.pauseDays.contains(day),
          ),
        ),
      );
    }
    return DiaryWeeklyCheckInSheetState(
      plan: plan,
      step: DiaryWeeklyCheckInStep.review,
      useMeasured: plan.measurement != null,
      trainingDays: Set<DateTime>.unmodifiable(plan.suggestedTrainingDays),
    );
  }

  void _update(
    DiaryWeeklyCheckInSheetState Function(DiaryWeeklyCheckInSheetState) next,
  ) {
    final current = state.value;
    if (current == null) {
      return;
    }
    state = AsyncData(next(current));
  }

  /// Picks the measured TDEE or keeps the previous one.
  void setUseMeasured({required bool useMeasured}) {
    _update(
      (current) => current.copyWith(
        useMeasured: useMeasured && current.plan.measurement != null,
      ),
    );
  }

  /// Moves to [step].
  void goTo(DiaryWeeklyCheckInStep step) {
    _update((current) => current.copyWith(step: step));
  }

  /// Turns [day] into a training day or back into a rest day.
  void toggleTrainingDay(DateTime day) {
    _update((current) {
      if (current.plan.pauseDays.contains(day)) {
        return current;
      }
      final days = Set<DateTime>.of(current.trainingDays);
      if (!days.remove(day)) {
        days.add(day);
      }
      return current.copyWith(trainingDays: Set.unmodifiable(days));
    });
  }

  /// Sets the training days of the reviewed run again.
  void resetTrainingDays() {
    _update(
      (current) => current.copyWith(
        trainingDays: Set.unmodifiable(current.plan.suggestedTrainingDays),
      ),
    );
  }

  /// Plans no training day.
  void clearTrainingDays() {
    _update((current) => current.copyWith(trainingDays: const {}));
  }
}
