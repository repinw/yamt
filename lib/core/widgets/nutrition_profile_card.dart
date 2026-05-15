import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/widgets/nutrition_metrics_strip.dart';

/// Shared nutrition summary card.
class NutritionProfileCard extends StatelessWidget {
  /// Creates nutrition profile card.
  const NutritionProfileCard({
    required this.kcal,
    required this.kcalUnitLabel,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.proteinLabel,
    required this.carbsLabel,
    required this.fatLabel,
    super.key,
    this.title,
    this.titleColor,
    this.accentColor,
    this.trailing,
  });

  /// Main kcal value.
  final double kcal;

  /// Localized kcal unit label.
  final String kcalUnitLabel;

  /// Protein value in grams.
  final double? protein;

  /// Carbs value in grams.
  final double? carbs;

  /// Fat value in grams.
  final double? fat;

  /// Localized protein label.
  final String proteinLabel;

  /// Localized carbs label.
  final String carbsLabel;

  /// Localized fat label.
  final String fatLabel;

  /// Optional title shown above card.
  final String? title;

  /// Optional title color override.
  final Color? titleColor;

  /// Accent color for kcal number.
  final Color? accentColor;

  /// Optional trailing widget shown next to title.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final header = _buildHeader(context);
    final card = _buildCard(context);
    if (header == null) {
      return card;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: AppSpacing.md),
        card,
      ],
    );
  }

  Widget? _buildHeader(BuildContext context) {
    final headerTitle = title;
    final headerTrailing = trailing;
    if (headerTitle == null && headerTrailing == null) {
      return null;
    }

    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        if (headerTitle != null)
          Expanded(
            child: Text(
              headerTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: titleColor ?? colors.onSurface,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        if (headerTrailing case final Widget trailingWidget) trailingWidget,
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final resolvedAccent = accentColor ?? colors.primary;

    return Container(
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        color: Color.alphaBlend(
          colors.surfaceContainerLowest.withValues(alpha: 0.96),
          colors.surface,
        ),
        blurRadius: 16,
        shadowOffset: const Offset(0, 8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: kcal.round().toString(),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: resolvedAccent,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                      ),
                      TextSpan(
                        text: ' ${kcalUnitLabel.toUpperCase()}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _NutritionDivider(colors: colors),
            Expanded(
              flex: 3,
              child: _NutritionMetricCell(
                label: carbsLabel.toUpperCase(),
                value: _buildMetricText(carbs),
              ),
            ),
            _NutritionDivider(colors: colors),
            Expanded(
              flex: 3,
              child: _NutritionMetricCell(
                label: proteinLabel.toUpperCase(),
                value: _buildMetricText(protein),
              ),
            ),
            _NutritionDivider(colors: colors),
            Expanded(
              flex: 3,
              child: _NutritionMetricCell(
                label: fatLabel.toUpperCase(),
                value: _buildMetricText(fat),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildMetricText(double? value) {
    if (value == null) {
      return '-';
    }
    return '${value.toNutritionMetricValue()}g';
  }
}

class _NutritionDivider extends StatelessWidget {
  const _NutritionDivider({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: VerticalDivider(
        width: AppSpacing.xl,
        thickness: 1,
        color: AppInventoryEditorialSurfaces.ghostBorder(
          colors,
        ).withValues(alpha: 0.9),
      ),
    );
  }
}

class _NutritionMetricCell extends StatelessWidget {
  const _NutritionMetricCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      label: '$label $value',
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              value,
              maxLines: 1,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
