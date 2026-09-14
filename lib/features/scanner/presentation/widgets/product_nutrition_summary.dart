import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/scanner/domain/models/product_candidate.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Prominent nutrition overview for comparing 100 g/ml values with a package.
class ProductNutritionSummary extends StatelessWidget {
  /// Creates a nutrition summary for [product].
  const ProductNutritionSummary({
    required this.product,
    super.key,
    this.packageSize,
  });

  /// Product whose nutrition values are displayed.
  final ProductCandidate product;

  /// Optional package size override, for example the value read from a receipt.
  final String? packageSize;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final displayedPackageSize = _displayedPackageSize;

    return Container(
      key: const Key('product_nutrition_summary'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.primary.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n?.receiptReviewNutritionPer100g ??
                      'Nährwerte je 100 g/ml',
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (displayedPackageSize != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l10n?.receiptReviewPackageSize(displayedPackageSize) ??
                        'Packung: $displayedPackageSize',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _NutritionValue(
                  label: l10n?.receiptReviewNutritionEnergy ?? 'Energie',
                  value: product.kcal != null
                      ? '${product.kcal!.round()} kcal'
                      : '–',
                  emphasized: true,
                ),
              ),
              Expanded(
                child: _NutritionValue(
                  label: l10n?.receiptReviewNutritionFat ?? 'Fett',
                  value: _grams(product.fat),
                ),
              ),
              Expanded(
                child: _NutritionValue(
                  label: l10n?.receiptReviewNutritionCarbs ?? 'KH',
                  value: _grams(product.carbs),
                ),
              ),
              Expanded(
                child: _NutritionValue(
                  label: l10n?.receiptReviewNutritionProtein ?? 'Protein',
                  value: _grams(product.protein),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? get _displayedPackageSize {
    final value = packageSize?.trim().isNotEmpty == true
        ? packageSize!.trim()
        : product.packageSize?.trim();
    return value?.isNotEmpty == true ? value : null;
  }

  String _grams(double? value) =>
      value != null ? '${value.toStringAsFixed(1)} g' : '–';
}

class _NutritionValue extends StatelessWidget {
  const _NutritionValue({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.onPrimaryContainer.withValues(alpha: 0.75),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          maxLines: 1,
          style: TextStyle(
            color: colors.onPrimaryContainer,
            fontSize: emphasized ? 16 : 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
