import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'kitchen_utensil.g.dart';

/// Kitchen utensil saved for tare selection.
@immutable
@JsonSerializable(fieldRename: FieldRename.snake)
class KitchenUtensil {
  /// Creates a kitchen utensil.
  const KitchenUtensil({
    required this.id,
    required this.weightGrams,
    required this.createdAt,
    required this.updatedAt,
    this.name,
    this.imageStoragePath,
  });

  /// Creates a kitchen utensil from json.
  factory KitchenUtensil.fromJson(Map<String, dynamic> json) {
    final utensil = _$KitchenUtensilFromJson(json);
    if (utensil.id.isEmpty ||
        utensil.weightGrams <= 0 ||
        !utensil.hasIdentity) {
      throw const FormatException('Invalid kitchen utensil.');
    }
    return utensil;
  }

  /// Stable document id.
  @JsonKey(fromJson: _readRequiredString)
  final String id;

  /// Optional user-facing name.
  @JsonKey(fromJson: _readTrimmedNullableString)
  final String? name;

  /// Optional Firebase Storage path for synced photo.
  @JsonKey(fromJson: _readTrimmedNullableString)
  final String? imageStoragePath;

  /// Weight in grams.
  @JsonKey(fromJson: _readIntOrZero)
  final int weightGrams;

  /// Creation date.
  @JsonKey(fromJson: _readDateTimeOrNow)
  final DateTime createdAt;

  /// Last update date.
  @JsonKey(fromJson: _readDateTimeOrNow)
  final DateTime updatedAt;

  /// Whether utensil has a non-empty name.
  bool get hasName => (name ?? '').trim().isNotEmpty;

  /// Whether utensil has a stored image.
  bool get hasImage => (imageStoragePath ?? '').trim().isNotEmpty;

  /// Whether utensil can be identified by name or photo.
  bool get hasIdentity => hasName || hasImage;

  /// Converts to json.
  Map<String, dynamic> toJson() => _$KitchenUtensilToJson(this);

  /// Copies this utensil.
  KitchenUtensil copyWith({
    String? id,
    Object? name = _keepValue,
    Object? imageStoragePath = _keepValue,
    int? weightGrams,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KitchenUtensil(
      id: id ?? this.id,
      name: name == _keepValue ? this.name : name as String?,
      imageStoragePath: imageStoragePath == _keepValue
          ? this.imageStoragePath
          : imageStoragePath as String?,
      weightGrams: weightGrams ?? this.weightGrams,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is KitchenUtensil &&
            other.id == id &&
            other.name == name &&
            other.imageStoragePath == imageStoragePath &&
            other.weightGrams == weightGrams &&
            other.createdAt == createdAt &&
            other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      imageStoragePath,
      weightGrams,
      createdAt,
      updatedAt,
    );
  }
}

const _keepValue = Object();

String _readRequiredString(Object? value) {
  return value is String ? value.trim() : '';
}

String? _readTrimmedNullableString(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int _readIntOrZero(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim()) ?? 0;
  }
  return 0;
}

DateTime _readDateTimeOrNow(Object? value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    final parsed = DateTime.tryParse(value.trim());
    if (parsed != null) {
      return parsed;
    }
  }
  return DateTime.now();
}
