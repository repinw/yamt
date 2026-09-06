import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/application/diary_nutrition_bars_data.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_food_log_feedback_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_nutrition_bars/diary_nutrition_macro_row.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Content of the diary nutrition bars displaying all three macro rows.
class DiaryNutritionBarsContent extends StatelessWidget {
  /// Creates the nutrition bars content.
  const DiaryNutritionBarsContent({
    required this.data,
    required this.showTitle,
    this.feedback,
    super.key,
  });

  /// Confirmed food addition matching the displayed day and values.
  final DiaryFoodLogFeedback? feedback;

  /// Loaded nutrition values and targets.
  final DiaryNutritionBarsData data;

  /// Whether to show the top section title.
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final l10n = AppLocalizations.of(context)!;
    final accentColors = MetricAccentColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            l10n.diaryNutritionTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Column(
          children: [
            DiaryNutritionMacroRow(
              label: l10n.caloriesProteinLabel,
              current: data.protein,
              previous: feedback?.before?.protein,
              startedAt: feedback?.startedAt,
              target: data.goals.protein,
              color: accentColors.protein,
              numberFormat: numberFormat,
              unit: l10n.caloriesUnitGram,
            ),
            const SizedBox(height: AppSpacing.xs),
            DiaryNutritionMacroRow(
              label: l10n.caloriesCarbsShortLabel,
              current: data.carbs,
              previous: feedback?.before?.carbs,
              startedAt: feedback?.startedAt,
              target: data.goals.carbs,
              color: accentColors.carbs,
              numberFormat: numberFormat,
              unit: l10n.caloriesUnitGram,
            ),
            const SizedBox(height: AppSpacing.xs),
            DiaryNutritionMacroRow(
              label: l10n.caloriesFatLabel,
              current: data.fat,
              previous: feedback?.before?.fat,
              startedAt: feedback?.startedAt,
              target: data.goals.fat,
              color: accentColors.fat,
              numberFormat: numberFormat,
              unit: l10n.caloriesUnitGram,
            ),
          ],
        ),
      ],
    );
  }
}
