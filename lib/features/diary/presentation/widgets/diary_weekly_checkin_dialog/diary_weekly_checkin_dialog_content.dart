import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/diary/presentation/'
    'diary_weekly_checkin_messages.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_dialog/diary_weekly_checkin_metric_rows.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Content for the diary weekly check-in dialog.
class DiaryWeeklyCheckInDialogContent extends StatelessWidget {
  /// Creates diary weekly check-in dialog content.
  const DiaryWeeklyCheckInDialogContent({required this.viewModel, super.key});

  /// Weekly check-in view model.
  final CalorieWeeklyCheckInViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final pending = viewModel.pendingWeeklyCheckIn;
    final calculation = viewModel.calculation;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DiaryWeeklyCheckInDialogIntro(viewModel: viewModel),
          if (pending != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            DiaryWeeklyCheckInWindowRow(pending: pending),
          ],
          if (calculation != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            DiaryWeeklyCheckInCalculationRows(
              calculation: calculation,
              lowConfidence: viewModel.lowConfidence,
            ),
          ],
          if (viewModel.isBlocked) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            DiaryWeeklyCheckInBlockedMessage(viewModel: viewModel),
          ],
        ],
      ),
    );
  }
}

/// Intro text for the diary weekly check-in dialog.
class DiaryWeeklyCheckInDialogIntro extends StatelessWidget {
  /// Creates diary weekly check-in dialog intro text.
  const DiaryWeeklyCheckInDialogIntro({required this.viewModel, super.key});

  /// Weekly check-in view model.
  final CalorieWeeklyCheckInViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Text(
      viewModel.isReady
          ? l10n.caloriesWeeklyCheckInDialogReadyBody
          : l10n.caloriesWeeklyCheckInDialogBlockedBody,
    );
  }
}

/// Blocked reason text for the diary weekly check-in dialog.
class DiaryWeeklyCheckInBlockedMessage extends StatelessWidget {
  /// Creates blocked reason text.
  const DiaryWeeklyCheckInBlockedMessage({required this.viewModel, super.key});

  /// Weekly check-in view model.
  final CalorieWeeklyCheckInViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Text(
      resolveDiaryWeeklyCheckInBlockedMessage(
        l10n: l10n,
        viewModel: viewModel,
        locale: locale,
        fallbackMessage: '',
      ),
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
