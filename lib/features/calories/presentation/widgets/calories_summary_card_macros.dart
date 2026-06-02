import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';

/// Displays one macro progress card in the summary footer.
class MacroProgressCard extends StatelessWidget {
  /// Creates a macro progress card.
  const MacroProgressCard({
    required this.macroId,
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.unitLabel,
    required this.numberFormat,
    super.key,
  });

  /// Stable identifier used for widget-test keys.
  final String macroId;

  /// Localized macro label.
  final String label;

  /// Current consumed amount for the macro.
  final double current;

  /// Goal amount for the macro.
  final double target;

  /// Accent color for the macro card and bar.
  final Color color;

  /// Localized unit label displayed next to the goal.
  final String unitLabel;

  /// Number formatter used for macro values.
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentValueColor = current > target ? color : colorScheme.onSurface;
    final progress = target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
    final currentText = numberFormat.format(current.round());
    final targetText = numberFormat.format(target.round());
    final backgroundColor = Color.alphaBlend(
      color.withValues(alpha: 0.06),
      colorScheme.surfaceContainerLowest,
    );
    final trackColor = Color.alphaBlend(
      color.withValues(alpha: 0.03),
      colorScheme.surfaceContainerHigh,
    );

    return DecoratedBox(
      key: CaloriesPageKeys.summaryMacroCard(macroId),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: SizedBox(
          height: 82,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final labelStyle = Theme.of(context).textTheme.labelSmall
                      ?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.95,
                      );
                  final displayLabel = _resolveMacroLabel(
                    context: context,
                    label: label.toUpperCase(),
                    style: labelStyle,
                    maxWidth: constraints.maxWidth,
                  );

                  return Text(
                    displayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: labelStyle,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              RichText(
                key: CaloriesPageKeys.summaryMacroValue(macroId),
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: currentText,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: currentValueColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                            height: 1,
                          ),
                    ),
                    TextSpan(
                      text: ' / $targetText$unitLabel',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: trackColor),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          key: CaloriesPageKeys.summaryMacroBar(macroId),
                          widthFactor: progress,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _resolveMacroLabel({
  required BuildContext context,
  required String label,
  required TextStyle? style,
  required double maxWidth,
}) {
  return resolveMacroLabelForWidth(
    label: label,
    style: style,
    maxWidth: maxWidth,
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  );
}

/// Resolve macro label for width.
@visibleForTesting
String resolveMacroLabelForWidth({
  required String label,
  required TextStyle? style,
  required double maxWidth,
  required ui.TextDirection textDirection,
  required TextScaler textScaler,
}) {
  if (label.isEmpty || style == null || maxWidth <= 0) {
    return label;
  }

  final textPainter = TextPainter(
    maxLines: 1,
    textDirection: textDirection,
    textScaler: textScaler,
  );

  if (doesCaloriesSummaryTextFitWidth(
    textPainter: textPainter,
    text: label,
    style: style,
    maxWidth: maxWidth,
  )) {
    return label;
  }

  var bestLabel = '${label.substring(0, 1)}.';
  var low = 1;
  var high = label.length - 1;

  while (low <= high) {
    final middle = low + ((high - low) ~/ 2);
    final shortenedLabel = '${label.substring(0, middle).trimRight()}.';
    if (doesCaloriesSummaryTextFitWidth(
      textPainter: textPainter,
      text: shortenedLabel,
      style: style,
      maxWidth: maxWidth,
    )) {
      bestLabel = shortenedLabel;
      low = middle + 1;
      continue;
    }
    high = middle - 1;
  }

  return bestLabel;
}

/// Does calories summary text fit width.
@visibleForTesting
bool doesCaloriesSummaryTextFitWidth({
  required String text,
  required TextStyle style,
  required double maxWidth,
  TextPainter? textPainter,
  ui.TextDirection textDirection = ui.TextDirection.ltr,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  final resolvedTextPainter =
      textPainter ??
            TextPainter(
              maxLines: 1,
              textDirection: textDirection,
              textScaler: textScaler,
            )
        ..text = TextSpan(text: text, style: style)
        ..layout(maxWidth: maxWidth);

  return !resolvedTextPainter.didExceedMaxLines;
}

/// Stores the derived macro goals shown in the summary footer.
class CaloriesSummaryMacroGoals {
  /// Creates resolved macro goals for the summary footer.
  const CaloriesSummaryMacroGoals({
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  /// Derives macro goals from the calorie goal.
  factory CaloriesSummaryMacroGoals.fromGoalKcal(double goalKcal) {
    final positiveGoalKcal = goalKcal > 0 ? goalKcal : 0.0;
    return CaloriesSummaryMacroGoals(
      carbs: positiveGoalKcal * 0.45 / 4,
      protein: positiveGoalKcal * 0.25 / 4,
      fat: positiveGoalKcal * 0.30 / 9,
    );
  }

  /// Carb goal in grams.
  final double carbs;

  /// Protein goal in grams.
  final double protein;

  /// Fat goal in grams.
  final double fat;
}
