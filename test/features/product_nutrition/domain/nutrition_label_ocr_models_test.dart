import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/product_nutrition/domain/'
    'nutrition_label_ocr_models.dart';

NutritionLabelOcrDraft _draft({
  double kj = 1650,
  double kcal = 393,
  double fat = 8.2,
  double saturatedFat = 1.4,
  double carbs = 63,
  double sugar = 17,
  double protein = 10,
  double salt = 0.45,
  double? polyunsaturatedFat,
  double? fiber = 7.5,
}) {
  return NutritionLabelOcrDraft(
    barcode: '4006381333931',
    per100Kj: kj,
    per100Kcal: kcal,
    per100Fat: fat,
    per100SaturatedFat: saturatedFat,
    per100Carbs: carbs,
    per100Sugar: sugar,
    per100Protein: protein,
    per100Salt: salt,
    per100PolyunsaturatedFat: polyunsaturatedFat,
    per100Fiber: fiber,
  );
}

void main() {
  group('NutritionLabelOcrDraft.isPlausible', () {
    test('accepts a regular label', () {
      expect(_draft().isPlausible, isTrue);
    });

    test('accepts water with only zeros', () {
      expect(
        _draft(
          kj: 0,
          kcal: 0,
          fat: 0,
          saturatedFat: 0,
          carbs: 0,
          sugar: 0,
          protein: 0,
          salt: 0,
          fiber: null,
        ).isPlausible,
        isTrue,
      );
    });

    test('accepts sugar-free gum whose kcal is far below the macros', () {
      expect(
        _draft(
          kj: 640,
          kcal: 153,
          fat: 0,
          saturatedFat: 0,
          carbs: 64,
          sugar: 0,
          protein: 0,
          salt: 0,
          fiber: null,
        ).isPlausible,
        isTrue,
      );
    });

    test('accepts rounding on the davon rows', () {
      expect(_draft(saturatedFat: 8.3, sugar: 63.1).isPlausible, isTrue);
    });

    test('accepts oil at 900 kcal and 100 g fat', () {
      expect(
        _draft(
          kj: 3700,
          kcal: 900,
          fat: 100,
          saturatedFat: 14,
          carbs: 0,
          sugar: 0,
          protein: 0,
          salt: 0,
          fiber: null,
        ).isPlausible,
        isTrue,
      );
    });

    final rejected = <String, NutritionLabelOcrDraft>{
      'negative value': _draft(salt: -0.1),
      'saturates above fat': _draft(saturatedFat: 9.5),
      'polyunsaturates above fat': _draft(polyunsaturatedFat: 9),
      'sugar above carbs': _draft(sugar: 70),
      'more than 100 g of nutrients': _draft(carbs: 90),
      'kcal above 900': _draft(kj: 3900, kcal: 932),
      'kJ that does not match kcal': _draft(kj: 900),
    };
    for (final MapEntry(key: reason, value: draft) in rejected.entries) {
      test('rejects $reason', () {
        expect(draft.isPlausible, isFalse);
      });
    }
  });
}
