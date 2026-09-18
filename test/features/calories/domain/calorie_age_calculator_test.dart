import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_age_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';

CalorieCalculatorProfile _profile({DateTime? birthDate, int ageYears = 30}) {
  return CalorieCalculatorProfile(
    sex: CalorieCalculatorSex.female,
    weightKg: 70,
    heightCm: 170,
    ageYears: ageYears,
    birthDate: birthDate,
    activityLevel: 1.375,
    goalMode: CalorieGoalMode.lose,
    goalSpeedKgPerWeek: 0.5,
  );
}

void main() {
  group('ageInYearsAt', () {
    test('counts full years after the birthday', () {
      expect(ageInYearsAt(DateTime(1990, 3, 10), DateTime(2026, 9, 17)), 36);
    });

    test('does not count the year before the birthday', () {
      expect(ageInYearsAt(DateTime(1990, 12, 10), DateTime(2026, 9, 17)), 35);
    });

    test('counts the birthday itself', () {
      expect(ageInYearsAt(DateTime(1990, 9, 17), DateTime(2026, 9, 17)), 36);
    });

    test('never returns a negative age', () {
      expect(ageInYearsAt(DateTime(2030), DateTime(2026, 9, 17)), 0);
    });
  });

  group('CalorieCalculatorProfile.ageAt', () {
    test('derives the age from the birth date', () {
      final profile = _profile(birthDate: DateTime(1996, 1, 5));

      expect(profile.ageAt(DateTime(2026, 9, 17)), 30);
    });

    test('falls back to the stored age without a birth date', () {
      expect(_profile(ageYears: 42).ageAt(DateTime(2026, 9, 17)), 42);
    });

    test('keeps the birth date through a json round trip', () {
      final profile = _profile(birthDate: DateTime(1996, 1, 5));

      final restored = CalorieCalculatorProfile.fromJson(
        Map<String, dynamic>.from(profile.toJson()),
      );

      expect(restored.birthDate, DateTime(1996, 1, 5));
    });
  });
}
