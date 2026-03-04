import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/config/barcode_backfill_feature_flags.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/data/calorie_barcode_backfill_repository.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/inventory/provider/fridge_items_controller.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_amount_input_dialog.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_action_coordinator.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_expand_section.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_main_section.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_progress.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_snapshot.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_view_data.dart';
import 'package:yamt/features/inventory/presentation/'
    'fridge_amount_unit_l10n.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_facade.dart';
import 'package:yamt/l10n/app_localizations.dart';

class InventoryItemRow extends ConsumerStatefulWidget {
  const InventoryItemRow({
    super.key,
    required this.item,
    required this.l10n,
    required this.currency,
    required this.onDeletePressed,
    required this.onEatPressed,
    required this.onThrowAwayPressed,
  });

  final FridgeItem item;
  final AppLocalizations l10n;
  final NumberFormat currency;
  final Future<bool> Function(String itemId) onDeletePressed;
  final Future<bool> Function(String itemId, int amount) onEatPressed;
  final Future<bool> Function(String itemId, int amount) onThrowAwayPressed;

  @override
  ConsumerState<InventoryItemRow> createState() => _InventoryItemRowState();
}

class _InventoryItemRowState extends ConsumerState<InventoryItemRow> {
  var _isExpanded = false;
  var _isWorking = false;
  late final InventoryItemRowActionCoordinator _actionCoordinator;

