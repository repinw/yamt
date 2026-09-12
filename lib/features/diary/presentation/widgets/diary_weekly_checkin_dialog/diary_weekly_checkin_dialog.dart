import 'package:flutter/material.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_dialog/diary_weekly_checkin_dialog_actions.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_dialog/diary_weekly_checkin_dialog_content.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_dialog/diary_weekly_checkin_dialog_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines diary weekly check-in dialog action.
enum DiaryWeeklyCheckInDialogAction {
  /// Later.
  later,

  /// Apply.
  apply,

  /// Reject.
  reject,

  /// Track missing weight.
  trackMissingWeight,

  /// Configure a new goal after reaching the previous target.
  newGoal,
}

/// Show diary weekly check-in dialog.
Future<DiaryWeeklyCheckInDialogAction?> showDiaryWeeklyCheckInDialog(
  BuildContext context, {
  required DiaryWeeklyCheckInData checkInData,
  bool goalReached = false,
}) {
  return showDialog<DiaryWeeklyCheckInDialogAction>(
    context: context,
    barrierDismissible: !goalReached,
    builder: (context) {
      return _DiaryWeeklyCheckInDialog(
        checkInData: checkInData,
        goalReached: goalReached,
      );
    },
  );
}

class _DiaryWeeklyCheckInDialog extends StatelessWidget {
  const _DiaryWeeklyCheckInDialog({
    required this.checkInData,
    required this.goalReached,
  });

  final DiaryWeeklyCheckInData checkInData;
  final bool goalReached;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      key: DiaryWeeklyCheckInDialogKeys.dialog,
      title: Text(l10n.caloriesWeeklyCheckInDialogTitle),
      content: DiaryWeeklyCheckInDialogContent(checkInData: checkInData),
      actions: <Widget>[
        if (!goalReached && _shouldShowTrackMissingWeight(checkInData))
          DiaryWeeklyCheckInTrackMissingWeightAction(
            onPressed: () {
              Navigator.of(
                context,
              ).pop(DiaryWeeklyCheckInDialogAction.trackMissingWeight);
            },
          ),
        if (goalReached)
          FilledButton(
            key: DiaryWeeklyCheckInDialogKeys.newGoalButton,
            onPressed: () => Navigator.of(
              context,
            ).pop(DiaryWeeklyCheckInDialogAction.newGoal),
            child: Text(l10n.caloriesWeeklyCheckInNewGoalAction),
          )
        else ...<Widget>[
          DiaryWeeklyCheckInLaterAction(
            onPressed: () {
              Navigator.of(context).pop(DiaryWeeklyCheckInDialogAction.later);
            },
          ),
          if (checkInData.isReady) ...<Widget>[
            DiaryWeeklyCheckInRejectAction(
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(DiaryWeeklyCheckInDialogAction.reject);
              },
            ),
            DiaryWeeklyCheckInApplyAction(
              onPressed: () {
                Navigator.of(context).pop(DiaryWeeklyCheckInDialogAction.apply);
              },
            ),
          ],
        ],
      ],
    );
  }

  bool _shouldShowTrackMissingWeight(DiaryWeeklyCheckInData checkInData) {
    if (checkInData.missingWeightDays.isEmpty) {
      return false;
    }

    return switch (checkInData.blockedReason) {
      CalorieWeeklyCheckInBlockedReason.missingWindowStartWeight ||
      CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight => true,
      _ => false,
    };
  }
}
