// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prepared_meal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PreparedMeal _$PreparedMealFromJson(Map<String, dynamic> json) => PreparedMeal(
  id: _readRequiredString(json['id']),
  name: _readRequiredString(json['name']),
  imageAssetId: _readTrimmedNullableString(json['image_asset_id']),
  totalPortions: _readIntOrZero(json['total_portions']),
  remainingPortions: _readIntOrZero(json['remaining_portions']),
  totalKcal: _readDoubleOrZero(json['total_kcal']),
  totalProtein: _readDoubleOrZero(json['total_protein']),
  totalCarbs: _readDoubleOrZero(json['total_carbs']),
  totalFat: _readDoubleOrZero(json['total_fat']),
  createdAt: _readDateTimeOrNow(json['created_at']),
  updatedAt: _readDateTimeOrNow(json['updated_at']),
  components:
      (json['components'] as List<dynamic>?)
          ?.map(
            (e) => PreparedMealComponent.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      [],
);

Map<String, dynamic> _$PreparedMealToJson(PreparedMeal instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'image_asset_id': instance.imageAssetId,
      'total_portions': instance.totalPortions,
      'remaining_portions': instance.remainingPortions,
      'total_kcal': instance.totalKcal,
      'total_protein': instance.totalProtein,
      'total_carbs': instance.totalCarbs,
      'total_fat': instance.totalFat,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'components': instance.components.map((e) => e.toJson()).toList(),
    };

PreparedMealComponent _$PreparedMealComponentFromJson(
  Map<String, dynamic> json,
) => PreparedMealComponent(
  inventoryItemId: _readRequiredString(json['inventory_item_id']),
  name: _readRequiredString(json['name']),
  brand: _readTrimmedNullableString(json['brand']),
  imageUrl: _readTrimmedNullableString(json['image_url']),
  usedAmount: _readIntOrZero(json['used_amount']),
  usedUnit: _readAmountUnitOrPiece(json['used_unit']),
  totalKcal: _readDoubleOrZero(json['total_kcal']),
  totalProtein: _readDoubleOrZero(json['total_protein']),
  totalCarbs: _readDoubleOrZero(json['total_carbs']),
  totalFat: _readDoubleOrZero(json['total_fat']),
  sourceItemSnapshot: InventoryItem.fromJson(
    json['source_item_snapshot'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$PreparedMealComponentToJson(
  PreparedMealComponent instance,
) => <String, dynamic>{
  'inventory_item_id': instance.inventoryItemId,
  'name': instance.name,
  'brand': instance.brand,
  'image_url': instance.imageUrl,
  'used_amount': instance.usedAmount,
  'used_unit': _writeAmountUnit(instance.usedUnit),
  'total_kcal': instance.totalKcal,
  'total_protein': instance.totalProtein,
  'total_carbs': instance.totalCarbs,
  'total_fat': instance.totalFat,
  'source_item_snapshot': instance.sourceItemSnapshot.toJson(),
};