  @override
  void initState() {
    super.initState();
    _actionCoordinator = InventoryItemRowActionCoordinator(
      isWorking: () => _isWorking,
      setWorking: _setWorking,
      isMounted: () => mounted,
      showSnackBar: _showActionSnackBar,
      defaultFailureMessage: widget.l10n.inventoryItemActionFailed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAlreadyInShoppingList = ref.watch(
      isInventoryItemInActiveShoppingListProvider(widget.item),
    );
    final featureFlags = ref.watch(barcodeBackfillFeatureFlagsProvider);
    final canRetryBarcodeLookup =
        widget.item.barcodeStatus != InventoryBarcodeStatus.resolved &&
        !_isWorking;
    final layoutData = _buildLayoutData(
      context,
      isAlreadyInShoppingList: isAlreadyInShoppingList,
      showBarcodeMarkers: featureFlags.showInventoryBarcodeMarkers,
    );
    final onPrimaryActionPressed = _buildPrimaryActionPressed(layoutData);

    return _InventoryItemRowCard(
      layoutData: layoutData,
      isExpanded: _isExpanded,
      deleteLabel: widget.l10n.inventoryItemDeleteAction,
      throwAwayLabel: widget.l10n.inventoryItemThrowAwayAction,
      onToggleExpanded: _toggleExpanded,
      onDeletePressed: _isWorking ? () {} : _onDeletePressed,
      onPrimaryActionPressed: onPrimaryActionPressed,
      onThrowAwayPressed: layoutData.isAdjustActionEnabled
          ? _onThrowAwayPressed
          : null,
      retryBarcodeLabel: widget.l10n.inventoryBarcodeRetryAction,
      onRetryBarcodePressed: canRetryBarcodeLookup
          ? _onRetryBarcodePressed
          : null,
    );
  }

  VoidCallback? _buildPrimaryActionPressed(
    _InventoryItemRowLayoutData layoutData,
  ) {
    if (!layoutData.isPrimaryActionEnabled) {
      return null;
    }
    if (layoutData.isBuyAgainPrimaryAction) {
      return _onBuyAgainPressed;
    }
    return _onEatPressed;
  }

  _InventoryItemRowLayoutData _buildLayoutData(
    BuildContext context, {
    required bool isAlreadyInShoppingList,
    required bool showBarcodeMarkers,
  }) {
    final item = widget.item;
    final hasAdjustableAmount = _buildInputConfig(item) != null;
    return _InventoryItemRowLayoutData.fromItem(
      context: context,
      item: item,
      l10n: widget.l10n,
      currency: widget.currency,
      hasAdjustableAmount: hasAdjustableAmount,
      isWorking: _isWorking,
      isAlreadyInShoppingList: isAlreadyInShoppingList,
      showBarcodeMarkers: showBarcodeMarkers,
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _setWorking(bool isWorking) {
    setState(() {
      _isWorking = isWorking;
    });
  }

  void _onDeletePressed() {
    unawaited(
      _actionCoordinator.runAction(
        () => widget.onDeletePressed(widget.item.id),
      ),
    );
  }

  void _onEatPressed() {
    unawaited(
      _requestAmountAndRunAction(
        action: widget.onEatPressed,
        title: widget.l10n.inventoryItemEatAction,
        confirmLabel: widget.l10n.inventoryItemEatAction,
      ),
    );
  }

  void _onThrowAwayPressed() {
    unawaited(
      _requestAmountAndRunAction(
        action: widget.onThrowAwayPressed,
        title: widget.l10n.inventoryItemThrowAwayAction,
        confirmLabel: widget.l10n.inventoryItemThrowAwayAction,
      ),
    );
  }

  void _onBuyAgainPressed() {
    final controller = ref.read(fridgeItemsControllerProvider.notifier);
    unawaited(
      _actionCoordinator.runAction(
        () => controller.buyAgainItem(widget.item),
        successMessage: widget.l10n.inventoryItemBuyAgainSucceeded,
        failureMessage: widget.l10n.inventoryItemActionFailed,
      ),
    );
  }

  void _onRetryBarcodePressed() {
    final item = widget.item;
    final backfillRepository = ref.read(
      calorieBarcodeBackfillRepositoryProvider,
    );
    unawaited(
      _actionCoordinator.runAction(() async {
        final queued = await backfillRepository.enqueueFingerprintLookup(
          itemId: item.id,
          fingerprint: item.resolvedFoodFingerprint,
          itemName: item.name,
          brand: item.brand,
          trigger: 'manual_search',
        );
        return queued;
      }, successMessage: widget.l10n.inventoryBarcodeLookupQueued),
    );
  }

  Future<void> _requestAmountAndRunAction({
    required Future<bool> Function(String itemId, int amount) action,
    required String title,
    required String confirmLabel,
  }) async {
    final config = _buildInputConfig(widget.item);
    if (config == null) {
      return;
    }

    final amount = await showDialog<int>(
      context: context,
      builder: (context) {
        return InventoryItemAmountInputDialog(
          title: title,
          confirmLabel: confirmLabel,
          cancelLabel: widget.l10n.inventoryReceiptReviewCancelAction,
          fieldLabel: config.fieldLabel,
          invalidAmountMessage: widget.l10n.inventoryReceiptReviewInvalidNumber,
          maxAmount: config.maxAmount,
          suffixText: config.suffixText,
        );
      },
    );
    if (!mounted || amount == null) {
      return;
    }

    await _actionCoordinator.runAction(() => action(widget.item.id, amount));
  }

  void _showActionSnackBar(String message) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  _ItemAmountInputConfig? _buildInputConfig(FridgeItem item) {
    if (item.usesAmountProgress) {
      final maxAmount = item.currentAmount > 0 ? item.currentAmount : 0;
      if (maxAmount < 1 || item.amountUnit == null) {
        return null;
      }
      return _ItemAmountInputConfig(
        maxAmount: maxAmount,
        fieldLabel: widget.l10n.inventoryReceiptReviewFieldWeight,
        suffixText: item.amountUnit!.localizedName(widget.l10n),
      );
    }

    final maxAmount = item.quantity > 0 ? item.quantity : 0;
    if (maxAmount < 1) {
      return null;
    }
    return _ItemAmountInputConfig(
      maxAmount: maxAmount,
      fieldLabel: widget.l10n.inventoryReceiptReviewFieldQuantity,
      suffixText: null,
    );
  }
}

class _ItemAmountInputConfig {
  const _ItemAmountInputConfig({
    required this.maxAmount,
    required this.fieldLabel,
    required this.suffixText,
  });

  final int maxAmount;
  final String fieldLabel;
  final String? suffixText;
}

class _InventoryItemRowLayoutData {
  const _InventoryItemRowLayoutData({
    required this.colorScheme,
    required this.snapshot,
    required this.viewData,
    required this.isPrimaryActionEnabled,
    required this.isBuyAgainPrimaryAction,
    required this.isAdjustActionEnabled,
  });

  factory _InventoryItemRowLayoutData.fromItem({
    required BuildContext context,
    required FridgeItem item,
    required AppLocalizations l10n,
    required NumberFormat currency,
    required bool hasAdjustableAmount,
    required bool isWorking,
    required bool isAlreadyInShoppingList,
    required bool showBarcodeMarkers,
  }) {
    final colors = Theme.of(context).colorScheme;
    final isBuyAgainPrimaryAction = item.isFullyConsumed;
    final eatActionColors = AppInventoryEatActionColors.fromColorScheme(colors);
    final buyAgainActionColors =
        AppInventoryBuyAgainActionColors.fromColorScheme(colors);
    final progress = const InventoryItemProgressCalculator().fromItem(item);
    final brand = item.brand?.trim() ?? '';
    final hasBrand = brand.isNotEmpty;
    final isAdjustActionEnabled = !isWorking && hasAdjustableAmount;
    final isPrimaryActionEnabled =
        !isWorking &&
        (isBuyAgainPrimaryAction
            ? !isAlreadyInShoppingList
            : isAdjustActionEnabled);

    final marker = showBarcodeMarkers
        ? _barcodeStatusMarker(
            l10n: l10n,
            colorScheme: colors,
            status: item.barcodeStatus,
          )
        : null;

    return _InventoryItemRowLayoutData(
      colorScheme: colors,
      snapshot: InventoryItemRowSnapshot.fromFridgeItem(item),
      viewData: InventoryItemRowViewData(
        rowBorderColor: colors.outlineVariant,
        expandHintColor: colors.onSurfaceVariant,
        unitPriceLabel:
            '${l10n.inventoryReceiptReviewFieldUnitPrice}: '
            '${currency.format(item.unitPrice)}',
        nameTextStyle:
            Theme.of(context).textTheme.titleMedium ?? const TextStyle(),
        hasBrand: hasBrand,
        brand: brand,
        statusText: marker?.text,
        statusColor: marker?.color,
        remainingRatio: progress.remainingRatio,
        remainingLabel: progress.remainingLabel,
        segmentedByUnits: progress.segmentedByUnits,
        isPrimaryActionEnabled: isPrimaryActionEnabled,
        isBuyAgainPrimaryAction: isBuyAgainPrimaryAction,
        eatActionBackgroundColor: isBuyAgainPrimaryAction
            ? buyAgainActionColors.backgroundColor
            : eatActionColors.backgroundColor,
        disabledActionBackgroundColor: colors.surfaceContainerHighest,
        eatActionBorderColor: isBuyAgainPrimaryAction
            ? buyAgainActionColors.borderColor
            : eatActionColors.borderColor,
        disabledActionBorderColor: colors.outlineVariant.withValues(alpha: 0.5),
        primaryActionTooltip: isBuyAgainPrimaryAction
            ? l10n.inventoryItemBuyAgainAction
            : l10n.inventoryItemEatAction,
        primaryActionIcon: isBuyAgainPrimaryAction
            ? Icons.shopping_cart_checkout_rounded
            : Icons.restaurant_menu,
        eatActionIconColor: isBuyAgainPrimaryAction
            ? buyAgainActionColors.iconColor
            : eatActionColors.iconColor,
        disabledActionIconColor: colors.onSurfaceVariant,
      ),
      isPrimaryActionEnabled: isPrimaryActionEnabled,
      isBuyAgainPrimaryAction: isBuyAgainPrimaryAction,
      isAdjustActionEnabled: isAdjustActionEnabled,
    );
  }

  final ColorScheme colorScheme;
  final InventoryItemRowSnapshot snapshot;
  final InventoryItemRowViewData viewData;
  final bool isPrimaryActionEnabled;
  final bool isBuyAgainPrimaryAction;
  final bool isAdjustActionEnabled;
}

({String text, Color color})? _barcodeStatusMarker({
  required AppLocalizations l10n,
  required ColorScheme colorScheme,
  required InventoryBarcodeStatus status,
}) {
  return switch (status) {
    InventoryBarcodeStatus.resolved => null,
    InventoryBarcodeStatus.pending => (
      text: l10n.inventoryBarcodeStatusPending,
      color: colorScheme.tertiary,
    ),
    InventoryBarcodeStatus.missing => (
      text: l10n.inventoryBarcodeStatusMissing,
      color: colorScheme.error,
    ),
  };
}

class _InventoryItemRowCard extends StatelessWidget {
  const _InventoryItemRowCard({
    required this.layoutData,
    required this.isExpanded,
    required this.deleteLabel,
    required this.throwAwayLabel,
    required this.onToggleExpanded,
    required this.onDeletePressed,
    required this.onPrimaryActionPressed,
    required this.onThrowAwayPressed,
    required this.retryBarcodeLabel,
    required this.onRetryBarcodePressed,
  });

  final _InventoryItemRowLayoutData layoutData;
  final bool isExpanded;
  final String deleteLabel;
  final String throwAwayLabel;
  final VoidCallback onToggleExpanded;
  final VoidCallback onDeletePressed;
  final VoidCallback? onPrimaryActionPressed;
  final VoidCallback? onThrowAwayPressed;
  final String retryBarcodeLabel;
  final VoidCallback? onRetryBarcodePressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onToggleExpanded,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: _InventoryItemRowBody(
          layoutData: layoutData,
          isExpanded: isExpanded,
          deleteLabel: deleteLabel,
          throwAwayLabel: throwAwayLabel,
          onToggleExpanded: onToggleExpanded,
          onDeletePressed: onDeletePressed,
          onPrimaryActionPressed: onPrimaryActionPressed,
          onThrowAwayPressed: onThrowAwayPressed,
          retryBarcodeLabel: retryBarcodeLabel,
          onRetryBarcodePressed: onRetryBarcodePressed,
        ),
      ),
    );
  }
}

