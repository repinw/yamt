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

  /// Goal next to the big number of a future day.
  static const kcalHeadTarget = ValueKey<String>(
    'diary-balance-kcal-head-target',
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
