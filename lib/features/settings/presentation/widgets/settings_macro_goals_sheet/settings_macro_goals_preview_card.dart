import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Card showing live preview of calculated macro distribution and percentages.
class SettingsMacroGoalsPreviewCard extends StatelessWidget {
  /// Creates a macro goals preview card.
  const SettingsMacroGoalsPreviewCard({
    required this.goalKcal,
    required this.weightKg,
    required this.proteinGrams,
    required this.fatGrams,
    required this.carbsGrams,
    required this.proteinPct,
    required this.fatPct,
    required this.carbsPct,
    required this.isBudgetExceeded,
    super.key,
  });

  /// User's daily calorie goal.
  final double goalKcal;

  /// User's body weight in kg.
  final double weightKg;

  /// Target protein in grams.
  final int proteinGrams;

  /// Target fat in grams.
  final int fatGrams;

  /// Target carbohydrates in grams.
  final int carbsGrams;

  /// Protein percentage of total calories.
  final int proteinPct;

  /// Fat percentage of total calories.
  final int fatPct;

  /// Carbs percentage of total calories.
  final int carbsPct;

  /// Whether protein + fat already exceed the calorie goal.
  final bool isBudgetExceeded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final accents = MetricAccentColors.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.settingsMacroGoalsPreviewTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                '${goalKcal.round()} kcal · '
                '${weightKg.toStringAsFixed(0)} kg',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: SettingsMacroGoalsPreviewPill(
                  label: l10n.caloriesProteinLabel,
                  grams: proteinGrams,
                  percentage: proteinPct,
                  color: accents.protein,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: SettingsMacroGoalsPreviewPill(
                  label: l10n.caloriesCarbsLabel,
                  grams: carbsGrams,
                  percentage: carbsPct,
                  color: accents.carbs,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: SettingsMacroGoalsPreviewPill(
                  label: l10n.caloriesFatLabel,
                  grams: fatGrams,
                  percentage: fatPct,
                  color: accents.fat,
                ),
              ),
            ],
          ),
          if (isBudgetExceeded) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.settingsMacroGoalsWarningBudgetExceeded,
              style: TextStyle(
                color: colors.error,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pill widget rendering an individual macronutrient in the preview card.
class SettingsMacroGoalsPreviewPill extends StatelessWidget {
  /// Creates a macro preview pill.
  const SettingsMacroGoalsPreviewPill({
    required this.label,
    required this.grams,
    required this.percentage,
    required this.color,
    super.key,
  });

  /// Name of the macro.
  final String label;

  /// Target grams.
  final int grams;

  /// Percentage of total calorie target.
  final int percentage;

  /// Distinctive accent color.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${grams}g',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '$percentage%',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
