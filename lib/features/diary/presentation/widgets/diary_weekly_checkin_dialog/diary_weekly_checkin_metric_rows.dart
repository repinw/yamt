import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Window date row for the diary weekly check-in dialog.
class DiaryWeeklyCheckInWindowRow extends StatelessWidget {
  /// Creates a window date row.
  const DiaryWeeklyCheckInWindowRow({required this.pending, super.key});

  /// Pending weekly check-in.
  final PendingCalorieGoalWeeklyCheckIn pending;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final rangeFormat = DateFormat.MMMd(locale);

    return _MetricRow(
      label: l10n.caloriesWeeklyCheckInDialogWindowLabel,
      value:
          '${rangeFormat.format(pending.windowStartDate)} - '
          '${rangeFormat.format(pending.windowEndDate)}',
    );
  }
}

/// Calculation rows for the diary weekly check-in dialog.
class DiaryWeeklyCheckInCalculationRows extends StatelessWidget {
  /// Creates calculation rows.
  const DiaryWeeklyCheckInCalculationRows({
    required this.calculation,
    required this.lowConfidence,
    super.key,
  });

  /// Weekly check-in calculation.
  final CalorieWeeklyCheckInCalculation calculation;

  /// Whether calculation is low confidence.
  final bool lowConfidence;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _TrendRow(calculation: calculation),
        const SizedBox(height: AppSpacing.sm),
        _TrueTdeeRow(calculation: calculation),
        const SizedBox(height: AppSpacing.sm),
        _NewTargetRow(calculation: calculation),
        if (lowConfidence) ...const <Widget>[
          SizedBox(height: AppSpacing.md),
          _LowConfidenceText(),
        ],
      ],
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.calculation});

  final CalorieWeeklyCheckInCalculation calculation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _MetricRow(
      label: l10n.caloriesWeeklyCheckInDialogTrendLabel,
      value: [
        calculation.trendWeightChangePerDay.toStringAsFixed(2),
        'kg/day',
      ].join(' '),
    );
  }
}

class _TrueTdeeRow extends StatelessWidget {
  const _TrueTdeeRow({required this.calculation});

  final CalorieWeeklyCheckInCalculation calculation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _MetricRow(
      label: l10n.caloriesWeeklyCheckInDialogTrueTdeeLabel,
      value:
          '${_formatKcal(context, calculation.calculatedTrueTdeeKcal)} '
          '${l10n.caloriesUnitKcal}',
    );
  }
}

class _NewTargetRow extends StatelessWidget {
  const _NewTargetRow({required this.calculation});

  final CalorieWeeklyCheckInCalculation calculation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _MetricRow(
      label: l10n.caloriesWeeklyCheckInDialogNewTargetLabel,
      value:
          '${_formatKcal(context, calculation.newGoalKcal)} '
          '${l10n.caloriesUnitKcal}',
    );
  }
}

class _LowConfidenceText extends StatelessWidget {
  const _LowConfidenceText();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Text(
      l10n.caloriesWeeklyCheckInDialogLowConfidence,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
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

String _formatKcal(BuildContext context, double value) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final numberFormat = NumberFormat.decimalPattern(locale);
  return numberFormat.format(value.round());
}
