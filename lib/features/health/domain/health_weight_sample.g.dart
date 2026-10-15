// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_weight_sample.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HealthWeightSample _$HealthWeightSampleFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['fromThisApp'],
    disallowNullValues: const ['fromThisApp'],
  );
  return HealthWeightSample(
    recordedAt: const DateTimeJsonConverter().fromJson(
      json['recordedAt'] as DateTime,
    ),
    weightKg: (json['weightKg'] as num).toDouble(),
    sourcePackageName: json['source'] as String?,
    isFromThisApp: json['fromThisApp'] as bool? ?? false,
  );
}

Map<String, dynamic> _$HealthWeightSampleToJson(HealthWeightSample instance) =>
    <String, dynamic>{
      'recordedAt': const DateTimeJsonConverter().toJson(instance.recordedAt),
      'weightKg': instance.weightKg,
      'source': ?instance.sourcePackageName,
      'fromThisApp': instance.isFromThisApp,
    };
