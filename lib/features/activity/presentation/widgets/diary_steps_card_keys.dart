import 'package:flutter/widgets.dart';

/// Stable keys for diary steps card tests.
abstract final class DiaryStepsCardKeys {
  /// Steps progress track key.
  static const progressTrack = ValueKey<String>('diary-steps-progress-track');

  /// Steps progress fill key.
  static const progressFill = ValueKey<String>('diary-steps-progress-fill');

  /// Retry button key.
  static const retryButton = ValueKey<String>('diary-steps-retry-button');
}
