import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/presentation/'
    'diary_weekly_checkin_messages.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_dialog/diary_weekly_checkin_metric_rows.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Content for the diary weekly check-in dialog.
class DiaryWeeklyCheckInDialogContent extends StatelessWidget {
  /// Creates diary weekly check-in dialog content.
  const DiaryWeeklyCheckInDialogContent({required this.checkInData, super.key});

  /// Weekly check-in data.
  final DiaryWeeklyCheckInData checkInData;

  @override
  Widget build(BuildContext context) {
    final pending = checkInData.pendingWeeklyCheckIn;
    final calculation = checkInData.calculation;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DiaryWeeklyCheckInDialogIntro(checkInData: checkInData),
          if (pending != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            DiaryWeeklyCheckInWindowRow(pending: pending),
          ],
          if (calculation != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            DiaryWeeklyCheckInCalculationRows(
              calculation: calculation,
              lowConfidence: checkInData.lowConfidence,
            ),
          ],
          if (checkInData.isBlocked) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            DiaryWeeklyCheckInBlockedMessage(checkInData: checkInData),
          ],
        ],
      ),
    );
  }
}

/// Intro text for the diary weekly check-in dialog.
class DiaryWeeklyCheckInDialogIntro extends StatelessWidget {
  /// Creates diary weekly check-in dialog intro text.
  const DiaryWeeklyCheckInDialogIntro({required this.checkInData, super.key});

  /// Weekly check-in data.
  final DiaryWeeklyCheckInData checkInData;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Text(
      checkInData.isReady
          ? l10n.caloriesWeeklyCheckInDialogReadyBody
          : l10n.caloriesWeeklyCheckInDialogBlockedBody,
    );
  }
}

/// Blocked reason text for the diary weekly check-in dialog.
class DiaryWeeklyCheckInBlockedMessage extends StatelessWidget {
  /// Creates blocked reason text.
  const DiaryWeeklyCheckInBlockedMessage({
    required this.checkInData,
    super.key,
  });

  /// Weekly check-in data.
  final DiaryWeeklyCheckInData checkInData;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Text(
      resolveDiaryWeeklyCheckInBlockedMessage(
        l10n: l10n,
        checkInData: checkInData,
        locale: locale,
        fallbackMessage: '',
      ),
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
