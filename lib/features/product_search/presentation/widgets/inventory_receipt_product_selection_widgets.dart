import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';

/// Compact nutrition badges shown for a selected or suggested product.
class InventoryReceiptNutritionChips extends StatelessWidget {
  /// The inventory receipt nutrition chips.
  const InventoryReceiptNutritionChips({
    super.key,
    required this.nutrition,
    this.leadingLabel,
  });

  /// The nutrition.
  final GlobalFoodNutrition nutrition;

  /// The leading label.
  final String? leadingLabel;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (leadingLabel case final String label when label.trim().isNotEmpty)
        _NutritionChip(label: label.trim()),
      if (nutrition.per100Kcal != null)
        _NutritionChip(
          label: '${nutrition.per100Kcal!.round()} kcal',
          emphasized: true,
        ),
      if (nutrition.per100Carbs != null)
        _NutritionChip(label: 'KH ${_formatMacro(nutrition.per100Carbs!)}'),
      if (nutrition.per100Protein != null)
        _NutritionChip(
          label: 'Eiweiß ${_formatMacro(nutrition.per100Protein!)}',
        ),
      if (nutrition.per100Fat != null)
        _NutritionChip(label: 'Fett ${_formatMacro(nutrition.per100Fat!)}'),
      if (nutrition.per100Salt != null)
        _NutritionChip(label: 'Salz ${_formatMacro(nutrition.per100Salt!)}'),
    ];

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: chips,
    );
  }

  String _formatMacro(double value) {
    final rounded = value.toStringAsFixed(
      value.truncateToDouble() == value ? 0 : 1,
    );
    return '$rounded g';
  }
}

class _NutritionChip extends StatelessWidget {
  const _NutritionChip({required this.label, this.emphasized = false});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = emphasized
        ? colors.primaryContainer
        : colors.surfaceContainerHighest;
    final foreground = emphasized
        ? colors.onPrimaryContainer
        : colors.onSurfaceVariant;
    final borderColor = emphasized ? colors.primary : colors.outlineVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

/// Thumbnail that only shows the image already present on the selected product.
class InventoryReceiptSelectionThumbnail extends StatelessWidget {
  /// The inventory receipt selection thumbnail.
  const InventoryReceiptSelectionThumbnail({
    super.key,
    required this.imageUrl,
    this.icon = Icons.inventory_2_outlined,
    this.backgroundColor,
    this.foregroundColor,
    this.dimension = 28,
  });

  /// The image url.
  final String? imageUrl;

  /// The icon.
  final IconData icon;

  /// The background color.
  final Color? backgroundColor;

  /// The foreground color.
  final Color? foregroundColor;

  /// The dimension.
  final double dimension;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final normalizedImageUrl = normalizeProductImageUrl(imageUrl);
    final hasImage =
        normalizedImageUrl != null && normalizedImageUrl.isNotEmpty;
    final effectiveBackground =
        backgroundColor ?? colors.surfaceContainerHighest;
    final effectiveForeground = foregroundColor ?? colors.onSurfaceVariant;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.square(
        dimension: dimension,
        child: hasImage
            ? AppCachedNetworkImage(
                imageUrl: normalizedImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stackTrace) {
                  return ColoredBox(
                    color: effectiveBackground,
                    child: Icon(
                      icon,
                      size: dimension * 0.5,
                      color: effectiveForeground,
                    ),
                  );
                },
              )
            : ColoredBox(
                color: effectiveBackground,
                child: Icon(
                  icon,
                  size: dimension * 0.5,
                  color: effectiveForeground,
                ),
              ),
      ),
    );
  }
}
