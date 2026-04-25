import 'package:yamt/core/utils/store_name_normalizer.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/receipt_item_input_parser.dart';
import 'package:yamt/features/inventory/domain/'
    'receipt_item_quantity_normalizer.dart';

/// Defines receipt item editor apply error.
enum ReceiptItemEditorApplyError {
  /// Documented member.
  invalidNumber,

  /// Documented member.
  invalidDiscounts,

  /// Documented member.
  invalidWeightUnit,
}

/// Defines receipt item editor form data.
class ReceiptItemEditorFormData {
  /// The receipt item editor form data.
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

  /// The name.
  final String name;

  /// The entry date.
  final DateTime entryDate;

  /// The store name.
  final String storeName;

  /// The quantity text.
  final String quantityText;

  /// The unit price text.
  final String unitPriceText;

  /// The weight text.
  final String weightText;

  /// The brand text.
  final String brandText;

  /// The category text.
  final String categoryText;

  /// The discount entries.
  final List<MapEntry<String, String>> discountEntries;

  /// The receipt date.
  final DateTime? receiptDate;

  /// Whether deposit.
  final bool isDeposit;

  /// Whether discount.
  final bool isDiscount;
}

/// Defines receipt item editor apply result.
sealed class ReceiptItemEditorApplyResult {
  const ReceiptItemEditorApplyResult();
}

/// Defines receipt item editor apply success.
final class ReceiptItemEditorApplySuccess extends ReceiptItemEditorApplyResult {
  /// The receipt item editor apply success.
  const ReceiptItemEditorApplySuccess(this.item);

  /// The item.
  final InventoryItem item;
}

/// Defines receipt item editor apply failure.
final class ReceiptItemEditorApplyFailure extends ReceiptItemEditorApplyResult {
  /// The receipt item editor apply failure.
  const ReceiptItemEditorApplyFailure(this.error);

  /// The error.
  final ReceiptItemEditorApplyError error;
}

/// Defines receipt item editor updater.
class ReceiptItemEditorUpdater {
  /// The receipt item editor updater.
  const ReceiptItemEditorUpdater({
    ReceiptItemInputParser inputParser = const ReceiptItemInputParser(),
  }) : _inputParser = inputParser;

  final ReceiptItemInputParser _inputParser;

  /// Apply.
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
    final storeName =
        normalizeStoreName(
          _requiredText(formData.storeName, fallback: sourceItem.storeName),
        ) ??
        sourceItem.storeName;

    final updated = sourceItem
        .copyWith(
          name: _requiredText(formData.name, fallback: sourceItem.name),
          entryDate: formData.entryDate,
          storeName: storeName,
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
