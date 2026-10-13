import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_weight_entry.dart';

void main() {
  test('the food alone counts in whole grams', () {
    expect(const PreparedMealWeightEntry('1250').netWeight, 1250);
    expect(const PreparedMealWeightEntry(' 850 ').netWeight, 850);
    // A decimal comma or point is rounded.
    expect(const PreparedMealWeightEntry('850,4').netWeight, 850);
    expect(const PreparedMealWeightEntry('850.5').netWeight, 851);
    // A thousands point is no decimal.
    expect(const PreparedMealWeightEntry('1.250').netWeight, 1250);
    expect(const PreparedMealWeightEntry('1.250,5').netWeight, 1251);
  });

  test('the pot on the scale loses the empty pot', () {
    const entry = PreparedMealWeightEntry('2380', tareWeight: 1180);

    expect(entry.scaleWeight, 2380);
    expect(entry.netWeight, 1200);
    expect(entry.isTooLight, isFalse);
    expect(entry.isInvalid, isFalse);
  });

  test('a pot no heavier than empty is too light', () {
    for (final text in ['1180', '900']) {
      final entry = PreparedMealWeightEntry(text, tareWeight: 1180);

      expect(entry.netWeight, isNull, reason: text);
      expect(entry.isTooLight, isTrue, reason: text);
      expect(entry.isInvalid, isFalse, reason: text);
    }
  });

  test('no weight from 1 g to the most a field takes is invalid', () {
    for (final text in ['0', '0,4', ',', '1,2,3', '100000', '99999,5']) {
      final entry = PreparedMealWeightEntry(text);

      expect(entry.netWeight, isNull, reason: text);
      expect(entry.isInvalid, isTrue, reason: text);
      expect(entry.isTooLight, isFalse, reason: text);
    }
    expect(const PreparedMealWeightEntry('99999').netWeight, 99999);
  });

  test('an empty field is neither a weight nor an error', () {
    const entry = PreparedMealWeightEntry('', tareWeight: 1180);

    expect(entry.netWeight, isNull);
    expect(entry.isInvalid, isFalse);
    expect(entry.isTooLight, isFalse);
  });
}
