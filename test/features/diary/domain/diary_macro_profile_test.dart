import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/domain/diary_macro_profile.dart';

void main() {
  DiaryMacroProfile? profile(
    double protein,
    double carbs,
    double fat,
  ) => DiaryMacroProfile.calculate(
    protein: protein,
    carbs: carbs,
    fat: fat,
  );

  test('describes each nutrient by energy rather than gram weight', () {
    expect(profile(30, 10, 4)!.emphasis, DiaryMacroEmphasis.protein);
    expect(profile(10, 30, 4)!.emphasis, DiaryMacroEmphasis.carbs);
    expect(profile(20, 20, 20)!.emphasis, DiaryMacroEmphasis.fat);
    expect(profile(25, 25, 100 / 9)!.emphasis, DiaryMacroEmphasis.mixed);
  });

  test('ten percentage points qualify without rounding the shares', () {
    // 40%, 30%, 30% is exactly the qualifying boundary.
    expect(profile(10, 7.5, 30 / 9)!.emphasis, DiaryMacroEmphasis.protein);
    expect(profile(9.999, 7.501, 30 / 9)!.emphasis, DiaryMacroEmphasis.mixed);
    expect(profile(12.5, 12.5, 0)!.emphasis, DiaryMacroEmphasis.mixed);
  });

  test('changing portion size preserves the emphasis and energy shares', () {
    final small = profile(25, 12, 4)!;
    final large = profile(75, 36, 12)!;
    expect(large.emphasis, small.emphasis);
    expect(large.protein, closeTo(small.protein, 1e-12));
    expect(small.protein + small.carbs + small.fat, closeTo(1, 1e-12));
  });

  test('empty and invalid values have no label', () {
    expect(profile(0, 0, 0), isNull);
    expect(profile(-1, 5, 5), isNull);
    expect(profile(double.nan, 5, 5), isNull);
    expect(profile(1, double.infinity, 5), isNull);
  });
}