class _InventoryItemRowBody extends StatelessWidget {
  const _InventoryItemRowBody({
    required this.layoutData,
    required this.isExpanded,
    required this.deleteLabel,
    required this.throwAwayLabel,
    required this.onToggleExpanded,
    required this.onDeletePressed,
    required this.onPrimaryActionPressed,
    required this.onThrowAwayPressed,
    required this.retryBarcodeLabel,
    required this.onRetryBarcodePressed,
  });

  final _InventoryItemRowLayoutData layoutData;
  final bool isExpanded;
  final String deleteLabel;
  final String throwAwayLabel;
  final VoidCallback onToggleExpanded;
  final VoidCallback onDeletePressed;
  final VoidCallback? onPrimaryActionPressed;
  final VoidCallback? onThrowAwayPressed;
  final String retryBarcodeLabel;
  final VoidCallback? onRetryBarcodePressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppInsets.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InventoryItemRowMainSection(
            item: layoutData.snapshot,
            viewData: layoutData.viewData,
            onPrimaryActionPressed: onPrimaryActionPressed,
          ),
          const SizedBox(height: AppSpacing.xs),
          InventoryItemRowExpandSection(
            isExpanded: isExpanded,
            viewData: layoutData.viewData,
            colorScheme: layoutData.colorScheme,
            deleteLabel: deleteLabel,
            throwAwayLabel: throwAwayLabel,
            onDeletePressed: onDeletePressed,
            onThrowAwayPressed: onThrowAwayPressed,
            onToggleExpanded: onToggleExpanded,
            retryBarcodeLabel: retryBarcodeLabel,
            onRetryBarcodePressed: onRetryBarcodePressed,
          ),
        ],
      ),
    );
  }
}
