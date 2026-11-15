import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/domain/scanned_ingredient_list.dart';

void main() {
  group('ScannedIngredientList.fromJson', () {
    test('reads title, servings, ingredients and steps', () {
      final scanned = ScannedIngredientList.fromJson(const {
        'title': 'Pancakes',
        'servings': 4,
        'ingredients': ['200 g Mehl', '2 Eier'],
        'steps': ['Mischen', 'Braten'],
      });

      expect(scanned.title, 'Pancakes');
      expect(scanned.servings, 4);
      expect(scanned.ingredients, ['200 g Mehl', '2 Eier']);
      expect(scanned.steps, ['Mischen', 'Braten']);
    });

    test('a missing title and servings become null', () {
      final scanned = ScannedIngredientList.fromJson(const {
        'ingredients': <Object?>[],
        'steps': <Object?>[],
      });

      expect(scanned.title, isNull);
      expect(scanned.servings, isNull);
    });

    test('a null title and servings stay null', () {
      final scanned = ScannedIngredientList.fromJson(const {
        'title': null,
        'servings': null,
        'ingredients': <Object?>[],
        'steps': <Object?>[],
      });

      expect(scanned.title, isNull);
      expect(scanned.servings, isNull);
    });

    test('an empty or blank title becomes null', () {
      for (final title in ['', '   ']) {
        final scanned = ScannedIngredientList.fromJson({
          'title': title,
          'ingredients': const <Object?>[],
          'steps': const <Object?>[],
        });
        expect(scanned.title, isNull, reason: 'title "$title"');
      }
    });

    test('trims the title and the lines and drops empty lines', () {
      final scanned = ScannedIngredientList.fromJson(const {
        'title': '  Suppe ',
        'ingredients': ['  1 Zwiebel ', '', '   ', 'Salz'],
        'steps': ['  Kochen  ', ''],
      });

      expect(scanned.title, 'Suppe');
      expect(scanned.ingredients, ['1 Zwiebel', 'Salz']);
      expect(scanned.steps, ['Kochen']);
    });

    test('throws a FormatException for a non-map', () {
      for (final json in <Object?>[null, 'text', 3, <Object?>[]]) {
        expect(
          () => ScannedIngredientList.fromJson(json),
          throwsFormatException,
          reason: 'json $json',
        );
      }
    });

    test('throws a FormatException for non-integer servings', () {
      for (final servings in <Object?>['4', 2.5, true]) {
        expect(
          () => ScannedIngredientList.fromJson({
            'servings': servings,
            'ingredients': const <Object?>[],
            'steps': const <Object?>[],
          }),
          throwsFormatException,
          reason: 'servings $servings',
        );
      }
    });

    test('throws a FormatException for a non-string title', () {
      expect(
        () => ScannedIngredientList.fromJson(const {
          'title': 5,
          'ingredients': <Object?>[],
          'steps': <Object?>[],
        }),
        throwsFormatException,
      );
    });

    test('throws a FormatException for non-list ingredients or steps', () {
      expect(
        () => ScannedIngredientList.fromJson(const {
          'ingredients': 'Mehl',
          'steps': <Object?>[],
        }),
        throwsFormatException,
      );
      expect(
        () => ScannedIngredientList.fromJson(const {'steps': <Object?>[]}),
        throwsFormatException,
      );
      expect(
        () => ScannedIngredientList.fromJson(const {
          'ingredients': <Object?>[],
          'steps': {'a': 1},
        }),
        throwsFormatException,
      );
    });

    test('throws a FormatException for a non-string line', () {
      expect(
        () => ScannedIngredientList.fromJson(const {
          'ingredients': ['Mehl', 3],
          'steps': <Object?>[],
        }),
        throwsFormatException,
      );
      expect(
        () => ScannedIngredientList.fromJson(const {
          'ingredients': <Object?>[],
          'steps': [null],
        }),
        throwsFormatException,
      );
    });
  });
}
