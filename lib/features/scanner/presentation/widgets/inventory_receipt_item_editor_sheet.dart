import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

class InventoryReceiptItemEditorSheet extends StatefulWidget {
  const InventoryReceiptItemEditorSheet({super.key, required this.item});

  final FridgeItem item;

  @override
  State<InventoryReceiptItemEditorSheet> createState() =>
      _InventoryReceiptItemEditorSheetState();
}

class _InventoryReceiptItemEditorSheetState
    extends State<InventoryReceiptItemEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _storeNameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitPriceController;
  late final TextEditingController _weightController;
  late final TextEditingController _brandController;
  late final TextEditingController _categoryController;
  late final TextEditingController _discountsController;
  late DateTime _entryDate;
  DateTime? _receiptDate;
  late bool _isDeposit;
  late bool _isDiscount;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item.name);
    _storeNameController = TextEditingController(text: item.storeName);
    _quantityController = TextEditingController(text: item.quantity.toString());
    _unitPriceController = TextEditingController(
      text: item.unitPrice.toString(),
    );
    _weightController = TextEditingController(text: item.weight ?? '');
    _brandController = TextEditingController(text: item.brand ?? '');
    _categoryController = TextEditingController(text: item.category ?? '');
    _discountsController = TextEditingController(
      text: _encodeDiscounts(item.discounts),
    );
    _entryDate = item.entryDate;
    _receiptDate = item.receiptDate;
    _isDeposit = item.isDeposit;
    _isDiscount = item.isDiscount;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _storeNameController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _weightController.dispose();
    _brandController.dispose();
    _categoryController.dispose();
    _discountsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final insets = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl + insets,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.inventoryReceiptReviewEditTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            _textField(
              key: const Key('receipt_review_field_name'),
              controller: _nameController,
              label: l10n.inventoryReceiptReviewFieldName,
            ),
            _dateField(
              context: context,
              label: l10n.inventoryReceiptReviewFieldEntryDate,
              value: _entryDate,
              noDateLabel: l10n.inventoryReceiptReviewNoDate,
              onSelectTap: _pickEntryDate,
            ),
            _textField(
              key: const Key('receipt_review_field_store_name'),
              controller: _storeNameController,
              label: l10n.inventoryReceiptReviewFieldStoreName,
            ),
            _textField(
              key: const Key('receipt_review_field_quantity'),
              controller: _quantityController,
              label: l10n.inventoryReceiptReviewFieldQuantity,
              keyboardType: TextInputType.number,
            ),
            _textField(
              key: const Key('receipt_review_field_unit_price'),
              controller: _unitPriceController,
              label: l10n.inventoryReceiptReviewFieldUnitPrice,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            _textField(
              key: const Key('receipt_review_field_weight'),
              controller: _weightController,
              label: l10n.inventoryReceiptReviewFieldWeight,
            ),
            _textField(
              key: const Key('receipt_review_field_brand'),
              controller: _brandController,
              label: l10n.inventoryReceiptReviewFieldBrand,
            ),
            _textField(
              key: const Key('receipt_review_field_category'),
              controller: _categoryController,
              label: l10n.inventoryReceiptReviewFieldCategory,
            ),
            _textField(
              key: const Key('receipt_review_field_discounts'),
              controller: _discountsController,
              label: l10n.inventoryReceiptReviewFieldDiscounts,
              hintText: l10n.inventoryReceiptReviewDiscountsHint,
            ),
            _dateField(
              context: context,
              label: l10n.inventoryReceiptReviewFieldReceiptDate,
              value: _receiptDate,
              noDateLabel: l10n.inventoryReceiptReviewNoDate,
              onSelectTap: _pickReceiptDate,
              onClearTap: _clearReceiptDate,
              clearButtonKey: const Key(
                'receipt_review_clear_receipt_date_button',
              ),
            ),
            SwitchListTile.adaptive(
              title: Text(l10n.inventoryReceiptReviewFieldIsDeposit),
              value: _isDeposit,
              onChanged: (value) {
                setState(() {
                  _isDeposit = value;
                });
              },
            ),
            SwitchListTile.adaptive(
              title: Text(l10n.inventoryReceiptReviewFieldIsDiscount),
              value: _isDiscount,
              onChanged: (value) {
                setState(() {
                  _isDiscount = value;
                });
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.inventoryReceiptReviewCancelAction),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    key: const Key('receipt_review_apply_item_button'),
                    onPressed: _applyChanges,
                    child: Text(l10n.inventoryReceiptReviewApplyItemAction),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField({
    required Key key,
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        key: key,
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, hintText: hintText),
      ),
    );
  }

  Widget _dateField({
    required BuildContext context,
    required String label,
    required DateTime? value,
    required String noDateLabel,
    required Future<void> Function() onSelectTap,
    VoidCallback? onClearTap,
    Key? clearButtonKey,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final formattedDate = _formatDate(context, value);
    final valueText = formattedDate ?? noDateLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xxs * 2),
          Text(valueText),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              TextButton(
                onPressed: onSelectTap,
                child: Text(l10n.inventoryReceiptReviewSelectDateAction),
              ),
              if (onClearTap != null)
                TextButton(
                  key: clearButtonKey,
                  onPressed: onClearTap,
                  child: Text(l10n.inventoryReceiptReviewClearDateAction),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String? _formatDate(BuildContext context, DateTime? value) {
    if (value == null) {
      return null;
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.yMMMd(locale).format(value);
  }

  Future<void> _pickEntryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || picked == null) {
      return;
    }
    setState(() {
      _entryDate = DateUtils.dateOnly(picked);
    });
  }

  Future<void> _pickReceiptDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receiptDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || picked == null) {
      return;
    }
    setState(() {
      _receiptDate = DateUtils.dateOnly(picked);
    });
  }

  void _clearReceiptDate() {
    setState(() {
      _receiptDate = null;
    });
  }

  void _applyChanges() {
    final l10n = AppLocalizations.of(context)!;
    final parsedNumbers = _parseNumbers();
    if (parsedNumbers == null) {
      _showError(l10n.inventoryReceiptReviewInvalidNumber);
      return;
    }

    final parsedDiscounts = _parseDiscounts(_discountsController.text);
    if (parsedDiscounts == null) {
      _showError(l10n.inventoryReceiptReviewInvalidDiscounts);
      return;
    }

    final quantity = parsedNumbers.$1;
    final unitPrice = parsedNumbers.$2;
    final safeInitialQuantity = quantity < 1 ? 1 : quantity;

    final updated = widget.item.copyWith(
      name: _requiredText(_nameController.text, fallback: widget.item.name),
      entryDate: _entryDate,
      storeName: _requiredText(
        _storeNameController.text,
        fallback: widget.item.storeName,
      ),
      quantity: quantity < 0 ? 0 : quantity,
      initialQuantity: safeInitialQuantity,
      unitPrice: unitPrice < 0 ? 0 : unitPrice,
      weight: _nullableText(_weightController.text),
      brand: _nullableText(_brandController.text),
      category: _nullableText(_categoryController.text),
      discounts: parsedDiscounts,
      receiptDate: _receiptDate,
      isDeposit: _isDeposit,
      isDiscount: _isDiscount,
    );

    Navigator.of(context).pop(updated);
  }

  (int, double)? _parseNumbers() {
    final quantity = int.tryParse(_quantityController.text.trim());
    final unitPrice = _parseDouble(_unitPriceController.text.trim());

    if (quantity == null || unitPrice == null) {
      return null;
    }
    return (quantity, unitPrice);
  }

  double? _parseDouble(String value) {
    if (value.isEmpty) {
      return null;
    }
    final normalized = value.replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  Map<String, double>? _parseDiscounts(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return const <String, double>{};
    }

    final fromJson = _parseDiscountsFromJson(normalized);
    if (fromJson != null) {
      return fromJson;
    }

    return _parseDiscountsFromPairs(normalized);
  }

  Map<String, double>? _parseDiscountsFromJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final parsed = <String, double>{};
      for (final entry in decoded.entries) {
        final amount = entry.value;
        if (amount is num) {
          parsed[entry.key] = amount.toDouble();
          continue;
        }
        if (amount is String) {
          final parsedAmount = _parseDouble(amount);
          if (parsedAmount == null) {
            return null;
          }
          parsed[entry.key] = parsedAmount;
          continue;
        }
        return null;
      }
      return parsed;
    } catch (_) {
      return null;
    }
  }

  Map<String, double>? _parseDiscountsFromPairs(String raw) {
    final entries = raw.split(',');
    final parsed = <String, double>{};

    for (final entry in entries) {
      final normalizedEntry = entry.trim();
      if (normalizedEntry.isEmpty) {
        continue;
      }

      final separator = normalizedEntry.contains('=')
          ? '='
          : normalizedEntry.contains(':')
          ? ':'
          : null;
      if (separator == null) {
        return null;
      }

      final parts = normalizedEntry.split(separator);
      if (parts.length != 2) {
        return null;
      }

      final key = parts.first.trim();
      final value = _parseDouble(parts.last.trim());
      if (key.isEmpty || value == null) {
        return null;
      }
      parsed[key] = value;
    }

    return parsed;
  }

  String _requiredText(String value, {required String fallback}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return fallback;
    }
    return trimmed;
  }

  String? _nullableText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  void _showError(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

String _encodeDiscounts(Map<String, double> discounts) {
  if (discounts.isEmpty) {
    return '';
  }
  return jsonEncode(discounts);
}
