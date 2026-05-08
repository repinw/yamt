// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kitchen_utensil.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KitchenUtensil _$KitchenUtensilFromJson(Map<String, dynamic> json) =>
    KitchenUtensil(
      id: _readRequiredString(json['id']),
      weightGrams: _readIntOrZero(json['weight_grams']),
      createdAt: _readDateTimeOrNow(json['created_at']),
      updatedAt: _readDateTimeOrNow(json['updated_at']),
      name: _readTrimmedNullableString(json['name']),
      imageStoragePath: _readTrimmedNullableString(json['image_storage_path']),
    );

Map<String, dynamic> _$KitchenUtensilToJson(KitchenUtensil instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'image_storage_path': instance.imageStoragePath,
      'weight_grams': instance.weightGrams,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
