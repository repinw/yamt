import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/core/domain/date_time_json_converter.dart';

part 'health_weight_sample.g.dart';

/// Defines health weight sample.
///
/// The json is the encrypted payload of its cloud copy.
@JsonSerializable(includeIfNull: false)
class HealthWeightSample {
  /// The health weight sample.
  const new({
    required this.recordedAt,
    required this.weightKg,
    this.uuid,
    this.sourcePackageName,
    this.isFromThisApp = false,
  });

  /// Decodes the payload of a cloud copy.
  factory fromJson(Map<String, dynamic> json) =>
      _$HealthWeightSampleFromJson(json);

  /// The recorded at.
  @DateTimeJsonConverter()
  final DateTime recordedAt;

  /// The weight kg.
  final double weightKg;

  /// Health platform record id, when available.
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? uuid;

  /// Source package name, when available.
  @JsonKey(name: 'source')
  final String? sourcePackageName;

  /// Whether this sample was written by this app.
  @JsonKey(name: 'fromThisApp', required: true, disallowNullValue: true)
  final bool isFromThisApp;

  /// Encodes the payload of a cloud copy.
  Map<String, dynamic> toJson() => _$HealthWeightSampleToJson(this);
}
