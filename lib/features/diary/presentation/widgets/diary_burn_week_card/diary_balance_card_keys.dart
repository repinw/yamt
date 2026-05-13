import 'package:flutter/widgets.dart';

/// Stable keys for diary balance card tests.
abstract final class DiaryBalanceCardKeys {
  /// Progress track key.
  static const progressTrack = ValueKey<String>(
    'diary-balance-progress-track',
  );

  /// Safe-zone fill key.
  static const safeZone = ValueKey<String>('diary-balance-safe-zone');

  /// Target marker key.
  static const targetMarker = ValueKey<String>(
    'diary-balance-target-marker',
  );

  /// Consumed marker key.
  static const consumedMarker = ValueKey<String>(
    'diary-balance-consumed-marker',
  );

  /// Practice day card key.
  static const practiceDay = ValueKey<String>('diary-balance-practice-day');

  /// Retry button key.
  static const retryButton = ValueKey<String>('diary-balance-retry-button');
}
