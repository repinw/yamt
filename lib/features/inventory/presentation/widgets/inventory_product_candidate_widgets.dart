import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_receipt_product_selection_widgets.dart';

/// Reusable candidate row for manual search and barcode pickers.
class InventoryProductCandidateTile extends StatelessWidget {
  /// The candidate tile.
  const InventoryProductCandidateTile({
    required this.name,
    required this.imageUrl,
    super.key,
    this.brand,
    this.packageWeight,
    this.nutrition,
    this.topLabel,
    this.onTap,
    this.trailing,
  });

  /// The product name.
  final String name;

  /// The brand text.
  final String? brand;

  /// The image url.
  final String? imageUrl;

  /// The package weight.
  final String? packageWeight;

  /// The nutrition.
  final GlobalFoodNutrition? nutrition;

  /// Optional top tag label.
  final String? topLabel;

  /// Optional tap on whole tile.
  final VoidCallback? onTap;

  /// Optional trailing widget.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(
      AppInventoryEditorial.cardRadius,
    );
    final tile = Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InventoryReceiptSelectionThumbnail(
            imageUrl: imageUrl,
            dimension: AppInventoryEditorial.imageTileSize,
            backgroundColor: colors.secondaryContainer.withValues(alpha: 0.28),
            foregroundColor: colors.onSecondaryContainer,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _InventoryProductCandidateDetails(
              name: name,
              brand: brand,
              packageWeight: packageWeight,
              nutrition: nutrition,
              topLabel: topLabel,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );

    return DecoratedBox(
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: borderRadius,
        color: colors.surfaceContainerLowest.withValues(alpha: 0.96),
        blurRadius: 22,
        shadowOffset: const Offset(0, 10),
      ),
      child: Material(
        color: Colors.transparent,
        child: AppInkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: tile,
        ),
      ),
    );
  }
}

/// Shared candidate action buttons.
class InventoryProductCandidateActions extends StatelessWidget {
  /// The candidate action buttons.
  const InventoryProductCandidateActions({
    required this.inventoryLabel,
    required this.eatLabel,
    required this.onInventory,
    required this.onEat,
    super.key,
    this.inventoryButtonKey,
    this.eatButtonKey,
    this.showInventoryAction = true,
  });

  /// Inventory label.
  final String inventoryLabel;

  /// Eat label.
  final String eatLabel;

  /// Inventory action.
  final VoidCallback onInventory;

  /// Eat action.
  final VoidCallback onEat;

  /// Optional inventory button key.
  final Key? inventoryButtonKey;

  /// Optional eat button key.
  final Key? eatButtonKey;

  /// Whether inventory action is visible.
  final bool showInventoryAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 86),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: colors.outlineVariant.withValues(alpha: 0.55),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showInventoryAction) ...[
                  _InventoryCandidateActionButton(
                    buttonKey: inventoryButtonKey,
                    tooltip: inventoryLabel,
                    icon: Icons.inventory_2_outlined,
                    onPressed: onInventory,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                _InventoryCandidateActionButton(
                  buttonKey: eatButtonKey,
                  tooltip: eatLabel,
                  icon: Icons.restaurant_menu_outlined,
                  onPressed: onEat,
                  highlighted: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryCandidateActionButton extends StatelessWidget {
  const _InventoryCandidateActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.buttonKey,
    this.highlighted = false,
  });

  final Key? buttonKey;
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final backgroundColor = highlighted
        ? colors.primaryContainer
        : colors.surfaceContainerHigh;
    final foregroundColor = highlighted
        ? colors.onPrimaryContainer
        : colors.onSurfaceVariant;
    final borderColor = highlighted
        ? colors.primary.withValues(alpha: 0.35)
        : colors.outlineVariant.withValues(alpha: 0.7);

    return Tooltip(
      message: tooltip,
      child: IconButton(
        key: buttonKey,
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          fixedSize: const Size.square(46),
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          shadowColor: highlighted
              ? colors.primary.withValues(alpha: 0.22)
              : Colors.transparent,
          elevation: highlighted ? 4 : 0,
        ),
      ),
    );
  }
}

class _InventoryProductCandidateDetails extends StatelessWidget {
  const _InventoryProductCandidateDetails({
    required this.name,
    required this.brand,
    required this.packageWeight,
    required this.nutrition,
    required this.topLabel,
  });

  final String name;
  final String? brand;
  final String? packageWeight;
  final GlobalFoodNutrition? nutrition;
  final String? topLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final normalizedBrand = _normalizeText(brand);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (topLabel case final String label when label.trim().isNotEmpty) ...[
          _InventoryProductCandidateTag(label: label.trim()),
          const SizedBox(height: AppSpacing.xs),
        ],
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (normalizedBrand != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            normalizedBrand,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (nutrition?.hasAnyNutritionValue == true) ...[
          const SizedBox(height: AppSpacing.xs),
          InventoryReceiptNutritionChips(
            leadingLabel: packageWeight,
            nutrition: nutrition!,
          ),
        ] else if (packageWeight case final String weight
            when weight.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          _InventoryProductCandidateTag(label: weight.trim()),
        ],
      ],
    );
  }
}

class _InventoryProductCandidateTag extends StatelessWidget {
  const _InventoryProductCandidateTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

String? _normalizeText(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
