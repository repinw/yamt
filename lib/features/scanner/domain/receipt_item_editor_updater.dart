import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/domain/receipt_item_input_parser.dart';
import 'package:yamt/features/scanner/domain/'
    'receipt_item_quantity_normalizer.dart';

enum ReceiptItemEditorApplyError {
  invalidNumber,
  invalidDiscounts,
  invalidWeightUnit,
}

class ReceiptItemEditorFormData {
  const ReceiptItemEditorFormData({
    required this.name,
    required this.entryDate,
    required this.storeName,
    required this.quantityText,
    required this.unitPriceText,
    required this.weightText,
    required this.brandText,
    required this.categoryText,
    required this.discountEntries,
    required this.receiptDate,
    required this.isDeposit,
    required this.isDiscount,
  });

  final String name;
  final DateTime entryDate;
  final String storeName;
  final String quantityText;
  final String unitPriceText;
  final String weightText;
  final String brandText;
  final String categoryText;
  final List<MapEntry<String, String>> discountEntries;
  final DateTime? receiptDate;
  final bool isDeposit;
  final bool isDiscount;
}

sealed class ReceiptItemEditorApplyResult {
  const ReceiptItemEditorApplyResult();
}

final class ReceiptItemEditorApplySuccess extends ReceiptItemEditorApplyResult {
  const ReceiptItemEditorApplySuccess(this.item);

  final InventoryItem item;
}

final class ReceiptItemEditorApplyFailure extends ReceiptItemEditorApplyResult {
  const ReceiptItemEditorApplyFailure(this.error);

  final ReceiptItemEditorApplyError error;
}

class ReceiptItemEditorUpdater {
  const ReceiptItemEditorUpdater({
    ReceiptItemInputParser inputParser = const ReceiptItemInputParser(),
  }) : _inputParser = inputParser;

  final ReceiptItemInputParser _inputParser;

  ReceiptItemEditorApplyResult apply({
    required InventoryItem sourceItem,
    required ReceiptItemEditorFormData formData,
    required String locale,
    required InventoryAmountUnit? fallbackUnit,
  }) {
    final parsedNumbers = _inputParser.parseNumbers(
      quantityText: formData.quantityText,
      unitPriceText: formData.unitPriceText,
      locale: locale,
    );
    if (parsedNumbers == null) {
      return const ReceiptItemEditorApplyFailure(
        ReceiptItemEditorApplyError.invalidNumber,
      );
    }

    final parsedDiscounts = _inputParser.parseDiscountEntries(
      formData.discountEntries,
      locale: locale,
    );
    if (parsedDiscounts == null) {
      return const ReceiptItemEditorApplyFailure(
        ReceiptItemEditorApplyError.invalidDiscounts,
      );
    }

    final quantity = parsedNumbers.quantity;
    final unitPrice = parsedNumbers.unitPrice;
    final safeQuantities = normalizeReceiptItemQuantities(
      quantity: quantity,
      canBeSavedToInventory: !(formData.isDeposit || formData.isDiscount),
    );
    final weight = _nullableText(formData.weightText);

    final updated = sourceItem
        .copyWith(
          name: _requiredText(formData.name, fallback: sourceItem.name),
          entryDate: formData.entryDate,
          storeName: _requiredText(
            formData.storeName,
            fallback: sourceItem.storeName,
          ),
          initialQuantity: safeQuantities.initialQuantity,
          unitPrice: unitPrice < 0 ? 0 : unitPrice,
          brand: _nullableText(formData.brandText),
          category: _nullableText(formData.categoryText),
          discounts: parsedDiscounts,
          receiptDate: formData.receiptDate,
          isDeposit: formData.isDeposit,
          isDiscount: formData.isDiscount,
        )
        .withDerivedAmount(
          weight: weight,
          quantity: safeQuantities.quantity,
          fallbackUnit: fallbackUnit,
        );

    final hasUnresolvedWeight =
        weight != null &&
        updated.initialAmount == 0 &&
        updated.amountUnit == null;
    if (hasUnresolvedWeight) {
      return const ReceiptItemEditorApplyFailure(
        ReceiptItemEditorApplyError.invalidWeightUnit,
      );
    }

    return ReceiptItemEditorApplySuccess(updated);
  }
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
