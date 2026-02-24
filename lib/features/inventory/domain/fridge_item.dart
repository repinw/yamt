import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:yamt/features/inventory/domain/fridge_item_amount_parser.dart';
export 'package:yamt/features/inventory/domain/fridge_item_amount_parser.dart'
    show FridgeAmountUnit;

part 'fridge_item.freezed.dart';
part 'fridge_item.g.dart';

@freezed
abstract class FridgeItem with _$FridgeItem {
  const FridgeItem._();

  const factory FridgeItem({
    required String id,
    required String name,
    required DateTime entryDate,
    required String storeName,
    required int quantity,
    @Default(1) int initialQuantity,
    @Default(0.0) double unitPrice,
    String? weight,
    @Default(0) int initialAmount,
    @Default(0) int currentAmount,
    FridgeAmountUnit? amountUnit,
    String? brand,
    String? category,
    @Default(<String, double>{}) Map<String, double> discounts,
    String? receiptId,
    DateTime? receiptDate,
    String? language,
    @Default(false) bool isDeposit,
    @Default(false) bool isDiscount,
  }) = _FridgeItem;

  factory FridgeItem.fromJson(Map<String, dynamic> json) =>
      _$FridgeItemFromJson(json);

  /// Derives `initialAmount`/`currentAmount` from [weight] and [quantity].
  ///
  /// Parsed values are normalized to base units (`g`, `ml`).
  FridgeItem withDerivedAmount({
    String? weight,
    int? quantity,
    FridgeAmountUnit? fallbackUnit,
  }) {
    final normalizedWeight = _normalizeWeightText(weight ?? this.weight);
    final nextQuantity = quantity ?? this.quantity;
    final parsedAmount = _amountParser.tryParse(
      rawWeight: normalizedWeight,
      quantity: nextQuantity,
      fallbackUnit: fallbackUnit,
    );
    final amount = parsedAmount?.amount ?? 0;

    return copyWith(
      quantity: nextQuantity,
      weight: normalizedWeight,
      initialAmount: amount,
      currentAmount: amount,
      amountUnit: parsedAmount?.unit,
    );
  }

  /// Display-only row in receipt review (not to be persisted as food stock).
  bool get isReviewOnly => isDeposit || isDiscount;

  bool get canBeSavedToFridge => !isReviewOnly;

  bool get usesAmountProgress => amountUnit != null && initialAmount > 0;

  bool get isConsumed {
    final progress = _consumptionProgress;
    return progress.remaining < progress.initial;
  }

  bool get isFullyConsumed {
    final progress = _consumptionProgress;
    return progress.remaining <= 0;
  }

  _ConsumptionProgress get _consumptionProgress {
    if (usesAmountProgress) {
      return _ConsumptionProgress(
        initial: initialAmount,
        remaining: currentAmount,
      );
    }
    return _ConsumptionProgress(initial: initialQuantity, remaining: quantity);
  }
}

class _ConsumptionProgress {
  const _ConsumptionProgress({required this.initial, required this.remaining});

  final int initial;
  final int remaining;
}

const _amountParser = FridgeItemAmountParser();

String? _normalizeWeightText(String? rawWeight) {
  final trimmed = rawWeight?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
