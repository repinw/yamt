import 'package:flutter/widgets.dart';

/// Defines diary weekly check-in card keys.
abstract final class DiaryWeeklyCheckInCardKeys {
  /// The weekly check-in hint card.
  static const hintCard = ValueKey<String>('diary-weekly-checkin-hint-card');

  /// The weekly check-in success card.
  static const successCard = ValueKey<String>(
    'diary-weekly-checkin-success-card',
  );

  /// The weekly check-in continue button.
  static const continueButton = ValueKey<String>(
    'diary-weekly-checkin-continue',
  );

  /// The weekly check-in track missing weight button.
  static const trackMissingWeightButton = ValueKey<String>(
    'diary-weekly-checkin-track-missing-weight',
  );

  /// The weekly check-in skip day button.
  static const skipDayButton = ValueKey<String>(
    'diary-weekly-checkin-skip-day',
  );
}
