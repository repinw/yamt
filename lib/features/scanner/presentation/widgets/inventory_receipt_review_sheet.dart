import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_processor.dart';
import 'package:yamt/features/scanner/domain/receipt_review_price_summary.dart';
import 'inventory_receipt_item_editor_sheet.dart';
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
  static const _priceSummaryCalculator = ReceiptReviewPriceSummaryCalculator();
  static const _itemProcessor = ReceiptReviewItemProcessor();

  late final List<FridgeItem> _items;
  late final ReceiptReviewMetadata _receiptMetadata;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    final result = _itemProcessor.process(widget.items);
    _items = result.items;
    _receiptMetadata = result.metadata;
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
    final priceSummary = _priceSummaryCalculator.calculate(_items);

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
            _ReceiptMetadataOverview(
              storeName: _receiptMetadata.storeName,
              receiptDate: _receiptMetadata.receiptDate,
            ),
            const SizedBox(height: AppSpacing.md),
            _PriceOverview(
              totalPrice: priceSummary.totalPrice,
              storablePrice: priceSummary.storablePrice,
              excludedPrice: priceSummary.excludedPrice,
              currency: currency,
            ),
            const SizedBox(height: AppSpacing.md),
            _ReceiptItemsSection(items: _items, onEditTap: _openItemEditor),
            const SizedBox(height: AppSpacing.md),
            _ReceiptReviewActionsRow(
              isSaving: _isSaving,
              canSave: _canSave,
              onCancelTap: widget.onCancelTap,
              onSaveTap: _saveReviewedItems,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openItemEditor(int index) async {
    if (_items[index].isDiscount) {
      return;
    }

    final editedItem = await showModalBottomSheet<FridgeItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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
}

class _ReceiptReviewActionsRow extends StatelessWidget {
  const _ReceiptReviewActionsRow({
    required this.isSaving,
    required this.canSave,
    required this.onCancelTap,
    required this.onSaveTap,
  });

  final bool isSaving;
  final bool canSave;
  final VoidCallback onCancelTap;
  final VoidCallback onSaveTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final saveChild = isSaving
        ? const SizedBox.square(
            dimension: AppSpacing.xl,
            child: CircularProgressIndicator(
              strokeWidth: AppSizes.progressStrokeWidth,
            ),
          )
        : Text(l10n.inventoryReceiptReviewSaveAction);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancelTap,
            child: Text(l10n.inventoryReceiptReviewCancelAction),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: FilledButton(
            key: const Key('receipt_review_save_button'),
            onPressed: canSave ? onSaveTap : null,
            child: saveChild,
          ),
        ),
      ],
    );
  }
}

class _ReceiptItemsSection extends StatelessWidget {
  const _ReceiptItemsSection({required this.items, required this.onEditTap});

  final List<FridgeItem> items;
  final ValueChanged<int> onEditTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(l10n.inventoryReceiptReviewEmpty),
      );
    }

    final locale = Localizations.localeOf(context).toLanguageTag();
    final currency = NumberFormat.currency(locale: locale, symbol: '€');

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.5,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Column(
            children: [
              _buildItemTile(
                context: context,
                l10n: l10n,
                item: item,
                index: index,
              ),
              ..._buildDiscountRows(
                context: context,
                l10n: l10n,
                item: item,
                itemIndex: index,
                currency: currency,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItemTile({
    required BuildContext context,
    required AppLocalizations l10n,
    required FridgeItem item,
    required int index,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final disabledColor = Theme.of(context).disabledColor;
    final muted = item.isReviewOnly;
    final titleStyle = muted
        ? textTheme.bodyLarge?.copyWith(color: disabledColor)
        : textTheme.bodyLarge;
    final subtitleStyle = muted
        ? textTheme.bodyMedium?.copyWith(color: disabledColor)
        : textTheme.bodyMedium;
    final subtitle = _buildItemSubtitle(context: context, item: item);
    final canEdit = !item.isDiscount;

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
          if (canEdit)
            IconButton(
              key: Key('receipt_review_edit_button_$index'),
              tooltip: l10n.inventoryReceiptReviewEditAction,
              onPressed: () => onEditTap(index),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildDiscountRows({
    required BuildContext context,
    required AppLocalizations l10n,
    required FridgeItem item,
    required int itemIndex,
    required NumberFormat currency,
  }) {
    if (item.discounts.isEmpty) {
      return const <Widget>[];
    }

    final disabledColor = Theme.of(context).disabledColor;
    final discountTextStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: disabledColor);
    final entries = item.discounts.entries.toList(growable: false);

    return entries.indexed
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
            key: Key('receipt_review_discount_row_${itemIndex}_$discountIndex'),
            padding: const EdgeInsets.only(
              left: AppSpacing.xl,
              right: AppSpacing.xs,
              bottom: AppSpacing.xs,
            ),
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
        .toList(growable: false);
  }

  String _buildItemSubtitle({
    required BuildContext context,
    required FridgeItem item,
  }) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final currency = NumberFormat.currency(locale: locale, symbol: '€');
    final linePrice = item.quantity * item.unitPrice;
    return '${item.quantity}x · ${currency.format(linePrice)}';
  }
}

class _ReceiptMetadataOverview extends StatelessWidget {
  const _ReceiptMetadataOverview({
    required this.storeName,
    required this.receiptDate,
  });

  final String storeName;
  final DateTime? receiptDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final receiptDateText = receiptDate == null
        ? l10n.inventoryReceiptReviewNoDate
        : DateFormat.yMMMd(locale).format(receiptDate!);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetadataRow(
              label: l10n.inventoryReceiptReviewFieldStoreName,
              value: storeName,
            ),
            const SizedBox(height: AppSpacing.xxs * 2),
            _MetadataRow(
              label: l10n.inventoryReceiptReviewFieldReceiptDate,
              value: receiptDateText,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value});

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
