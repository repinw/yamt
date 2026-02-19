import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/scanner/presentation/widgets/inventory_receipt_item_editor_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

class InventoryReceiptReviewSheet extends StatefulWidget {
  const InventoryReceiptReviewSheet({
    super.key,
    required this.items,
    required this.onCancelTap,
    required this.onSaveTap,
  });

  final List<FridgeItem> items;
  final VoidCallback onCancelTap;
  final Future<void> Function(List<FridgeItem> items) onSaveTap;

  @override
  State<InventoryReceiptReviewSheet> createState() =>
      _InventoryReceiptReviewSheetState();
}

class _InventoryReceiptReviewSheetState
    extends State<InventoryReceiptReviewSheet> {
  late final List<FridgeItem> _items;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _items = List<FridgeItem>.from(widget.items);
  }

  bool get _canSave {
    if (_isSaving) {
      return false;
    }
    return _items.any((item) => item.canBeSavedToFridge);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final currency = NumberFormat.currency(locale: locale, symbol: '€');
    final saveChild = _isSaving
        ? const SizedBox.square(
            dimension: AppSpacing.xl,
            child: CircularProgressIndicator(
              strokeWidth: AppSizes.progressStrokeWidth,
            ),
          )
        : Text(l10n.inventoryReceiptReviewSaveAction);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xxxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.inventoryReceiptReviewTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _PriceOverview(
              totalPrice: _totalPrice,
              storablePrice: _storablePrice,
              excludedPrice: _excludedPrice,
              currency: currency,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildItemsList(context, l10n),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancelTap,
                    child: Text(l10n.inventoryReceiptReviewCancelAction),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    key: const Key('receipt_review_save_button'),
                    onPressed: _canSave ? _saveReviewedItems : null,
                    child: saveChild,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(BuildContext context, AppLocalizations l10n) {
    if (_items.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(l10n.inventoryReceiptReviewEmpty),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.5,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _items.length,
        itemBuilder: (context, index) {
          return _buildItemTile(context, l10n, index, _items[index]);
        },
      ),
    );
  }

  Widget _buildItemTile(
    BuildContext context,
    AppLocalizations l10n,
    int index,
    FridgeItem item,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final disabledColor = Theme.of(context).disabledColor;
    final muted = item.isReviewOnly;
    final titleStyle = muted
        ? textTheme.bodyLarge?.copyWith(color: disabledColor)
        : textTheme.bodyLarge;
    final subtitleStyle = muted
        ? textTheme.bodyMedium?.copyWith(color: disabledColor)
        : textTheme.bodyMedium;
    final subtitle = '${item.quantity}x · ${item.storeName}';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(item.name, style: titleStyle),
      subtitle: Text(subtitle, style: subtitleStyle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (muted)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: Text(
                l10n.inventoryReceiptReviewExcludedTag,
                style: textTheme.labelMedium?.copyWith(color: disabledColor),
              ),
            ),
          IconButton(
            key: Key('receipt_review_edit_button_$index'),
            tooltip: l10n.inventoryReceiptReviewEditAction,
            onPressed: () => _openItemEditor(index),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }

  Future<void> _openItemEditor(int index) async {
    final editedItem = await showModalBottomSheet<FridgeItem>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return InventoryReceiptItemEditorSheet(item: _items[index]);
      },
    );
    if (!mounted || editedItem == null) {
      return;
    }
    setState(() {
      _items[index] = editedItem;
    });
  }

  Future<void> _saveReviewedItems() async {
    if (!_canSave) {
      return;
    }

    setState(() {
      _isSaving = true;
    });
    await widget.onSaveTap(List<FridgeItem>.from(_items));
    if (!mounted) {
      return;
    }
    setState(() {
      _isSaving = false;
    });
  }

  double get _totalPrice => _sumPrice(_items);

  double get _storablePrice {
    final storable = _items.where((item) => item.canBeSavedToFridge);
    return _sumPrice(storable);
  }

  double get _excludedPrice {
    final excluded = _items.where((item) => item.isReviewOnly);
    return _sumPrice(excluded);
  }

  double _sumPrice(Iterable<FridgeItem> items) {
    return items.fold(0.0, (sum, item) => sum + _linePrice(item));
  }

  double _linePrice(FridgeItem item) {
    return item.quantity * item.unitPrice;
  }
}

class _PriceOverview extends StatelessWidget {
  const _PriceOverview({
    required this.totalPrice,
    required this.storablePrice,
    required this.excludedPrice,
    required this.currency,
  });

  final double totalPrice;
  final double storablePrice;
  final double excludedPrice;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.inventoryReceiptReviewPriceTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            _PriceRow(
              label: l10n.inventoryReceiptReviewPriceTotal,
              value: currency.format(totalPrice),
            ),
            const SizedBox(height: AppSpacing.xxs * 2),
            _PriceRow(
              label: l10n.inventoryReceiptReviewPriceSavable,
              value: currency.format(storablePrice),
            ),
            const SizedBox(height: AppSpacing.xxs * 2),
            _PriceRow(
              label: l10n.inventoryReceiptReviewPriceExcluded,
              value: currency.format(excludedPrice),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
