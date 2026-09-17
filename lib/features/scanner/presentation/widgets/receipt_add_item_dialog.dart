import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_selection_list_tiles.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Dialog to manually add an item to the receipt.
class ReceiptAddItemDialog extends StatefulWidget {
  /// Creates a [ReceiptAddItemDialog].
  const new({super.key});

  /// Shows the dialog and returns the new [ReceiptLineItem] or null if
  /// cancelled.
  static Future<ReceiptLineItem?> show(BuildContext context) {
    return showDialog<ReceiptLineItem>(
      context: context,
      builder: (context) => const ReceiptAddItemDialog(),
    );
  }

  @override
  State<ReceiptAddItemDialog> createState() => _ReceiptAddItemDialogState();
}

class _ReceiptAddItemDialogState extends State<ReceiptAddItemDialog> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  bool _isDeposit = false;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _onSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final quantity =
        double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 1.0;
    final price =
        double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0.0;

    final item = ReceiptLineItem(
      id: 'manual_${DateTime.now().microsecondsSinceEpoch}',
      rawName: name,
      quantity: quantity > 0 ? quantity : 1.0,
      totalPrice: price >= 0 ? price : 0.0,
      isDeposit: _isDeposit,
    );

    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n?.receiptReviewAddItem ?? 'Position hinzufügen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText:
                    l10n?.receiptReviewItemNameLabel ?? 'Artikelbezeichnung',
                hintText:
                    l10n?.receiptReviewItemNameHint ??
                    'z. B. Hafermilch Barista',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText:
                          l10n?.receiptReviewItemQuantityLabel ?? 'Menge',
                      hintText: '1',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n?.receiptReviewPriceLabel ?? 'Preis',
                      hintText: '0.00',
                      suffixText: '€',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n?.receiptReviewIsDepositLabel ?? 'Ist Pfand'),
              value: _isDeposit,
              onChanged: (val) => setState(() => _isDeposit = val),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n?.inventoryReceiptReviewCancelAction ?? 'Abbrechen'),
        ),
        FilledButton(
          onPressed: _onSave,
          child: Text(l10n?.receiptReviewAddAction ?? 'Hinzufügen'),
        ),
      ],
    );
  }
}
