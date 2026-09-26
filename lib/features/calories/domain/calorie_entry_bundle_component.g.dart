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
  totalKcal: const FlexibleDoubleConverter().fromJson(json['total_kcal']),
  totalProtein: const FlexibleDoubleConverter().fromJson(json['total_protein']),
  totalCarbs: const FlexibleDoubleConverter().fromJson(json['total_carbs']),
  totalFat: const FlexibleDoubleConverter().fromJson(json['total_fat']),
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
  'total_kcal': const FlexibleDoubleConverter().toJson(instance.totalKcal),
  'total_protein': const FlexibleDoubleConverter().toJson(
    instance.totalProtein,
  ),
  'total_carbs': const FlexibleDoubleConverter().toJson(instance.totalCarbs),
  'total_fat': const FlexibleDoubleConverter().toJson(instance.totalFat),
};
