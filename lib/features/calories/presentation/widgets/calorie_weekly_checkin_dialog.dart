import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_weekly_checkin_messages.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines calorie weekly check in dialog action.
enum CalorieWeeklyCheckInDialogAction {
  /// Later.
  later,

  /// Apply.
  apply,

  /// Open health trends.
  openHealthTrends,
}

/// Show calorie weekly check in dialog.
Future<CalorieWeeklyCheckInDialogAction?> showCalorieWeeklyCheckInDialog(
  BuildContext context, {
  required CalorieWeeklyCheckInViewModel viewModel,
}) {
  return showDialog<CalorieWeeklyCheckInDialogAction>(
    context: context,
    builder: (context) {
      return _CalorieWeeklyCheckInDialog(viewModel: viewModel);
    },
  );
}

class _CalorieWeeklyCheckInDialog extends StatelessWidget {
  const _CalorieWeeklyCheckInDialog({required this.viewModel});

  final CalorieWeeklyCheckInViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final pending = viewModel.pendingWeeklyCheckIn;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final rangeFormat = DateFormat.MMMd(locale);
    final numberFormat = NumberFormat.decimalPattern(locale);
    final showOpenTrends = switch (viewModel.blockedReason) {
      CalorieWeeklyCheckInBlockedReason.missingWindowStartWeight ||
      CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight ||
      CalorieWeeklyCheckInBlockedReason.unstableWeightData => true,
      _ => false,
    };
    final canApply = viewModel.isReady;

    return AlertDialog(
      key: CalorieWeeklyCheckInDialogKeys.dialog,
      title: Text(l10n.caloriesWeeklyCheckInDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              viewModel.isReady
                  ? l10n.caloriesWeeklyCheckInDialogReadyBody
                  : l10n.caloriesWeeklyCheckInDialogBlockedBody,
            ),
            if (pending != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              _MetricRow(
                label: l10n.caloriesWeeklyCheckInDialogWindowLabel,
                value:
                    '${rangeFormat.format(pending.windowStartDate)} - '
                    '${rangeFormat.format(pending.windowEndDate)}',
              ),
            ],
            if (viewModel.calculation != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              _MetricRow(
                label: l10n.caloriesWeeklyCheckInDialogTrendLabel,
                value: [
                  viewModel.calculation!.trendWeightChangePerDay
                      .toStringAsFixed(2),
                  'kg/day',
                ].join(' '),
              ),
              const SizedBox(height: AppSpacing.sm),
              _MetricRow(
                label: l10n.caloriesWeeklyCheckInDialogTrueTdeeLabel,
                value:
                    '${numberFormat.format(
                      viewModel.calculation!.calculatedTrueTdeeKcal.round(),
                    )} ${l10n.caloriesUnitKcal}',
              ),
              const SizedBox(height: AppSpacing.sm),
              _MetricRow(
                label: l10n.caloriesWeeklyCheckInDialogNewTargetLabel,
                value:
                    '${numberFormat.format(
                      viewModel.calculation!.newGoalKcal.round(),
                    )} ${l10n.caloriesUnitKcal}',
              ),
              if (viewModel.lowConfidence) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.caloriesWeeklyCheckInDialogLowConfidence,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
            if (viewModel.isBlocked) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Text(
                resolveCalorieWeeklyCheckInBlockedMessage(
                  l10n: l10n,
                  viewModel: viewModel,
                  locale: locale,
                  fallbackMessage: '',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        if (showOpenTrends)
          TextButton(
            key: CalorieWeeklyCheckInDialogKeys.openTrendsButton,
            onPressed: () {
              Navigator.of(
                context,
              ).pop(CalorieWeeklyCheckInDialogAction.openHealthTrends);
            },
            child: Text(l10n.caloriesWeeklyCheckInOpenHealthTrendsAction),
          ),
        TextButton(
          key: CalorieWeeklyCheckInDialogKeys.laterButton,
          onPressed: () {
            Navigator.of(context).pop(CalorieWeeklyCheckInDialogAction.later);
          },
          child: Text(l10n.caloriesWeeklyCheckInLaterAction),
        ),
        if (canApply)
          FilledButton(
            key: CalorieWeeklyCheckInDialogKeys.applyButton,
            onPressed: () {
              Navigator.of(context).pop(CalorieWeeklyCheckInDialogAction.apply);
            },
            child: Text(l10n.caloriesWeeklyCheckInApplyAction),
          ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          value,
          textAlign: TextAlign.right,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
