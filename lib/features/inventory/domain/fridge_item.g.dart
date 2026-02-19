// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fridge_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FridgeItem _$FridgeItemFromJson(Map<String, dynamic> json) => _FridgeItem(
  id: json['id'] as String,
  name: json['name'] as String,
  entryDate: DateTime.parse(json['entryDate'] as String),
  storeName: json['storeName'] as String,
  quantity: (json['quantity'] as num).toInt(),
  initialQuantity: (json['initialQuantity'] as num?)?.toInt() ?? 1,
  unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
  weight: json['weight'] as String?,
  brand: json['brand'] as String?,
  category: json['category'] as String?,
  discounts:
      (json['discounts'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ) ??
      const <String, double>{},
  receiptId: json['receiptId'] as String?,
  receiptDate: json['receiptDate'] == null
      ? null
      : DateTime.parse(json['receiptDate'] as String),
  language: json['language'] as String?,
  isDeposit: json['isDeposit'] as bool? ?? false,
  isDiscount: json['isDiscount'] as bool? ?? false,
);

Map<String, dynamic> _$FridgeItemToJson(_FridgeItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'entryDate': instance.entryDate.toIso8601String(),
      'storeName': instance.storeName,
      'quantity': instance.quantity,
      'initialQuantity': instance.initialQuantity,
      'unitPrice': instance.unitPrice,
      'weight': instance.weight,
      'brand': instance.brand,
      'category': instance.category,
      'discounts': instance.discounts,
      'receiptId': instance.receiptId,
      'receiptDate': instance.receiptDate?.toIso8601String(),
      'language': instance.language,
      'isDeposit': instance.isDeposit,
      'isDiscount': instance.isDiscount,
    };
