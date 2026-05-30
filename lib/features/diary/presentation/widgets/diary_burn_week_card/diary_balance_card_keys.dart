import 'package:flutter/widgets.dart';

/// Stable keys for diary balance card tests.
abstract final class DiaryBalanceCardKeys {
  /// Progress track key.
  static const progressTrack = ValueKey<String>(
    'diary-balance-progress-track',
  );

  /// Daily progress track key.
  static const dailyProgressTrack = ValueKey<String>(
    'diary-balance-daily-progress-track',
  );

  /// Daily eaten progress fill key.
  static const dailyProgressEatenFill = ValueKey<String>(
    'diary-balance-daily-progress-eaten-fill',
  );

  /// Daily activity progress extension key.
  static const dailyProgressActivityFill = ValueKey<String>(
    'diary-balance-daily-progress-activity-fill',
  );

  /// Daily activity preview extension key.
  static const dailyProgressActivityPreview = ValueKey<String>(
    'diary-balance-daily-progress-activity-preview',
  );

  /// Target marker key.
  static const targetMarker = ValueKey<String>(
    'diary-balance-target-marker',
  );

  /// Practice day card key.
  static const practiceDay = ValueKey<String>('diary-balance-practice-day');

  /// Retry button key.
  static const retryButton = ValueKey<String>('diary-balance-retry-button');
}
