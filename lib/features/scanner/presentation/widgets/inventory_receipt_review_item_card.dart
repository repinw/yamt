import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/product_image_url.dart';
import 'package:yamt/features/inventory/provider/'
    'inventory_barcode_image_provider.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';
import 'package:yamt/l10n/app_localizations.dart';

BoxDecoration _itemCardDecoration(
  BuildContext context, {
  Color? backgroundColor,
}) {
  final colors = Theme.of(context).colorScheme;

  return BoxDecoration(
    color: backgroundColor ?? colors.surface,
    borderRadius: BorderRadius.circular(AppReceiptReviewUi.panelRadius),
    border: Border.all(color: colors.outlineVariant),
    boxShadow: <BoxShadow>[
      BoxShadow(
        color: colors.shadow.withValues(alpha: 0.08),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

/// Receipt review list row that shows one mapped or unresolved item.
class InventoryReceiptReviewItemCard extends StatelessWidget {
  const InventoryReceiptReviewItemCard({
    super.key,
    required this.draft,
    required this.index,
    required this.currency,
    required this.onEditTap,
    required this.onSwitchTap,
  });

  final ReceiptReviewItemDraft draft;
  final int index;
  final NumberFormat currency;
  final ValueChanged<int> onEditTap;
  final ValueChanged<int> onSwitchTap;

  @override
  Widget build(BuildContext context) {
    final item = draft.item;
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final viewData = _ReceiptItemCardViewData.fromDraft(context, draft);
    final muted = viewData.isMuted;
    final titleStyle = muted
        ? textTheme.titleMedium?.copyWith(
            color: Theme.of(context).disabledColor,
          )
        : textTheme.titleMedium;
    final subtitleStyle = textTheme.bodySmall?.copyWith(
      color: muted ? Theme.of(context).disabledColor : colors.onSurfaceVariant,
      fontSize: 12,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('receipt_review_edit_button_$index'),
        onTap: item.isDiscount ? null : () => onEditTap(index),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: _itemCardDecoration(
            context,
            backgroundColor: muted
                ? colors.surfaceContainerLow
                : colors.surface,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReceiptItemLeading(
                  visualState: viewData.visualState,
                  display: viewData.display,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ReceiptItemTopRow(
                        item: item,
                        currency: currency,
                        viewData: viewData,
                        titleStyle: titleStyle,
                        subtitleStyle: subtitleStyle,
                      ),
                      if (viewData.display.nutrition?.hasAnyNutritionValue ??
                          false) ...[
                        const SizedBox(height: 10),
                        InventoryReceiptNutritionChips(
                          nutrition: viewData.display.nutrition!,
                        ),
                      ],
                      _ReceiptItemDiscountRows(
                        item: item,
                        itemIndex: index,
                        currency: currency,
                      ),
                      const SizedBox(height: 16),
                      _ReceiptItemFooter(
                        item: item,
                        index: index,
                        viewData: viewData,
                        onEditTap: onEditTap,
                        onSwitchTap: onSwitchTap,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptItemTopRow extends StatelessWidget {
  const _ReceiptItemTopRow({
    required this.item,
    required this.currency,
    required this.viewData,
    required this.titleStyle,
    required this.subtitleStyle,
  });

  final InventoryItem item;
  final NumberFormat currency;
  final _ReceiptItemCardViewData viewData;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brand = viewData.displayBrand;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                viewData.display.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: titleStyle?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: colors.onSurface,
                ),
              ),
              if (brand != null) ...[
                const SizedBox(height: 2),
                Text(brand, style: subtitleStyle),
              ],
              if (viewData.ocrHint case final String value) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: 12,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${l10n.inventoryReceiptReviewReadAsPrefix}: $value',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          currency.format(item.unitPrice),
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _ReceiptItemFooter extends StatelessWidget {
  const _ReceiptItemFooter({
    required this.item,
    required this.index,
    required this.viewData,
    required this.onEditTap,
    required this.onSwitchTap,
  });

  final InventoryItem item;
  final int index;
  final _ReceiptItemCardViewData viewData;
  final ValueChanged<int> onEditTap;
  final ValueChanged<int> onSwitchTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _QuantityPill(label: '${item.quantity}x'),
              if (viewData.isMuted)
                _StatusPill(label: l10n.inventoryReceiptReviewExcludedTag),
            ],
          ),
        ),
        if (viewData.actionLabel != null)
          _ReceiptItemActionButton(
            key: viewData.actionButtonKey(index),
            visualState: viewData.visualState,
            label: viewData.actionLabel!,
            onPressed: () => _handleAction(index),
          ),
      ],
    );
  }

  void _handleAction(int index) {
    if (viewData.opensEditorForAction) {
      onEditTap(index);
      return;
    }
    onSwitchTap(index);
  }
}

class _ReceiptItemLeading extends StatelessWidget {
  const _ReceiptItemLeading({required this.visualState, required this.display});

  final _ReceiptItemVisualState visualState;
  final _ReceiptDisplayData display;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        InventoryReceiptSelectionThumbnail(
          imageUrl: display.imageUrl,
          barcode: display.barcode,
          icon: Icons.inventory_2_outlined,
          backgroundColor: colors.surfaceContainerHighest,
          foregroundColor: colors.onSurfaceVariant,
          dimension: 48,
        ),
        Positioned(
          right: -4,
          bottom: -4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surface,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxs * 2),
              child: Icon(
                visualState.icon,
                size: 20,
                color: visualState.color(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _ReceiptItemVisualState { matched, reviewNeeded, newProduct, excluded }

class _ReceiptItemCardViewData {
  const _ReceiptItemCardViewData({
    required this.display,
    required this.visualState,
    required this.ocrHint,
    required this.actionLabel,
  });

  factory _ReceiptItemCardViewData.fromDraft(
    BuildContext context,
    ReceiptReviewItemDraft draft,
  ) {
    final visualState = _visualStateForDraft(draft);
    final display = _ReceiptDisplayData.fromDraft(draft);
    return _ReceiptItemCardViewData(
      display: display,
      visualState: visualState,
      ocrHint: _ocrHintForDraft(draft: draft, displayedName: display.name),
      actionLabel: _actionLabelFor(
        context: context,
        draft: draft,
        visualState: visualState,
      ),
    );
  }

  final _ReceiptDisplayData display;
  final _ReceiptItemVisualState visualState;
  final String? ocrHint;
  final String? actionLabel;

  bool get isMuted => visualState == _ReceiptItemVisualState.excluded;

  bool get opensEditorForAction =>
      visualState == _ReceiptItemVisualState.newProduct;

  String? get displayBrand {
    final trimmed = display.brand?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  Key actionButtonKey(int index) {
    return Key(
      opensEditorForAction
          ? 'receipt_review_determine_button_$index'
          : 'receipt_review_switch_button_$index',
    );
  }
}

extension on _ReceiptItemVisualState {
  IconData get icon => switch (this) {
    _ReceiptItemVisualState.matched => Icons.check_circle,
    _ReceiptItemVisualState.reviewNeeded => Icons.error,
    _ReceiptItemVisualState.newProduct => Icons.error,
    _ReceiptItemVisualState.excluded => Icons.remove_circle_outline,
  };

  Color color(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return switch (this) {
      _ReceiptItemVisualState.matched => colors.primary,
      _ReceiptItemVisualState.reviewNeeded => colors.tertiary,
      _ReceiptItemVisualState.newProduct => colors.error,
      _ReceiptItemVisualState.excluded => colors.onSurfaceVariant,
    };
  }
}

_ReceiptItemVisualState _visualStateForDraft(ReceiptReviewItemDraft draft) {
  if (!draft.canBeSavedToInventory) {
    return _ReceiptItemVisualState.excluded;
  }
  if (!draft.hasCandidates) {
    return _ReceiptItemVisualState.newProduct;
  }
  if (draft.selectedCandidate == null) {
    return _ReceiptItemVisualState.reviewNeeded;
  }
  if (draft.selectionNeedsReview || draft.differsFromSelectedCandidate) {
    return _ReceiptItemVisualState.reviewNeeded;
  }
  return _ReceiptItemVisualState.matched;
}

class _ReceiptDisplayData {
  const _ReceiptDisplayData({
    required this.name,
    required this.brand,
    required this.barcode,
    required this.imageUrl,
    required this.nutrition,
  });

  factory _ReceiptDisplayData.fromDraft(ReceiptReviewItemDraft draft) {
    final selectedCandidate = draft.selectedCandidate;
    if (selectedCandidate != null) {
      return _ReceiptDisplayData(
        name: selectedCandidate.item.name,
        brand: selectedCandidate.item.brand,
        barcode: selectedCandidate.item.normalizedBarcode,
        imageUrl: selectedCandidate.item.imageUrl,
        nutrition: selectedCandidate.item.nutrition,
      );
    }

    return _ReceiptDisplayData(
      name: draft.item.name,
      brand: draft.item.brand,
      barcode: draft.item.normalizedBarcode,
      imageUrl: draft.item.imageUrl,
      nutrition: draft.item.nutrition,
    );
  }

  final String name;
  final String? brand;
  final String? barcode;
  final String? imageUrl;
  final GlobalFoodNutrition? nutrition;
}

String? _ocrHintForDraft({
  required ReceiptReviewItemDraft draft,
  required String displayedName,
}) {
  final ocrName = draft.ocrName?.trim();
  if (ocrName == null || ocrName.isEmpty) {
    return null;
  }
  if (ocrName == displayedName.trim()) {
    return null;
  }
  return ocrName;
}

/// Compact nutrition badges shown for a selected or suggested product.
class InventoryReceiptNutritionChips extends StatelessWidget {
  const InventoryReceiptNutritionChips({super.key, required this.nutrition});

  final GlobalFoodNutrition nutrition;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
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

class _QuantityPill extends StatelessWidget {
  const _QuantityPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppReceiptReviewUi.chipRadius),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppReceiptReviewUi.chipRadius),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

String? _actionLabelFor({
  required BuildContext context,
  required ReceiptReviewItemDraft draft,
  required _ReceiptItemVisualState visualState,
}) {
  final l10n = AppLocalizations.of(context)!;
  if (!draft.canBeSavedToInventory) {
    return null;
  }
  if (visualState == _ReceiptItemVisualState.newProduct) {
    return l10n.inventoryReceiptReviewDetermineAction;
  }
  if (draft.hasCandidates && draft.candidates.length > 1) {
    return l10n.inventoryReceiptReviewSwitchAction;
  }
  return null;
}

class _ReceiptItemActionButton extends StatelessWidget {
  const _ReceiptItemActionButton({
    super.key,
    required this.visualState,
    required this.label,
    required this.onPressed,
  });

  final _ReceiptItemVisualState visualState;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDetermine = visualState == _ReceiptItemVisualState.newProduct;

    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: isDetermine ? colors.primaryContainer : colors.surface,
        foregroundColor: isDetermine
            ? colors.onPrimaryContainer
            : colors.onSurfaceVariant,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppReceiptReviewUi.buttonRadius),
          side: isDetermine
              ? BorderSide.none
              : BorderSide(color: colors.outlineVariant),
        ),
      ),
      icon: Icon(isDetermine ? Icons.search : Icons.swap_horiz, size: 16),
      label: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ReceiptItemDiscountRows extends StatelessWidget {
  const _ReceiptItemDiscountRows({
    required this.item,
    required this.itemIndex,
    required this.currency,
  });

  final InventoryItem item;
  final int itemIndex;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (item.discounts.isEmpty) {
      return const SizedBox.shrink();
    }

    final disabledColor = Theme.of(context).disabledColor;
    final discountTextStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: disabledColor);
    final entries = item.discounts.entries.toList(growable: false);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        children: entries.indexed
            .map((entryWithIndex) {
              final discountIndex = entryWithIndex.$1;
              final discount = entryWithIndex.$2;
              final discountName = discount.key.trim();
              final text = discountName.isEmpty
                  ? '${l10n.inventoryReceiptReviewFieldDiscounts} '
                        '(${currency.format(discount.value)})'
                  : '${l10n.inventoryReceiptReviewFieldDiscounts}: '
                        '$discountName (${currency.format(discount.value)})';
              return Padding(
                key: Key(
                  'receipt_review_discount_row_${itemIndex}_$discountIndex',
                ),
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(
                      Icons.subdirectory_arrow_right,
                      size: 16,
                      color: disabledColor,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(child: Text(text, style: discountTextStyle)),
                  ],
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

/// Thumbnail that resolves a product image directly or via barcode lookup.
class InventoryReceiptSelectionThumbnail extends ConsumerWidget {
  const InventoryReceiptSelectionThumbnail({
    super.key,
    required this.imageUrl,
    this.barcode,
    this.icon = Icons.inventory_2_outlined,
    this.backgroundColor,
    this.foregroundColor,
    this.dimension = 28,
  });

  final String? imageUrl;
  final String? barcode;
  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double dimension;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final normalizedImageUrl = _resolveImageUrl(ref);
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
            ? Image.network(
                normalizedImageUrl,
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

  String? _resolveImageUrl(WidgetRef ref) {
    final directImageUrl = normalizeProductImageUrl(imageUrl);
    if (directImageUrl != null && directImageUrl.isNotEmpty) {
      return directImageUrl;
    }

    final normalizedBarcode = barcode?.trim();
    if (normalizedBarcode == null || normalizedBarcode.isEmpty) {
      return null;
    }

    final resolvedByBarcode = ref.watch(
      inventoryBarcodeImageUrlProvider(
        normalizedBarcode,
      ).select((asyncValue) => asyncValue.asData?.value),
    );
    return normalizeProductImageUrl(resolvedByBarcode);
  }
}
