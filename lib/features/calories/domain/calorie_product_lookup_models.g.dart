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
  per100Kcal: (json['per100_kcal'] as num).toDouble(),
  per100Protein: (json['per100_protein'] as num).toDouble(),
  per100Carbs: (json['per100_carbs'] as num).toDouble(),
  per100Fat: (json['per100_fat'] as num).toDouble(),
  source: $enumDecode(_$CalorieProductSourceEnumMap, json['source']),
  createdAt: const DateTimeJsonConverter().fromJson(
    json['created_at'] as DateTime,
  ),
  updatedAt: const DateTimeJsonConverter().fromJson(
    json['updated_at'] as DateTime,
  ),
  brand: json['brand'] as String?,
  offProductId: json['off_product_id'] as String?,
  imageUrl: json['image_url'] as String?,
  nutrientDetails: const NullableCalorieNutrientDetailsConverter().fromJson(
    json['nutrient_details'],
  ),
);

Map<String, dynamic> _$CalorieProductProfileToJson(
  CalorieProductProfile instance,
) => <String, dynamic>{
  'barcode': instance.barcode,
  'name': instance.name,
  'brand': instance.brand,
  'per100_kcal': instance.per100Kcal,
  'per100_protein': instance.per100Protein,
  'per100_carbs': instance.per100Carbs,
  'per100_fat': instance.per100Fat,
  'source': _$CalorieProductSourceEnumMap[instance.source]!,
  'off_product_id': instance.offProductId,
  'image_url': instance.imageUrl,
  'nutrient_details': const NullableCalorieNutrientDetailsConverter().toJson(
    instance.nutrientDetails,
  ),
  'created_at': const DateTimeJsonConverter().toJson(instance.createdAt),
  'updated_at': const DateTimeJsonConverter().toJson(instance.updatedAt),
};

const _$CalorieProductSourceEnumMap = {
  CalorieProductSource.userOverride: 'user_override',
  CalorieProductSource.globalCatalog: 'global_catalog',
  CalorieProductSource.offBarcode: 'off_barcode',
  CalorieProductSource.offSearch: 'off_search',
  CalorieProductSource.ocr: 'ocr',
};
