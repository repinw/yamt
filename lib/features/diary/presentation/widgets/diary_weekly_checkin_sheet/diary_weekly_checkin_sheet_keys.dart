import 'package:flutter/widgets.dart';

/// Keys of the weekly check-in sheet.
abstract final class DiaryWeeklyCheckInSheetKeys {
  /// The sheet.
  static const sheet = ValueKey<String>('diary-weekly-checkin-sheet');

  /// The later button.
  static const laterButton = ValueKey<String>('diary-weekly-checkin-later');

  /// The next button of the review and training steps.
  static const nextButton = ValueKey<String>('diary-weekly-checkin-next');

  /// The button that ends the check-in on the targets step.
  static const startWeekButton = ValueKey<String>(
    'diary-weekly-checkin-start-week',
  );

  /// The choice that uses the measured TDEE.
  static const useMeasuredChoice = ValueKey<String>(
    'diary-weekly-checkin-use-measured',
  );

  /// The choice that keeps the previous TDEE.
  static const keepPreviousChoice = ValueKey<String>(
    'diary-weekly-checkin-keep-previous',
  );

  /// The row that opens the goal calculator.
  static const changeGoalButton = ValueKey<String>(
    'diary-weekly-checkin-change-goal',
  );

  /// The mandatory new-goal button shown after reaching a weight target.
  static const newGoalButton = ValueKey<String>(
    'diary-weekly-checkin-new-goal',
  );

  /// The track missing weight button.
  static const trackMissingWeightButton = ValueKey<String>(
    'diary-weekly-checkin-sheet-track-missing-weight',
  );

  /// The button that plans the training days of the reviewed run again.
  static const sameAsLastRunButton = ValueKey<String>(
    'diary-weekly-checkin-same-as-last-run',
  );

  /// The button that plans no training day.
  static const noSessionButton = ValueKey<String>(
    'diary-weekly-checkin-no-session',
  );

  /// The hint that past days and pause days keep their type.
  static const fixedDaysHint = ValueKey<String>(
    'diary-weekly-checkin-fixed-days-hint',
  );

  /// The chip of the next run day at [index].
  static ValueKey<String> trainingDay(int index) =>
      ValueKey<String>('diary-weekly-checkin-training-day-$index');
}
