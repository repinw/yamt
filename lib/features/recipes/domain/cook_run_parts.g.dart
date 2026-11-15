// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cook_run_parts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CookPot _$CookPotFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    allowedKeys: const ['id', 'name', 'empty_weight', 'image_storage_path'],
    requiredKeys: const ['id', 'name', 'empty_weight', 'image_storage_path'],
  );
  return CookPot(
    id: json['id'] as String,
    name: json['name'] as String?,
    emptyWeight: (json['empty_weight'] as num).toInt(),
    imageStoragePath: json['image_storage_path'] as String?,
  );
}

Map<String, dynamic> _$CookPotToJson(CookPot instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'empty_weight': instance.emptyWeight,
  'image_storage_path': instance.imageStoragePath,
};

CookTimer _$CookTimerFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    allowedKeys: const ['id', 'label', 'ends_at', 'device_id'],
    requiredKeys: const ['id', 'label', 'ends_at', 'device_id'],
  );
  return CookTimer(
    id: json['id'] as String,
    label: json['label'] as String,
    endsAt: const DateTimeJsonConverter().fromJson(json['ends_at'] as DateTime),
    deviceId: json['device_id'] as String,
  );
}

Map<String, dynamic> _$CookTimerToJson(CookTimer instance) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'ends_at': const DateTimeJsonConverter().toJson(instance.endsAt),
  'device_id': instance.deviceId,
};

CookMealDraft _$CookMealDraftFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    allowedKeys: const ['pot_id', 'name', 'count', 'in_pieces', 'gross_weight'],
    requiredKeys: const [
      'pot_id',
      'name',
      'count',
      'in_pieces',
      'gross_weight',
    ],
  );
  return CookMealDraft(
    potId: json['pot_id'] as String,
    name: json['name'] as String,
    count: (json['count'] as num).toInt(),
    inPieces: json['in_pieces'] as bool,
    grossWeight: (json['gross_weight'] as num?)?.toInt(),
  );
}

Map<String, dynamic> _$CookMealDraftToJson(CookMealDraft instance) =>
    <String, dynamic>{
      'pot_id': instance.potId,
      'name': instance.name,
      'count': instance.count,
      'in_pieces': instance.inPieces,
      'gross_weight': instance.grossWeight,
    };
