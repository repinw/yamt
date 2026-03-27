import 'dart:convert';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/features/calories/domain/calories_json_converters.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';

part 'calorie_entry.g.dart';

@JsonEnum(valueField: 'jsonValue')
enum ConsumedUnit {
  grams('g'),
  milliliters('ml');

  const ConsumedUnit(this.jsonValue);

  final String jsonValue;

  static ConsumedUnit fromJsonValue(String? value) {
    return switch (value) {
      'ml' => ConsumedUnit.milliliters,
      _ => ConsumedUnit.grams,
    };
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CalorieEntryBundleComponent {
  const CalorieEntryBundleComponent({
    required this.name,
    required this.amountLabel,
    required this.totalKcal,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    this.brand,
    this.imageUrl,
  });

  final String name;
  final String amountLabel;
  final String? brand;
  final String? imageUrl;
  @FlexibleDoubleConverter()
  final double totalKcal;
  @FlexibleDoubleConverter()
  final double totalProtein;
  @FlexibleDoubleConverter()
  final double totalCarbs;
  @FlexibleDoubleConverter()
  final double totalFat;

  factory CalorieEntryBundleComponent.fromJson(Map<String, dynamic> json) {
    return _$CalorieEntryBundleComponentFromJson(json);
  }

  Map<String, dynamic> toJson() => _$CalorieEntryBundleComponentToJson(this);

  CalorieEntryBundleComponent copyWith({
    String? name,
    String? amountLabel,
    String? brand,
    String? imageUrl,
    double? totalKcal,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
  }) {
    return CalorieEntryBundleComponent(
      name: name ?? this.name,
      amountLabel: amountLabel ?? this.amountLabel,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      totalKcal: totalKcal ?? this.totalKcal,
      totalProtein: totalProtein ?? this.totalProtein,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
    );
  }
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CalorieEntry {
  const CalorieEntry({
    required this.id,
    required this.userId,
    required this.name,
    required this.mealType,
    required this.consumedAmount,
    required this.consumedUnit,
    required this.per100Kcal,
    required this.per100Protein,
    required this.per100Carbs,
    required this.per100Fat,
    required this.totalKcal,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.loggedAt,
    required this.createdAt,
    required this.updatedAt,
    this.brand,
    this.imageUrl,
    this.imageBase64,
    this.bundleSourcePreparedMealId,
    this.bundleConsumedPortions,
    this.bundleTotalPortions,
    this.bundleComponents = const <CalorieEntryBundleComponent>[],
  });

  factory CalorieEntry.create({
    required String id,
    required String userId,
    required String name,
    required MealType mealType,
    required double consumedAmount,
    required ConsumedUnit consumedUnit,
    required double per100Kcal,
    required double per100Protein,
    required double per100Carbs,
    required double per100Fat,
    DateTime? loggedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? brand,
    String? imageUrl,
    String? imageBase64,
  }) {
    final now = DateTime.now();
    final factor = consumedAmount / 100;

    return CalorieEntry(
      id: id,
      userId: userId,
      name: name,
      mealType: mealType,
      consumedAmount: consumedAmount,
      consumedUnit: consumedUnit,
      per100Kcal: per100Kcal,
      per100Protein: per100Protein,
      per100Carbs: per100Carbs,
      per100Fat: per100Fat,
      totalKcal: per100Kcal * factor,
      totalProtein: per100Protein * factor,
      totalCarbs: per100Carbs * factor,
      totalFat: per100Fat * factor,
      loggedAt: loggedAt ?? now,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      brand: brand,
      imageUrl: imageUrl,
      imageBase64: imageBase64,
    );
  }

  factory CalorieEntry.bundle({
    required String id,
    required String userId,
    required String name,
    required MealType mealType,
    required double totalKcal,
    required double totalProtein,
    required double totalCarbs,
    required double totalFat,
    required String bundleSourcePreparedMealId,
    required int bundleConsumedPortions,
    required int bundleTotalPortions,
    required List<CalorieEntryBundleComponent> bundleComponents,
    DateTime? loggedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? brand,
    String? imageUrl,
    String? imageBase64,
  }) {
    final now = DateTime.now();

    return CalorieEntry(
      id: id,
      userId: userId,
      name: name,
      brand: brand,
      imageUrl: imageUrl,
      imageBase64: imageBase64,
      mealType: mealType,
      consumedAmount: 100,
      consumedUnit: ConsumedUnit.grams,
      per100Kcal: totalKcal,
      per100Protein: totalProtein,
      per100Carbs: totalCarbs,
      per100Fat: totalFat,
      totalKcal: totalKcal,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      loggedAt: loggedAt ?? now,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      bundleSourcePreparedMealId: bundleSourcePreparedMealId,
      bundleConsumedPortions: bundleConsumedPortions,
      bundleTotalPortions: bundleTotalPortions,
      bundleComponents: bundleComponents,
    );
  }

  factory CalorieEntry.fromJson(Map<String, dynamic> json) {
    return _$CalorieEntryFromJson(json);
  }

  final String id;
  final String userId;
  final String name;
  final String? brand;
  final String? imageUrl;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? imageBase64;
  final String? bundleSourcePreparedMealId;
  final int? bundleConsumedPortions;
  final int? bundleTotalPortions;
  @JsonKey(defaultValue: <CalorieEntryBundleComponent>[])
  final List<CalorieEntryBundleComponent> bundleComponents;
  @JsonKey(defaultValue: MealType.snack, unknownEnumValue: MealType.snack)
  final MealType mealType;
  @FlexibleDoubleConverter()
  final double consumedAmount;
  @JsonKey(
    defaultValue: ConsumedUnit.grams,
    unknownEnumValue: ConsumedUnit.grams,
  )
  final ConsumedUnit consumedUnit;
  @FlexibleDoubleConverter()
  final double per100Kcal;
  @FlexibleDoubleConverter()
  final double per100Protein;
  @FlexibleDoubleConverter()
  final double per100Carbs;
  @FlexibleDoubleConverter()
  final double per100Fat;
  @FlexibleDoubleConverter()
  final double totalKcal;
  @FlexibleDoubleConverter()
  final double totalProtein;
  @FlexibleDoubleConverter()
  final double totalCarbs;
  @FlexibleDoubleConverter()
  final double totalFat;
  @FlexibleDateTimeConverter()
  final DateTime loggedAt;
  @FlexibleDateTimeConverter()
  final DateTime createdAt;
  @FlexibleDateTimeConverter()
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$CalorieEntryToJson(this);

  bool get isValid {
    if (id.trim().isEmpty || userId.trim().isEmpty || name.trim().isEmpty) {
      return false;
    }
    if (consumedAmount <= 0) {
      return false;
    }
    if (per100Kcal < 0 || per100Protein < 0 || per100Carbs < 0) {
      return false;
    }
    if (per100Fat < 0 || totalKcal < 0 || totalProtein < 0) {
      return false;
    }
    if (totalCarbs < 0 || totalFat < 0) {
      return false;
    }
    return true;
  }

  bool get isBundle {
    return (bundleSourcePreparedMealId?.trim().isNotEmpty ?? false) &&
        bundleComponents.isNotEmpty;
  }

  Uint8List? get imageBytes {
    final raw = imageBase64?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  CalorieEntry copyWith({
    String? id,
    String? userId,
    String? name,
    String? brand,
    String? imageUrl,
    Object? imageBase64 = _keepValue,
    Object? bundleSourcePreparedMealId = _keepValue,
    Object? bundleConsumedPortions = _keepValue,
    Object? bundleTotalPortions = _keepValue,
    List<CalorieEntryBundleComponent>? bundleComponents,
    MealType? mealType,
    double? consumedAmount,
    ConsumedUnit? consumedUnit,
    double? per100Kcal,
    double? per100Protein,
    double? per100Carbs,
    double? per100Fat,
    double? totalKcal,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
    DateTime? loggedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalorieEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      imageBase64: imageBase64 == _keepValue
          ? this.imageBase64
          : imageBase64 as String?,
      bundleSourcePreparedMealId: bundleSourcePreparedMealId == _keepValue
          ? this.bundleSourcePreparedMealId
          : bundleSourcePreparedMealId as String?,
      bundleConsumedPortions: bundleConsumedPortions == _keepValue
          ? this.bundleConsumedPortions
          : bundleConsumedPortions as int?,
      bundleTotalPortions: bundleTotalPortions == _keepValue
          ? this.bundleTotalPortions
          : bundleTotalPortions as int?,
      bundleComponents: bundleComponents ?? this.bundleComponents,
      mealType: mealType ?? this.mealType,
      consumedAmount: consumedAmount ?? this.consumedAmount,
      consumedUnit: consumedUnit ?? this.consumedUnit,
      per100Kcal: per100Kcal ?? this.per100Kcal,
      per100Protein: per100Protein ?? this.per100Protein,
      per100Carbs: per100Carbs ?? this.per100Carbs,
      per100Fat: per100Fat ?? this.per100Fat,
      totalKcal: totalKcal ?? this.totalKcal,
      totalProtein: totalProtein ?? this.totalProtein,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
      loggedAt: loggedAt ?? this.loggedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  CalorieEntry recalculateTotals({DateTime? updatedAt}) {
    if (isBundle) {
      return copyWith(updatedAt: updatedAt ?? DateTime.now());
    }

    final factor = consumedAmount / 100;
    return copyWith(
      totalKcal: per100Kcal * factor,
      totalProtein: per100Protein * factor,
      totalCarbs: per100Carbs * factor,
      totalFat: per100Fat * factor,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

const Object _keepValue = Object();
