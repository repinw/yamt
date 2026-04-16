import 'package:json_annotation/json_annotation.dart';

/// Defines meal type.
@JsonEnum(valueField: 'jsonValue')
enum MealType {
  /// Breakfast.
  breakfast('breakfast'),

  /// Lunch.
  lunch('lunch'),

  /// Dinner.
  dinner('dinner'),

  /// Snack.
  snack('snack')
  ;

  const MealType(this.jsonValue);

  /// The json value.
  final String jsonValue;

  /// The section order.
  static const List<MealType> sectionOrder = <MealType>[
    MealType.breakfast,
    MealType.lunch,
    MealType.dinner,
    MealType.snack,
  ];

  /// From json value.
  static MealType fromJsonValue(String? value) {
    return switch (value) {
      'breakfast' => MealType.breakfast,
      'lunch' => MealType.lunch,
      'dinner' => MealType.dinner,
      _ => MealType.snack,
    };
  }

  /// Default for date time.
  static MealType defaultForDateTime(DateTime dateTime) {
    return fromHour(dateTime.hour);
  }

  /// From hour.
  static MealType fromHour(int hour) {
    if (hour >= 5 && hour < 11) {
      return MealType.breakfast;
    }
    if (hour >= 11 && hour < 16) {
      return MealType.lunch;
    }
    if (hour >= 16 && hour < 22) {
      return MealType.dinner;
    }
    return MealType.snack;
  }
}
