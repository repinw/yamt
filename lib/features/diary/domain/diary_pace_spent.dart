import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/domain/meal_type.dart';

/// The meals whose notice came or is pending on [day], read from [stored];
/// empty when [stored] is null, from another day, or broken.
Map<MealType, DateTime> decodeDiaryPaceSpent(String? stored, DateTime day) {
  if (stored?.split('|') case [final key, final pairs]
      when parseLocalDayKey(key) == day) {
    return {
      for (final pair in pairs.split(','))
        if (pair.split('=') case [final meal, final minute])
          if ((
                MealType.values.where((m) => m.jsonValue == meal).firstOrNull,
                int.tryParse(minute),
              )
              case (final MealType type, final int at))
            type: DateTime(day.year, day.month, day.day, 0, at),
    };
  }
  return {};
}

/// [spent] of [day] as one line of text, as "yyyy-mm-dd|meal=minute,...".
String encodeDiaryPaceSpent(DateTime day, Map<MealType, DateTime> spent) {
  final pairs = [
    for (final MapEntry(key: meal, value: at) in spent.entries)
      '${meal.jsonValue}=${at.hour * 60 + at.minute}',
  ];
  return '${localDayKey(normalizeLocalDay(day))}|${pairs.join(',')}';
}
