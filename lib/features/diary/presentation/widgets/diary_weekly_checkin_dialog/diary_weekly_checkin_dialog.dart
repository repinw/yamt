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

  /// Track missing weight.
  trackMissingWeight,
}

/// Show diary weekly check-in dialog.
Future<DiaryWeeklyCheckInDialogAction?> showDiaryWeeklyCheckInDialog(
  BuildContext context, {
  required DiaryWeeklyCheckInData checkInData,
}) {
  return showDialog<DiaryWeeklyCheckInDialogAction>(
    context: context,
    builder: (context) {
      return _DiaryWeeklyCheckInDialog(checkInData: checkInData);
    },
  );
}

class _DiaryWeeklyCheckInDialog extends StatelessWidget {
  const _DiaryWeeklyCheckInDialog({required this.checkInData});

  final DiaryWeeklyCheckInData checkInData;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      key: DiaryWeeklyCheckInDialogKeys.dialog,
      title: Text(l10n.caloriesWeeklyCheckInDialogTitle),
      content: DiaryWeeklyCheckInDialogContent(checkInData: checkInData),
      actions: <Widget>[
        if (_shouldShowTrackMissingWeight(checkInData))
          DiaryWeeklyCheckInTrackMissingWeightAction(
            onPressed: () {
              Navigator.of(
                context,
              ).pop(DiaryWeeklyCheckInDialogAction.trackMissingWeight);
            },
          ),
        DiaryWeeklyCheckInLaterAction(
          onPressed: () {
            Navigator.of(context).pop(DiaryWeeklyCheckInDialogAction.later);
          },
        ),
        if (checkInData.isReady)
          DiaryWeeklyCheckInApplyAction(
            onPressed: () {
              Navigator.of(context).pop(DiaryWeeklyCheckInDialogAction.apply);
            },
          ),
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
