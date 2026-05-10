import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_metric_stat_card.dart';

/// One detail row in the calorie budget dialog.
class CalorieBudgetDetailsLine {
  /// Creates a detail row.
  const CalorieBudgetDetailsLine({
    required this.label,
    required this.value,
  });

  /// Row label.
  final String label;

  /// Row value.
  final String value;
}

/// Data shown in the shared calorie budget details dialog.
class CalorieBudgetDetailsData {
  /// Creates dialog data.
  const CalorieBudgetDetailsData({
    required this.title,
    required this.primaryLabel,
    required this.primaryValue,
    required this.secondaryLabel,
    required this.secondaryValue,
    required this.explanation,
    required this.lines,
  });

  /// Dialog title.
  final String title;

  /// Primary stat label.
  final String primaryLabel;

  /// Primary stat value.
  final String primaryValue;

  /// Secondary stat label.
  final String secondaryLabel;

  /// Secondary stat value.
  final String secondaryValue;

  /// Human explanation for the formula.
  final String explanation;

  /// Detail rows.
  final List<CalorieBudgetDetailsLine> lines;
}

/// Shows shared calorie budget details dialog.
Future<void> showCalorieBudgetDetailsDialog({
  required BuildContext context,
  required CalorieBudgetDetailsData data,
}) {
  final colors = Theme.of(context).colorScheme;
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(data.title),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 360,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CalorieMetricStatCard(
                        title: data.primaryLabel,
                        value: data.primaryValue,
                        borderColor: colors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: CalorieMetricStatCard(
                        title: data.secondaryLabel,
                        value: data.secondaryValue,
                        borderColor: colors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.explanation,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        for (final line in data.lines)
                          _BudgetInfoLine(
                            label: line.label,
                            value: line.value,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
        ],
      );
    },
  );
}

class _BudgetInfoLine extends StatelessWidget {
  const _BudgetInfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: RichText(
        text: TextSpan(
          style: style?.copyWith(color: colors.onSurface),
          children: [
            TextSpan(
              text: '$label: ',
              style: style?.copyWith(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
