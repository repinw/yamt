// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_product_lookup_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalorieProductProfile _$CalorieProductProfileFromJson(
  Map<String, dynamic> json,
) => CalorieProductProfile(
  barcode: json['barcode'] as String,
  name: json['name'] as String,
  per100Kcal: const FlexibleDoubleConverter().fromJson(json['per100_kcal']),
  per100Protein: const FlexibleDoubleConverter().fromJson(
    json['per100_protein'],
  ),
  per100Carbs: const FlexibleDoubleConverter().fromJson(json['per100_carbs']),
  per100Fat: const FlexibleDoubleConverter().fromJson(json['per100_fat']),
  source: $enumDecode(_$CalorieProductSourceEnumMap, json['source']),
  createdAt: const FlexibleDateTimeConverter().fromJson(json['created_at']),
  updatedAt: const FlexibleDateTimeConverter().fromJson(json['updated_at']),
  brand: json['brand'] as String?,
  offProductId: json['off_product_id'] as String?,
);

Map<String, dynamic> _$CalorieProductProfileToJson(
  CalorieProductProfile instance,
) => <String, dynamic>{
  'barcode': instance.barcode,
  'name': instance.name,
  'brand': instance.brand,
  'per100_kcal': const FlexibleDoubleConverter().toJson(instance.per100Kcal),
  'per100_protein': const FlexibleDoubleConverter().toJson(
    instance.per100Protein,
  ),
  'per100_carbs': const FlexibleDoubleConverter().toJson(instance.per100Carbs),
  'per100_fat': const FlexibleDoubleConverter().toJson(instance.per100Fat),
  'source': _$CalorieProductSourceEnumMap[instance.source]!,
  'off_product_id': instance.offProductId,
  'created_at': const FlexibleDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const FlexibleDateTimeConverter().toJson(instance.updatedAt),
};

const _$CalorieProductSourceEnumMap = {
  CalorieProductSource.userOverride: 'user_override',
  CalorieProductSource.globalCatalog: 'global_catalog',
  CalorieProductSource.offBarcode: 'off_barcode',
  CalorieProductSource.offSearch: 'off_search',
  CalorieProductSource.ocr: 'ocr',
};
