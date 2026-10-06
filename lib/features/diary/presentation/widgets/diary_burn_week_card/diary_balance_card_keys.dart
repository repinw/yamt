import 'package:flutter/widgets.dart';

/// Stable keys for diary balance card tests.
abstract final class DiaryBalanceCardKeys {
  /// Daily progress track key.
  static const dailyProgressTrack = ValueKey<String>(
    'diary-balance-daily-progress-track',
  );

  /// Daily eaten progress fill key.
  static const dailyProgressEatenFill = ValueKey<String>(
    'diary-balance-daily-progress-eaten-fill',
  );

  /// Label above the big number of the daily head.
  static const kcalHeadLabel = ValueKey<String>(
    'diary-balance-kcal-head-label',
  );

  /// Big number of the daily head.
  static const kcalHeadValue = ValueKey<String>(
    'diary-balance-kcal-head-value',
  );

  /// Chip that counts the open plans of the day in the head.
  static const afterPlanChip = ValueKey<String>(
    'diary-balance-after-plan-chip',
  );

  /// What is left without the plans, under the big number after plan.
  static const kcalHeadWithoutPlan = ValueKey<String>(
    'diary-balance-kcal-head-without-plan',
  );

  /// Goal next to the big number of a future day.
  static const kcalHeadTarget = ValueKey<String>(
    'diary-balance-kcal-head-target',
  );

  /// Button that closes the day before a planned day.
  static const previousDayCloseButton = ValueKey<String>(
    'diary-balance-previous-day-close-button',
  );

  /// Note that the day before a planned day is closed.
  static const previousDayClosed = ValueKey<String>(
    'diary-balance-previous-day-closed',
  );

  /// Button that opens the closed day before a planned day again.
  static const previousDayReopenButton = ValueKey<String>(
    'diary-balance-previous-day-reopen-button',
  );

  /// Practice day card key.
  static const practiceDay = ValueKey<String>('diary-balance-practice-day');

  /// Retry button key.
  static const retryButton = ValueKey<String>('diary-balance-retry-button');

  /// Daily budget details button key.
  static const dailyBudgetDetailsButton = ValueKey<String>(
    'diary-balance-daily-budget-details-button',
  );

  /// Daily progress bar tap button key.
  @Deprecated('Use dailyBudgetDetailsButton instead')
  static const dailyProgressBarButton = ValueKey<String>(
    'diary-balance-daily-progress-bar-button',
  );

  /// Daily budget details sheet key.
  static const dailyBudgetDetailsSheet = ValueKey<String>(
    'diary-balance-daily-budget-details-sheet',
  );
}
