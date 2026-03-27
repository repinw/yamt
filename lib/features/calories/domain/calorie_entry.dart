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
  });

  final String id;
  final String userId;
  final String name;
  final String? brand;
  final String? imageUrl;
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
    );
  }

  factory CalorieEntry.fromJson(Map<String, dynamic> json) {
    return _$CalorieEntryFromJson(json);
  }

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

  CalorieEntry copyWith({
    String? id,
    String? userId,
    String? name,
    String? brand,
    String? imageUrl,
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
