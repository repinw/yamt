import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
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
    this.statusLabel,
    this.onTap,
    this.trailing,
    this.onCopy,
    this.copyTooltip,
    this.copyButtonKey,
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

  /// Optional status tag label.
  final String? statusLabel;

  /// Optional tap on whole tile.
  final VoidCallback? onTap;

  /// Optional trailing widget.
  final Widget? trailing;

  /// Optional copy callback.
  final VoidCallback? onCopy;

  /// Optional copy tooltip text.
  final String? copyTooltip;

  /// Optional copy button key.
  final Key? copyButtonKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(AppRadius.xl);
    final hasActions = onCopy != null || trailing != null;

    final tile = Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InventoryReceiptSelectionThumbnail(
            imageUrl: imageUrl,
            dimension: 56,
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
              statusLabel: statusLabel,
            ),
          ),
          if (hasActions) ...[
            const SizedBox(width: AppSpacing.sm),
            if (onCopy != null)
              _InventoryCandidateCopyButton(
                tooltip: copyTooltip ?? 'Kopieren',
                buttonKey: copyButtonKey,
                onPressed: onCopy!,
              ),
            if (trailing != null) ...[
              if (onCopy != null) const SizedBox(width: AppSpacing.xs),
              trailing!,
            ],
          ],
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: borderRadius,
        border: Border.all(color: colors.outlineVariant),
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

class _InventoryCandidateCopyButton extends StatelessWidget {
  const _InventoryCandidateCopyButton({
    required this.tooltip,
    required this.onPressed,
    this.buttonKey,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: IconButton(
        key: buttonKey,
        onPressed: onPressed,
        icon: const Icon(Icons.content_copy_rounded, size: 20),
        style: IconButton.styleFrom(
          fixedSize: const Size.square(42),
          backgroundColor: colors.surfaceContainerHigh,
          foregroundColor: colors.onSurfaceVariant,
          side: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.7),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
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
    required this.statusLabel,
  });

  final String name;
  final String? brand;
  final String? packageWeight;
  final GlobalFoodNutrition? nutrition;
  final String? topLabel;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final normalizedBrand = _normalizeText(brand);
    final topLabels = <String>[
      if (_normalizeText(topLabel) case final String label) label,
      if (_normalizeText(statusLabel) case final String label) label,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (topLabels.isNotEmpty) ...[
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            children: [
              for (final label in topLabels)
                _InventoryProductCandidateTag(label: label),
            ],
          ),
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
