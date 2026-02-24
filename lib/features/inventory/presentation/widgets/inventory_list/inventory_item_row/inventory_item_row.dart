import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_amount_input_dialog.dart';
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
import 'package:yamt/l10n/app_localizations.dart';

class InventoryItemRow extends StatefulWidget {
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
  State<InventoryItemRow> createState() => _InventoryItemRowState();
}

class _InventoryItemRowState extends State<InventoryItemRow> {
  var _isExpanded = false;
  var _isWorking = false;

  @override
  Widget build(BuildContext context) {
    final layoutData = _buildLayoutData(context);

    return _InventoryItemRowCard(
      layoutData: layoutData,
      isExpanded: _isExpanded,
      deleteLabel: widget.l10n.inventoryItemDeleteAction,
      throwAwayLabel: widget.l10n.inventoryItemThrowAwayAction,
      onToggleExpanded: _toggleExpanded,
      onDeletePressed: _isWorking ? () {} : _onDeletePressed,
      onEatPressed: layoutData.isAdjustActionEnabled ? _onEatPressed : null,
      onThrowAwayPressed: layoutData.isAdjustActionEnabled
          ? _onThrowAwayPressed
          : null,
    );
  }

  _InventoryItemRowLayoutData _buildLayoutData(BuildContext context) {
    final item = widget.item;
    final hasAdjustableAmount = _buildInputConfig(item) != null;
    return _InventoryItemRowLayoutData.fromItem(
      context: context,
      item: item,
      l10n: widget.l10n,
      currency: widget.currency,
      hasAdjustableAmount: hasAdjustableAmount,
      isWorking: _isWorking,
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _onDeletePressed() {
    unawaited(_runAction(() => widget.onDeletePressed(widget.item.id)));
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

    await _runAction(() => action(widget.item.id, amount));
  }

  Future<void> _runAction(Future<bool> Function() action) async {
    if (_isWorking) {
      return;
    }

    setState(() {
      _isWorking = true;
    });
    final success = await action();
    if (!mounted) {
      return;
    }
    setState(() {
      _isWorking = false;
    });

    if (success) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(widget.l10n.inventoryItemActionFailed)),
    );
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
        suffixText: _unitSuffix(item.amountUnit!),
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

  String _unitSuffix(FridgeAmountUnit unit) {
    return switch (unit) {
      FridgeAmountUnit.gram => 'g',
      FridgeAmountUnit.milliliter => 'ml',
      FridgeAmountUnit.piece => 'pc',
    };
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
    required this.isAdjustActionEnabled,
  });

  factory _InventoryItemRowLayoutData.fromItem({
    required BuildContext context,
    required FridgeItem item,
    required AppLocalizations l10n,
    required NumberFormat currency,
    required bool hasAdjustableAmount,
    required bool isWorking,
  }) {
    final colors = Theme.of(context).colorScheme;
    final eatActionColors = AppInventoryEatActionColors.fromColorScheme(colors);
    final progress = const InventoryItemProgressCalculator().fromItem(item);
    final brand = item.brand?.trim() ?? '';
    final hasBrand = brand.isNotEmpty;
    final isAdjustActionEnabled = !isWorking && hasAdjustableAmount;

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
        statusText: null,
        statusColor: null,
        remainingRatio: progress.remainingRatio,
        remainingLabel: progress.remainingLabel,
        segmentedByUnits: progress.segmentedByUnits,
        isPrimaryActionEnabled: isAdjustActionEnabled,
        eatActionBackgroundColor: eatActionColors.backgroundColor,
        disabledActionBackgroundColor: colors.surfaceContainerHighest,
        eatActionBorderColor: eatActionColors.borderColor,
        disabledActionBorderColor: colors.outlineVariant.withValues(alpha: 0.5),
        primaryActionTooltip: l10n.inventoryItemEatAction,
        primaryActionIcon: Icons.restaurant_menu,
        eatActionIconColor: eatActionColors.iconColor,
        disabledActionIconColor: colors.onSurfaceVariant,
      ),
      isAdjustActionEnabled: isAdjustActionEnabled,
    );
  }

  final ColorScheme colorScheme;
  final InventoryItemRowSnapshot snapshot;
  final InventoryItemRowViewData viewData;
  final bool isAdjustActionEnabled;
}

class _InventoryItemRowCard extends StatelessWidget {
  const _InventoryItemRowCard({
    required this.layoutData,
    required this.isExpanded,
    required this.deleteLabel,
    required this.throwAwayLabel,
    required this.onToggleExpanded,
    required this.onDeletePressed,
    required this.onEatPressed,
    required this.onThrowAwayPressed,
  });

  final _InventoryItemRowLayoutData layoutData;
  final bool isExpanded;
  final String deleteLabel;
  final String throwAwayLabel;
  final VoidCallback onToggleExpanded;
  final VoidCallback onDeletePressed;
  final VoidCallback? onEatPressed;
  final VoidCallback? onThrowAwayPressed;

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
          onEatPressed: onEatPressed,
          onThrowAwayPressed: onThrowAwayPressed,
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
    required this.onEatPressed,
    required this.onThrowAwayPressed,
  });

  final _InventoryItemRowLayoutData layoutData;
  final bool isExpanded;
  final String deleteLabel;
  final String throwAwayLabel;
  final VoidCallback onToggleExpanded;
  final VoidCallback onDeletePressed;
  final VoidCallback? onEatPressed;
  final VoidCallback? onThrowAwayPressed;

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
            onPrimaryActionPressed: onEatPressed,
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
          ),
        ],
      ),
    );
  }
}
