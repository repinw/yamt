import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_expand_section.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_main_section.dart';
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
    required this.onThrowAwayPressed,
  });

  final FridgeItem item;
  final AppLocalizations l10n;
  final NumberFormat currency;
  final Future<bool> Function(String itemId) onDeletePressed;
  final Future<bool> Function(String itemId) onThrowAwayPressed;

  @override
  State<InventoryItemRow> createState() => _InventoryItemRowState();
}

class _InventoryItemRowState extends State<InventoryItemRow> {
  var _isExpanded = false;
  var _isWorking = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final item = widget.item;
    final brand = item.brand?.trim() ?? '';
    final hasBrand = brand.isNotEmpty;
    final initialQuantity = item.initialQuantity < 1 ? 1 : item.initialQuantity;
    final remainingRatio = (item.quantity / initialQuantity).clamp(0.0, 1.0);
    final snapshot = InventoryItemRowSnapshot.fromFridgeItem(item);

    final viewData = InventoryItemRowViewData(
      rowBorderColor: colors.outlineVariant,
      expandHintColor: colors.onSurfaceVariant,
      unitPriceLabel:
          '${widget.l10n.inventoryReceiptReviewFieldUnitPrice}: '
          '${widget.currency.format(item.unitPrice)}',
      nameTextStyle:
          Theme.of(context).textTheme.titleMedium ?? const TextStyle(),
      hasBrand: hasBrand,
      brand: brand,
      statusText: null,
      statusColor: null,
      remainingRatio: remainingRatio,
      remainingLabel: '${item.quantity}/$initialQuantity',
      hasWeight: (item.weight ?? '').isNotEmpty,
      isPrimaryActionEnabled: !_isWorking,
      eatActionBackgroundColor: colors.secondaryContainer,
      disabledActionBackgroundColor: colors.surfaceContainerHighest,
      eatActionBorderColor: colors.outlineVariant,
      disabledActionBorderColor: colors.outlineVariant.withValues(alpha: 0.5),
      primaryActionTooltip: widget.l10n.inventoryItemEatAction,
      primaryActionIcon: Icons.restaurant_menu,
      eatActionIconColor: colors.onSecondaryContainer,
      disabledActionIconColor: colors.onSurfaceVariant,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InventoryItemRowMainSection(
              item: snapshot,
              viewData: viewData,
              onPrimaryActionPressed: _isWorking ? null : _onThrowAwayPressed,
            ),
            const SizedBox(height: AppSpacing.xs),
            InventoryItemRowExpandSection(
              isExpanded: _isExpanded,
              viewData: viewData,
              colorScheme: colors,
              deleteLabel: widget.l10n.inventoryItemDeleteAction,
              throwAwayLabel: widget.l10n.inventoryItemThrowAwayAction,
              onDeletePressed: _isWorking ? () {} : _onDeletePressed,
              onThrowAwayPressed: _isWorking ? null : _onThrowAwayPressed,
              onToggleExpanded: _toggleExpanded,
            ),
          ],
        ),
      ),
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _onDeletePressed() {
    unawaited(_runAction(widget.onDeletePressed));
  }

  void _onThrowAwayPressed() {
    unawaited(_runAction(widget.onThrowAwayPressed));
  }

  Future<void> _runAction(Future<bool> Function(String itemId) action) async {
    if (_isWorking) {
      return;
    }

    setState(() {
      _isWorking = true;
    });
    final success = await action(widget.item.id);
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
}
