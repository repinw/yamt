import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/diary/domain/diary_meal_shares.dart';

void main() {
  test('the standard split puts the borders at 25, 60 and 90 %', () {
    expect(DiaryMealShares.standard.boundaries, [25, 60, 90]);
    expect(DiaryMealShares.standard.of(MealType.lunch), 0.35);
  });

  group('decode', () {
    test('reads what encode wrote, also a meal at 0', () {
      const shares = DiaryMealShares([0, 60, 30, 10]);

      expect(shares.encode(), '0,60,30,10');
      expect(DiaryMealShares.decode(shares.encode()), shares);
    });

    test('rejects all but four parts of at least 0 that add up to 100', () {
      for (final value in [
        '25,35,30',
        '25,35,30,10,0',
        '30,35,30,10',
        '-5,40,55,10',
        '25,35,x,10',
        '',
      ]) {
        expect(DiaryMealShares.decode(value), isNull, reason: value);
      }
    });
  });

  group('moveBoundary', () {
    test('moves a border and resizes the two meals next to it', () {
      expect(DiaryMealShares.standard.moveBoundary(0, 30).percents, [
        30,
        30,
        30,
        10,
      ]);
    });

    test('stops at the next border and leaves the meal between at 0', () {
      expect(DiaryMealShares.standard.moveBoundary(1, 95).percents, [
        25,
        65,
        0,
        10,
      ]);
      expect(DiaryMealShares.standard.moveBoundary(0, -10).percents, [
        0,
        60,
        30,
        10,
      ]);
    });
  });

  group('boundaryAt', () {
    test('takes the nearest border', () {
      expect(DiaryMealShares.standard.boundaryAt(40, rightward: true), 0);
      expect(DiaryMealShares.standard.boundaryAt(80, rightward: false), 2);
    });

    test('of two borders on one spot, the drag direction picks, so a meal '
        'at 0 comes back either way', () {
      const dinnerOff = DiaryMealShares([25, 35, 0, 40]);

      expect(dinnerOff.boundaries, [25, 60, 60]);
      expect(dinnerOff.boundaryAt(60, rightward: true), 2);
      expect(dinnerOff.boundaryAt(60, rightward: false), 1);
      expect(dinnerOff.moveBoundary(2, 70).percents, [25, 35, 10, 30]);
      expect(dinnerOff.moveBoundary(1, 50).percents, [25, 25, 10, 40]);
    });
  });
  group('splitKcal', () {
    test('the parts add up to the target', () {
      final parts = DiaryMealShares.standard.splitKcal(2204);

      expect(parts.reduce((a, b) => a + b), 2204);
      expect(parts.first, 551);
    });

    test('a meal at 0 gets nothing', () {
      const shares = DiaryMealShares([30, 70, 0, 0]);

      expect(shares.splitKcal(1999), [600, 1399, 0, 0]);
    });
  });
}
