import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';

const _amountParser = InventoryAmountParser();

/// Should require receipt weight confirmation.
bool shouldRequireReceiptWeightConfirmation(ReceiptReviewItemDraft draft) {
  if (!draft.canBeSavedToInventory) {
    return false;
  }

  final itemWeight = normalizeReceiptReviewWeight(draft.item.weight);
  if (itemWeight == null) {
    return true;
  }

  final candidateWeight = normalizeReceiptReviewWeight(
    draft.selectedCandidate?.item.packageWeight,
  );
  if (candidateWeight == null) {
    return false;
  }

  if (_compactWeight(itemWeight) == _compactWeight(candidateWeight)) {
    return false;
  }

  final itemAmount = _amountParser.tryParse(
    rawWeight: itemWeight,
    quantity: draft.item.quantity,
    fallbackUnit: draft.item.amountUnit,
  );
  final candidateAmount = _amountParser.tryParse(
    rawWeight: candidateWeight,
    quantity: draft.item.quantity,
    fallbackUnit: draft.item.amountUnit,
  );
  if (itemAmount == null || candidateAmount == null) {
    return true;
  }

  return itemAmount.amount != candidateAmount.amount ||
      itemAmount.unit != candidateAmount.unit;
}

/// Normalize receipt review weight.
String? normalizeReceiptReviewWeight(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

String _compactWeight(String value) {
  return value.replaceAll(' ', '').toLowerCase();
}
