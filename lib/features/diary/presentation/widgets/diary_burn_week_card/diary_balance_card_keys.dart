import 'package:flutter/widgets.dart';

/// Stable keys for diary balance card tests.
abstract final class DiaryBalanceCardKeys {
  /// Row with the open plans in the budget details, while they count.
  static const dailyBudgetPlannedRow = ValueKey<String>(
    'diary-balance-daily-budget-planned-row',
  );

  /// Row with the kcal left in the budget details.
  static const dailyBudgetLeftRow = ValueKey<String>(
    'diary-balance-daily-budget-left-row',
  );

  /// Retry button key.
  static const retryButton = ValueKey<String>('diary-balance-retry-button');

  /// Daily budget details sheet key.
  static const dailyBudgetDetailsSheet = ValueKey<String>(
    'diary-balance-daily-budget-details-sheet',
  );
}
