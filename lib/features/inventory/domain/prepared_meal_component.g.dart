// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prepared_meal_component.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PreparedMealComponent _$PreparedMealComponentFromJson(
  Map<String, dynamic> json,
) => PreparedMealComponent(
  inventoryItemId: readPreparedMealString(json['inventory_item_id']),
  name: readPreparedMealString(json['name']),
  brand: readPreparedMealOptionalString(json['brand']),
  imageUrl: readPreparedMealOptionalString(json['image_url']),
  usedAmount: readPreparedMealInt(json['used_amount']),
  usedUnit: readPreparedMealAmountUnit(json['used_unit']),
  totalKcal: readPreparedMealDouble(json['total_kcal']),
  totalProtein: readPreparedMealDouble(json['total_protein']),
  totalCarbs: readPreparedMealDouble(json['total_carbs']),
  totalFat: readPreparedMealDouble(json['total_fat']),
  sourceItemSnapshot: InventoryItem.fromJson(
    json['source_item_snapshot'] as Map<String, dynamic>,
  ),
  addedForMeal: json['added_for_meal'] as bool?,
);

Map<String, dynamic> _$PreparedMealComponentToJson(
  PreparedMealComponent instance,
) => <String, dynamic>{
  'inventory_item_id': instance.inventoryItemId,
  'name': instance.name,
  'brand': instance.brand,
  'image_url': instance.imageUrl,
  'used_amount': instance.usedAmount,
  'used_unit': writePreparedMealAmountUnit(instance.usedUnit),
  'total_kcal': instance.totalKcal,
  'total_protein': instance.totalProtein,
  'total_carbs': instance.totalCarbs,
  'total_fat': instance.totalFat,
  'source_item_snapshot': instance.sourceItemSnapshot.toJson(),
  'added_for_meal': ?instance.addedForMeal,
};
