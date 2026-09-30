/// What the user decided in the weekly check-in sheet.
enum DiaryWeeklyCheckInSheetAction {
  /// Decide later.
  later,

  /// Use the measured TDEE.
  apply,

  /// Keep the previous TDEE.
  reject,

  /// Track a missing weight first.
  trackMissingWeight,

  /// Open the goal calculator.
  newGoal,
}

/// Result of the weekly check-in sheet: the decision and, for
/// [DiaryWeeklyCheckInSheetAction.apply] and
/// [DiaryWeeklyCheckInSheetAction.reject], the training days of the next run.
typedef DiaryWeeklyCheckInSheetResult = ({
  DiaryWeeklyCheckInSheetAction action,
  Set<DateTime>? trainingDays,
});
