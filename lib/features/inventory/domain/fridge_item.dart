import 'package:freezed_annotation/freezed_annotation.dart';

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

  /// Display-only row in receipt review (not to be persisted as food stock).
  bool get isReviewOnly => isDeposit || isDiscount;

  bool get canBeSavedToFridge => !isReviewOnly;
}
