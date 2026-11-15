// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cook_line_settlement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemTake _$ItemTakeFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    allowedKeys: const ['item_id', 'amount'],
    requiredKeys: const ['item_id', 'amount'],
  );
  return ItemTake(
    itemId: json['item_id'] as String,
    amount: (json['amount'] as num).toInt(),
  );
}

Map<String, dynamic> _$ItemTakeToJson(ItemTake instance) => <String, dynamic>{
  'item_id': instance.itemId,
  'amount': instance.amount,
};
