import 'package:flutter/material.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_models.dart';
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

  /// Open health trends.
  openHealthTrends,
}

/// Show diary weekly check-in dialog.
Future<DiaryWeeklyCheckInDialogAction?> showDiaryWeeklyCheckInDialog(
  BuildContext context, {
  required CalorieWeeklyCheckInViewModel viewModel,
}) {
  return showDialog<DiaryWeeklyCheckInDialogAction>(
    context: context,
    builder: (context) {
      return _DiaryWeeklyCheckInDialog(viewModel: viewModel);
    },
  );
}

class _DiaryWeeklyCheckInDialog extends StatelessWidget {
  const _DiaryWeeklyCheckInDialog({required this.viewModel});

  final CalorieWeeklyCheckInViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      key: DiaryWeeklyCheckInDialogKeys.dialog,
      title: Text(l10n.caloriesWeeklyCheckInDialogTitle),
      content: DiaryWeeklyCheckInDialogContent(viewModel: viewModel),
      actions: <Widget>[
        if (_shouldShowOpenTrends(viewModel))
          DiaryWeeklyCheckInOpenTrendsAction(
            onPressed: () {
              Navigator.of(
                context,
              ).pop(DiaryWeeklyCheckInDialogAction.openHealthTrends);
            },
          ),
        DiaryWeeklyCheckInLaterAction(
          onPressed: () {
            Navigator.of(context).pop(DiaryWeeklyCheckInDialogAction.later);
          },
        ),
        if (viewModel.isReady)
          DiaryWeeklyCheckInApplyAction(
            onPressed: () {
              Navigator.of(context).pop(DiaryWeeklyCheckInDialogAction.apply);
            },
          ),
      ],
    );
  }

  bool _shouldShowOpenTrends(CalorieWeeklyCheckInViewModel viewModel) {
    return switch (viewModel.blockedReason) {
      CalorieWeeklyCheckInBlockedReason.missingWindowStartWeight ||
      CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight ||
      CalorieWeeklyCheckInBlockedReason.unstableWeightData => true,
      _ => false,
    };
  }
}
