import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/constants/'
    'inventory_ui_constants.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/shared/widgets/'
    'inventory_receipt_product_selection_widgets.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Receipt review list row that shows one mapped or unresolved item.
class InventoryReceiptReviewItemCard extends StatelessWidget {
  /// The inventory receipt review item card.
  const InventoryReceiptReviewItemCard({
    required this.draft,
    required this.index,
    required this.currency,
    required this.onEditTap,
    required this.onSwitchTap,
    required this.onConfirmTap,
    required this.canConfirm,
    super.key,
    this.isActionLoading = false,
  });

  /// The draft.
  final ReceiptReviewItemDraft draft;

  /// The index.
  final int index;

  /// The currency.
  final NumberFormat currency;

  /// The on edit tap.
  final ValueChanged<String> onEditTap;

  /// The on switch tap.
  final ValueChanged<String> onSwitchTap;

  /// The on confirm tap.
  final VoidCallback onConfirmTap;

  /// Whether confirm.
  final bool canConfirm;

  /// Whether action loading.
  final bool isActionLoading;

  @override
  Widget build(BuildContext context) {
    final draft = this.draft;
    final item = draft.item;
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final viewData = _ReceiptItemCardViewData.fromDraft(context, draft);
    final muted = viewData.isMuted || draft.isConfirmed;
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
      child: AppInkWell(
        key: Key('receipt_review_edit_button_$index'),
        onTap: item.isDiscount ? null : () => onEditTap(item.id),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: AppReceiptReviewSurfaces.panelDecoration(
            colors,
            backgroundColor: viewData.isMuted
                ? colors.surfaceContainerLow
                : draft.isConfirmed
                ? colors.primaryContainer.withValues(alpha: 0.34)
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
                  quantityLabel: '${item.quantity}x',
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
                        isConfirmed: draft.isConfirmed,
                      ),
                      if (!draft.isConfirmed &&
                          (viewData.display.nutrition?.hasAnyNutritionValue ??
                              false)) ...[
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
                        draft: draft,
                        item: item,
                        itemId: item.id,
                        index: index,
                        viewData: viewData,
                        onSwitchTap: onSwitchTap,
                        isActionLoading: isActionLoading,
                        canConfirm: canConfirm,
                        onConfirmTap: onConfirmTap,
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
    required this.isConfirmed,
  });

  final InventoryItem item;
  final NumberFormat currency;
  final _ReceiptItemCardViewData viewData;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final bool isConfirmed;

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
                  color: titleStyle?.color ?? colors.onSurface,
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
            color: isConfirmed
                ? Theme.of(context).disabledColor
                : colors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _ReceiptItemFooter extends StatelessWidget {
  const _ReceiptItemFooter({
    required this.draft,
    required this.item,
    required this.itemId,
    required this.index,
    required this.viewData,
    required this.onSwitchTap,
    required this.isActionLoading,
    required this.canConfirm,
    required this.onConfirmTap,
  });

  final ReceiptReviewItemDraft draft;
  final InventoryItem item;
  final String itemId;
  final int index;
  final _ReceiptItemCardViewData viewData;
  final ValueChanged<String> onSwitchTap;
  final bool isActionLoading;
  final bool canConfirm;
  final VoidCallback onConfirmTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final candidateWeight = viewData.display.packageWeight?.trim();
    final itemWeight = item.weight?.trim();
    final displayedWeight = itemWeight?.isNotEmpty == true
        ? itemWeight
        : candidateWeight;
    final shouldHighlightWeight =
        draft.weightNeedsAttention && !draft.isConfirmed;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (displayedWeight case final weight? when weight.isNotEmpty)
                _QuantityPill(
                  label: weight,
                  highlighted: shouldHighlightWeight,
                ),
              if (viewData.isMuted)
                _StatusPill(label: l10n.inventoryReceiptReviewExcludedTag),
            ],
          ),
        ),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            if (viewData.actionLabel != null)
              _ReceiptItemActionButton(
                key: viewData.actionButtonKey(index),
                visualState: viewData.visualState,
                isLoading: isActionLoading,
                onPressed: _handleAction,
              ),
            if (draft.canBeSavedToInventory)
              _ReceiptItemConfirmButton(
                index: index,
                isConfirmed: draft.isConfirmed,
                isEnabled: canConfirm,
                onPressed: onConfirmTap,
              ),
          ],
        ),
      ],
    );
  }

  void _handleAction() {
    if (isActionLoading) {
      return;
    }
    onSwitchTap(itemId);
  }
}

