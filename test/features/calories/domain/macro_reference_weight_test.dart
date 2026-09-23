import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/macro_reference_weight.dart';

void main() {
  group('macroReferenceWeightKg', () {
    test('keeps the full weight up to a BMI of 25', () {
      expect(macroReferenceWeightKg(weightKg: 75, heightCm: 180), 75);
    });

    test('counts only 40 percent of the weight above a BMI of 25', () {
      // BMI 25 at 180 cm is 81 kg; 0.4 of the 49 kg above it counts.
      expect(
        macroReferenceWeightKg(weightKg: 130, heightCm: 180),
        closeTo(100.6, 0.001),
      );
    });

    test('keeps the weight when the height is unknown', () {
      expect(macroReferenceWeightKg(weightKg: 130, heightCm: 0), 130);
    });
  });

  group('macroAdjustedWeightKg', () {
    test('is null up to a BMI of 25', () {
      expect(macroAdjustedWeightKg(weightKg: 75, heightCm: 180), isNull);
    });

    test('returns the reference weight above a BMI of 25', () {
      expect(
        macroAdjustedWeightKg(weightKg: 130, heightCm: 180),
        closeTo(100.6, 0.001),
      );
    });
  });
}
