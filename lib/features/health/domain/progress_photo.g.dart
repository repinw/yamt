// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_photo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProgressPhoto _$ProgressPhotoFromJson(Map<String, dynamic> json) =>
    _ProgressPhoto(
      id: json['id'] as String,
      day: const DateTimeJsonConverter().fromJson(json['day'] as DateTime),
      pose: $enumDecode(_$ProgressPhotoPoseEnumMap, json['pose']),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ProgressPhotoToJson(_ProgressPhoto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'day': const DateTimeJsonConverter().toJson(instance.day),
      'pose': _$ProgressPhotoPoseEnumMap[instance.pose]!,
      'weight_kg': instance.weightKg,
    };

const _$ProgressPhotoPoseEnumMap = {
  ProgressPhotoPose.front: 'front',
  ProgressPhotoPose.side: 'side',
  ProgressPhotoPose.back: 'back',
};