class _ReceiptItemLeading extends StatelessWidget {
  const _ReceiptItemLeading({
    required this.visualState,
    required this.display,
    required this.quantityLabel,
  });

  final _ReceiptItemVisualState visualState;
  final _ReceiptDisplayData display;
  final String quantityLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            InventoryReceiptSelectionThumbnail(
              imageUrl: display.imageUrl,
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
        ),
        const SizedBox(height: AppSpacing.sm),
        _QuantityPill(label: quantityLabel),
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
  if (draft.isConfirmed) {
    return _ReceiptItemVisualState.matched;
  }
  if (!draft.hasCandidates) {
    return _ReceiptItemVisualState.newProduct;
  }
  return _ReceiptItemVisualState.reviewNeeded;
}

class _ReceiptDisplayData {
  const _ReceiptDisplayData({
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.packageWeight,
    required this.nutrition,
  });

  factory _ReceiptDisplayData.fromDraft(ReceiptReviewItemDraft draft) {
    return _ReceiptDisplayData(
      name: draft.item.name,
      brand: draft.item.brand,
      imageUrl: draft.item.imageUrl,
      packageWeight: draft.selectedCandidate?.item.packageWeight,
      nutrition: draft.item.nutrition,
    );
  }

  final String name;
  final String? brand;
  final String? imageUrl;
  final String? packageWeight;
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

class _QuantityPill extends StatelessWidget {
  const _QuantityPill({required this.label, this.highlighted = false});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = highlighted
        ? colors.tertiaryContainer
        : colors.surfaceContainerLowest;
    final foreground = highlighted
        ? colors.onTertiaryContainer
        : colors.onSurfaceVariant;
    final border = highlighted ? colors.tertiary : colors.outlineVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppReceiptReviewUi.chipRadius),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: foreground,
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
  if (draft.hasCandidates) {
    return l10n.inventoryReceiptReviewSwitchAction;
  }
  if (visualState == _ReceiptItemVisualState.newProduct) {
    return l10n.inventoryReceiptReviewCandidatesAction;
  }
  return null;
}

class _ReceiptItemActionButton extends StatelessWidget {
  const _ReceiptItemActionButton({
    required this.visualState,
    required this.onPressed,
    required this.isLoading,
    super.key,
  });

  final _ReceiptItemVisualState visualState;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final isDetermine = visualState == _ReceiptItemVisualState.newProduct;
    final tooltip = isDetermine
        ? l10n.inventoryReceiptReviewCandidatesAction
        : l10n.inventoryReceiptReviewSwitchAction;

    return Tooltip(
      message: tooltip,
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          backgroundColor: isDetermine
              ? colors.primaryContainer
              : colors.surface,
          foregroundColor: isDetermine
              ? colors.onPrimaryContainer
              : colors.onSurfaceVariant,
          padding: const EdgeInsets.all(12),
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppReceiptReviewUi.buttonRadius,
            ),
            side: isDetermine
                ? BorderSide.none
                : BorderSide(color: colors.outlineVariant),
          ),
        ),
        child: isLoading
            ? SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDetermine
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant,
                ),
              )
            : Icon(isDetermine ? Icons.search : Icons.swap_horiz, size: 20),
      ),
    );
  }
}

class _ReceiptItemConfirmButton extends StatelessWidget {
  const _ReceiptItemConfirmButton({
    required this.index,
    required this.isConfirmed,
    required this.isEnabled,
    required this.onPressed,
  });

  final int index;
  final bool isConfirmed;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return Tooltip(
      message: isConfirmed
          ? l10n.inventoryReceiptReviewUndoConfirmAction
          : l10n.inventoryReceiptReviewConfirmItemAction,
      child: FilledButton(
        key: Key('receipt_review_confirm_button_$index'),
        onPressed: isEnabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: isConfirmed
              ? colors.primaryContainer
              : colors.primary,
          foregroundColor: isConfirmed
              ? colors.onPrimaryContainer
              : colors.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          minimumSize: const Size(48, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppReceiptReviewUi.buttonRadius,
            ),
          ),
        ),
        child: Icon(isConfirmed ? Icons.undo : Icons.check, size: 18),
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
