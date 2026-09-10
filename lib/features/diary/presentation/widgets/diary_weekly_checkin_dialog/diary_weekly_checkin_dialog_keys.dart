import 'package:flutter/widgets.dart';

/// Defines diary weekly check-in dialog keys.
abstract final class DiaryWeeklyCheckInDialogKeys {
  /// The dialog.
  static const dialog = ValueKey<String>('diary-weekly-checkin-dialog');

  /// The later button.
  static const laterButton = ValueKey<String>(
    'diary-weekly-checkin-later',
  );

  /// The apply button.
  static const applyButton = ValueKey<String>(
    'diary-weekly-checkin-apply',
  );

  /// The reject button.
  static const rejectButton = ValueKey<String>(
    'diary-weekly-checkin-reject',
  );

  /// The track missing weight button.
  static const trackMissingWeightButton = ValueKey<String>(
    'diary-weekly-checkin-dialog-track-missing-weight',
  );
}
