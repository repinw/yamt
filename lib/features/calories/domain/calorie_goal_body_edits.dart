import 'package:yamt/features/calories/domain/calorie_body_edit.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';

/// How far a body edit reaches into the calorie plan.
enum CalorieBodyEditReach {
  /// No goal is set. The edit only changes the stored body data.
  noGoal,

  /// The goal comes from a learned expenditure. The calorie goal stays, and
  /// only the macros follow the edit.
  learnedTdee,

  /// The calorie goal was set by hand. It stays, and only the macros follow
  /// the edit.
  manualGoal,

  /// No expenditure is learned yet. The edit corrects the calculated goal
  /// from its start, so the calorie goal is calculated again.
  goalCorrection,
}

/// Body data edits on [CalorieGoalSettings].
extension CalorieGoalBodyEdits on CalorieGoalSettings {
  /// How far a body edit made at [now] reaches.
  CalorieBodyEditReach bodyEditReach(DateTime now) {
    if (!hasGoal) {
      return CalorieBodyEditReach.noGoal;
    }
    if (hasLearnedTdee) {
      return CalorieBodyEditReach.learnedTdee;
    }
    return _correctableGoalEntry(now) == null
        ? CalorieBodyEditReach.manualGoal
        : CalorieBodyEditReach.goalCorrection;
  }

  /// Start of the goal that a body edit made at [now] corrects, or `null`
  /// when the edit does not correct a goal.
  DateTime? bodyCorrectionStart(DateTime now) {
    return _correctableGoalEntry(now)?.effectiveCountingStartDate;
  }

  /// Whether the start weight may change. Once an expenditure is learned,
  /// the start weight is part of the record and stays.
  bool get canEditStartWeight => calculatorProfile != null && !hasLearnedTdee;

  /// Returns these settings with [edit] applied at [now].
  ///
  /// The calculator profile always takes the edit. Without a learned
  /// expenditure, the calculated goal takes it too: its calorie goal is
  /// calculated again, and weekly check-ins that kept the old goal keep the
  /// new one instead.
  CalorieGoalSettings applyBodyEdit(
    CalorieBodyEdit edit, {
    required DateTime now,
  }) {
    final profile = calculatorProfile;
    if (profile == null) {
      throw StateError('A body edit needs a calculator profile.');
    }
    if (edit is CalorieStartWeightEdit && !canEditStartWeight) {
      throw StateError('The start weight is fixed once a TDEE is learned.');
    }
    final nextProfile = profile.withBodyEdit(edit, ageDay: now);
    final entry = _correctableGoalEntry(now);
    if (entry == null) {
      return copyWith(calculatorProfile: nextProfile, updatedAt: now);
    }
    final correctedProfile = entry.calculatorProfile!.withBodyEdit(
      edit,
      ageDay: entry.effectiveCountingStartDate,
    );
    final correctedKcal = CalorieGoalCalculator.calculate(correctedProfile)
        .finalGoalKcal;
    final previousKcal = entry.dailyKcalGoal;
    final nextHistory = [
      for (final other in goalHistory)
        if (identical(other, entry))
          other.copyWith(
            dailyKcalGoal: correctedKcal,
            calculatorProfile: correctedProfile,
          )
        else if (_keptGoalOf(other, entry, previousKcal))
          other.copyWith(dailyKcalGoal: correctedKcal)
        else
          other,
    ];
    return copyWith(
      dailyKcalGoal: identical(entry, latestGoalEntry) ? correctedKcal : null,
      calculatorProfile: nextProfile,
      goalHistory: List<CalorieGoalHistoryEntry>.unmodifiable(nextHistory),
      updatedAt: now,
    );
  }

  CalorieGoalHistoryEntry? _correctableGoalEntry(DateTime now) {
    if (hasLearnedTdee) {
      return null;
    }
    final entry = activeGoalEntryForDay(now) ?? latestGoalEntry;
    if (entry == null || entry.calculatorProfile == null) {
      return null;
    }
    return entry;
  }
}

/// Whether [entry] is a weekly check-in after [goal] that kept its calorie
/// goal of [goalKcal].
bool _keptGoalOf(
  CalorieGoalHistoryEntry entry,
  CalorieGoalHistoryEntry goal,
  double? goalKcal,
) {
  return entry.isWeeklyCheckIn &&
      !entry.effectiveDate.isBefore(goal.effectiveDate) &&
      entry.dailyKcalGoal == goalKcal;
}
