import 'package:flutter/material.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_dialog/diary_weekly_checkin_dialog_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Track missing weight action for the diary weekly check-in dialog.
class DiaryWeeklyCheckInTrackMissingWeightAction extends StatelessWidget {
  /// Creates a track missing weight dialog action.
  const DiaryWeeklyCheckInTrackMissingWeightAction({
    required this.onPressed,
    super.key,
  });

  /// Called when action is tapped.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TextButton(
      key: DiaryWeeklyCheckInDialogKeys.trackMissingWeightButton,
      onPressed: onPressed,
      child: Text(l10n.caloriesWeeklyCheckInTrackMissingWeightAction),
    );
  }
}

/// Later action for the diary weekly check-in dialog.
class DiaryWeeklyCheckInLaterAction extends StatelessWidget {
  /// Creates a later dialog action.
  const DiaryWeeklyCheckInLaterAction({required this.onPressed, super.key});

  /// Called when action is tapped.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TextButton(
      key: DiaryWeeklyCheckInDialogKeys.laterButton,
      onPressed: onPressed,
      child: Text(l10n.caloriesWeeklyCheckInLaterAction),
    );
  }
}

/// Apply action for the diary weekly check-in dialog.
class DiaryWeeklyCheckInApplyAction extends StatelessWidget {
  /// Creates an apply dialog action.
  const DiaryWeeklyCheckInApplyAction({required this.onPressed, super.key});

  /// Called when action is tapped.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FilledButton(
      key: DiaryWeeklyCheckInDialogKeys.applyButton,
      onPressed: onPressed,
      child: Text(l10n.caloriesWeeklyCheckInApplyAction),
    );
  }
}
