import 'package:flutter/material.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Prompts the user to confirm the detected weight before saving.
Future<InventoryItem?> showInventoryReceiptWeightConfirmationDialog({
  required BuildContext context,
  required InventoryItem item,
  String? initialWeight,
}) async {
  final controller = TextEditingController(text: initialWeight?.trim() ?? '');
  final focusNode = FocusNode();
  String? errorText;

  final confirmedItem = await showDialog<InventoryItem>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          final l10n = AppLocalizations.of(dialogContext)!;

          void submit() {
            final weight = controller.text.trim();
            if (weight.isEmpty) {
              setState(() {
                errorText = l10n.inventoryReceiptReviewWeightConfirmRequired;
              });
              return;
            }

            final updatedItem = item.withDerivedAmount(
              weight: weight,
              quantity: item.quantity,
            );
            if (updatedItem.amountUnit == null) {
              setState(() {
                errorText = l10n.inventoryReceiptReviewInvalidWeightUnit;
              });
              return;
            }

            Navigator.of(dialogContext).pop(updatedItem);
          }

          return AlertDialog(
            title: Text(l10n.inventoryReceiptReviewWeightConfirmTitle),
            content: TextField(
              key: const Key('receipt_review_weight_confirmation_field'),
              controller: controller,
              focusNode: focusNode,
              autofocus: false,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.inventoryReceiptReviewFieldWeight,
                errorText: errorText,
                suffixIcon: IconButton(
                  key: const Key(
                    'receipt_review_weight_confirmation_clear_button',
                  ),
                  tooltip: l10n.inventoryReceiptReviewWeightConfirmClearAction,
                  onPressed: () {
                    controller.clear();
                    focusNode.requestFocus();
                    if (errorText == null) {
                      return;
                    }
                    setState(() {
                      errorText = null;
                    });
                  },
                  icon: const Icon(Icons.cleaning_services_outlined),
                ),
              ),
              onChanged: (_) {
                if (errorText == null) {
                  return;
                }
                setState(() {
                  errorText = null;
                });
              },
              onSubmitted: (_) => submit(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.inventoryReceiptReviewCancelAction),
              ),
              FilledButton(
                key: const Key('receipt_review_weight_confirmation_yes_button'),
                onPressed: submit,
                child: Text(l10n.inventoryReceiptReviewWeightConfirmAction),
              ),
            ],
          );
        },
      );
    },
  );

  controller.dispose();
  focusNode.dispose();
  return confirmedItem;
}
