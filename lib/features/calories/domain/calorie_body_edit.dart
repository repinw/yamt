import 'package:yamt/features/calories/domain/calorie_age_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';

/// Smallest body height in cm that a body edit accepts.
const minimumBodyHeightCm = 120.0;

/// Largest body height in cm that a body edit accepts.
const maximumBodyHeightCm = 230.0;

/// Smallest start weight in kg that a body edit accepts.
const minimumStartWeightKg = 30.0;

/// Largest start weight in kg that a body edit accepts.
const maximumStartWeightKg = 300.0;

/// Youngest age in years that a birthday edit accepts.
const minimumBodyAgeYears = 16;

/// Oldest age in years that a birthday edit accepts.
const maximumBodyAgeYears = 100;

/// A change to one body fact of the calculator profile.
sealed class CalorieBodyEdit {
  const new();
}

/// Sets the body height.
final class CalorieHeightEdit extends CalorieBodyEdit {
  /// Creates a height edit.
  const new(this.heightCm);

  /// The new height in cm.
  final double heightCm;
}

/// Sets the sex.
final class CalorieSexEdit extends CalorieBodyEdit {
  /// Creates a sex edit.
  const new(this.sex);

  /// The new sex.
  final CalorieCalculatorSex sex;
}

/// Sets the birthday.
final class CalorieBirthDateEdit extends CalorieBodyEdit {
  /// Creates a birthday edit.
  const new(this.birthDate);

  /// The new birthday.
  final DateTime birthDate;
}

/// Sets the weight at the goal start.
final class CalorieStartWeightEdit extends CalorieBodyEdit {
  /// Creates a start weight edit.
  const new(this.weightKg);

  /// The new start weight in kg.
  final double weightKg;
}

/// Applies a [CalorieBodyEdit] to a [CalorieCalculatorProfile].
extension CalorieBodyEditProfile on CalorieCalculatorProfile {
  /// Returns this profile with [edit] applied. A birthday also sets the age
  /// in full years at [ageDay], because the calculator reads that age.
  CalorieCalculatorProfile withBodyEdit(
    CalorieBodyEdit edit, {
    required DateTime ageDay,
  }) {
    return switch (edit) {
      CalorieHeightEdit(:final heightCm) => copyWith(heightCm: heightCm),
      CalorieSexEdit(:final sex) => copyWith(sex: sex),
      CalorieBirthDateEdit(:final birthDate) => copyWith(
        birthDate: birthDate,
        ageYears: ageInYearsAt(birthDate, ageDay),
      ),
      CalorieStartWeightEdit(:final weightKg) => copyWith(weightKg: weightKg),
    };
  }

  /// Whether [edit] leaves this profile as it is.
  bool isUnchangedBy(CalorieBodyEdit edit) {
    return switch (edit) {
      CalorieHeightEdit(:final heightCm) => heightCm == this.heightCm,
      CalorieSexEdit(:final sex) => sex == this.sex,
      CalorieBirthDateEdit(:final birthDate) => birthDate == this.birthDate,
      CalorieStartWeightEdit(:final weightKg) => weightKg == this.weightKg,
    };
  }
}
