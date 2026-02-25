import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'jsonValue')
enum MealType {
  breakfast('breakfast'),
  lunch('lunch'),
  dinner('dinner'),
  snack('snack');

  const MealType(this.jsonValue);

  final String jsonValue;

  static const List<MealType> sectionOrder = <MealType>[
    MealType.breakfast,
    MealType.lunch,
    MealType.dinner,
    MealType.snack,
  ];

  static MealType fromJsonValue(String? value) {
    return switch (value) {
      'breakfast' => MealType.breakfast,
      'lunch' => MealType.lunch,
      'dinner' => MealType.dinner,
      _ => MealType.snack,
    };
  }

  static MealType defaultForDateTime(DateTime dateTime) {
    return fromHour(dateTime.hour);
  }

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
