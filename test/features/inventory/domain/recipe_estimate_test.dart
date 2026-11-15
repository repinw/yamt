import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/recipe_estimate.dart';

import '../../../support/prepared_meal_test_data.dart';

final _at = DateTime.utc(2026, 11, 13, 10);

RecipeEstimate _estimate({List<RecipeLineNutrition>? lines}) => RecipeEstimate(
  kcal: 600,
  protein: 20,
  carbs: 80,
  fat: 15,
  portions: 2,
  linesKey: recipeLinesKey(const ['200 g Pasta', '100 g Tomaten']),
  createdAt: _at,
  lines: lines,
);

const _pasta = RecipeLineNutrition(kcal: 700, protein: 24, carbs: 140, fat: 4);
const _tomato = RecipeLineNutrition(kcal: 20, protein: 1, carbs: 4, fat: 0.5);

void main() {
  group('RecipeLineNutrition', () {
    test('round-trips through json with snake case keys', () {
      final json = _pasta.toJson();

      expect(json, {
        'kcal': 700.0,
        'protein': 24.0,
        'carbs': 140.0,
        'fat': 4.0,
      });
      expect(RecipeLineNutrition.fromJson(json), _pasta);
    });

    test('scaled multiplies every value', () {
      final scaled = _tomato.scaled(3);

      expect(scaled.kcal, 60);
      expect(scaled.protein, 3);
      expect(scaled.carbs, 12);
      expect(scaled.fat, 1.5);
    });

    test('scaled by 1 equals the line, by 0 gives zeros', () {
      expect(_pasta.scaled(1), _pasta);
      expect(
        _pasta.scaled(0),
        const RecipeLineNutrition(kcal: 0, protein: 0, carbs: 0, fat: 0),
      );
    });

    test('equal lines have equal hashes', () {
      expect(
        _pasta.hashCode,
        const RecipeLineNutrition(
          kcal: 700,
          protein: 24,
          carbs: 140,
          fat: 4,
        ).hashCode,
      );
      expect(_pasta, isNot(_tomato));
    });
  });

  group('RecipeEstimate.lines', () {
    test('round-trip through json in order', () {
      final estimate = _estimate(lines: const [_pasta, _tomato]);

      final restored = RecipeEstimate.fromJson(estimate.toJson());

      expect(restored, estimate);
      expect(restored.lines, [_pasta, _tomato]);
    });

    test('an estimate without lines has no lines key in its json', () {
      final json = _estimate().toJson();

      expect(json.containsKey('lines'), isFalse);
      expect(RecipeEstimate.fromJson(json).lines, isNull);
    });

    test('an old json without lines still reads', () {
      final restored = RecipeEstimate.fromJson({
        'kcal': 600,
        'protein': 20,
        'carbs': 80,
        'fat': 15,
        'portions': 2,
        'lines_key': 'a\nb',
        'created_at': _at.toIso8601String(),
      });

      expect(restored.lines, isNull);
      expect(restored.kcal, 600);
    });

    test('estimates differ by their lines', () {
      expect(_estimate(lines: const [_pasta]), isNot(_estimate()));
      expect(
        _estimate(lines: const [_pasta]),
        _estimate(lines: const [_pasta]),
      );
      expect(
        _estimate(lines: const [_pasta]).hashCode,
        _estimate(lines: const [_pasta]).hashCode,
      );
    });

    test('isFor ignores the lines nutrition', () {
      final estimate = _estimate(lines: const [_pasta, _tomato]);

      expect(estimate.isFor(const ['200 g Pasta', '100 g Tomaten'], 2), isTrue);
      expect(estimate.isFor(const ['200 g Pasta'], 2), isFalse);
      expect(
        estimate.isFor(const ['200 g Pasta', '100 g Tomaten'], 4),
        isFalse,
      );
    });

    test('survive the json of a PreparedMeal', () {
      final meal = preparedMealTestData().copyWith(
        recipeEstimate: _estimate(lines: const [_pasta, _tomato]),
      );

      final restored = PreparedMeal.fromJson(meal.toJson());

      expect(restored.recipeEstimate!.lines, [_pasta, _tomato]);
      expect(restored.recipeEstimate, meal.recipeEstimate);
    });

    test('an estimate without lines stays so through a PreparedMeal', () {
      final meal = preparedMealTestData().copyWith(recipeEstimate: _estimate());

      final restored = PreparedMeal.fromJson(meal.toJson());

      expect(restored.recipeEstimate!.lines, isNull);
      expect(
        (meal.toJson()['recipe_estimate']! as Map<String, dynamic>).containsKey(
          'lines',
        ),
        isFalse,
      );
    });
  });
}
