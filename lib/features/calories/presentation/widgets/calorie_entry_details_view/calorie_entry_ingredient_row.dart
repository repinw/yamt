import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';

/// Single ingredient row in a bundle calorie entry.
class CalorieEntryIngredientRow extends StatelessWidget {
  /// Creates an ingredient row.
  const CalorieEntryIngredientRow({
    required this.component,
    required this.index,
    required this.accentColor,
    super.key,
  });

  /// Bundle component displayed by the row.
  final CalorieEntryBundleComponent component;

  /// Component index used for test keys.
  final int index;

  /// Accent color for the row marker.
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brand = component.brand?.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: accentColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  component.name,
                  key: CalorieEntryDetailKeys.ingredientNameCell(index),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (brand != null && brand.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: Text(
                      brand,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            component.amountLabel,
            key: CalorieEntryDetailKeys.ingredientAmountCell(index),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
