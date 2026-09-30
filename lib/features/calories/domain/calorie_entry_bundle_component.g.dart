// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_entry_bundle_component.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalorieEntryBundleComponent _$CalorieEntryBundleComponentFromJson(
  Map<String, dynamic> json,
) => CalorieEntryBundleComponent(
  name: json['name'] as String,
  amountLabel: json['amount_label'] as String,
  totalKcal: (json['total_kcal'] as num).toDouble(),
  totalProtein: (json['total_protein'] as num).toDouble(),
  totalCarbs: (json['total_carbs'] as num).toDouble(),
  totalFat: (json['total_fat'] as num).toDouble(),
  brand: json['brand'] as String?,
  imageUrl: json['image_url'] as String?,
  sourceInventoryItemId: json['source_inventory_item_id'] as String?,
  sourceInventoryAmountToRestore:
      (json['source_inventory_amount_to_restore'] as num?)?.toInt(),
);

Map<String, dynamic> _$CalorieEntryBundleComponentToJson(
  CalorieEntryBundleComponent instance,
) => <String, dynamic>{
  'name': instance.name,
  'amount_label': instance.amountLabel,
  'brand': instance.brand,
  'image_url': instance.imageUrl,
  'source_inventory_item_id': instance.sourceInventoryItemId,
  'source_inventory_amount_to_restore': instance.sourceInventoryAmountToRestore,
  'total_kcal': instance.totalKcal,
  'total_protein': instance.totalProtein,
  'total_carbs': instance.totalCarbs,
  'total_fat': instance.totalFat,
};
