import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';

void main() {
  group('normalizeGlobalFoodText', () {
    test('converts German umlauts and sharp s correctly', () {
      expect(normalizeGlobalFoodText('Räucherlachs'), 'raeucherlachs');
      expect(normalizeGlobalFoodText('Frischkäse'), 'frischkaese');
      expect(normalizeGlobalFoodText('Käse'), 'kaese');
      expect(normalizeGlobalFoodText('Müsli'), 'muesli');
      expect(normalizeGlobalFoodText('Öl'), 'oel');
      expect(normalizeGlobalFoodText('Süßkartoffel'), 'suesskartoffel');
      expect(normalizeGlobalFoodText('Hähnchen'), 'haehnchen');
    });

    test('normalizes whitespace and removes special characters', () {
      expect(
        normalizeGlobalFoodText('  Bio-Vollmilch 3,5%  '),
        'bio vollmilch 3 5',
      );
    });
  });

  group('buildGlobalFoodSearchTokens', () {
    test(
      'does not produce single-character tokens for umlauts like Räucherlachs',
      () {
        final tokens = buildGlobalFoodSearchTokens(name: 'Räucherlachs');

        expect(tokens, contains('raeucherlachs'));
        expect(tokens, isNot(contains('r')));
        expect(tokens, isNot(contains('ucherlachs')));
        expect(tokens.every((token) => token.length >= 2), isTrue);
      },
    );

    test('filters out pure numeric tokens and single characters', () {
      final tokens = buildGlobalFoodSearchTokens(
        name: 'Milch 1,5% 1L',
        brand: 'B',
      );

      expect(tokens, contains('milch 1 5 1l'));
      expect(tokens, contains('milch'));
      expect(tokens, contains('1l'));
      expect(tokens, isNot(contains('1')));
      expect(tokens, isNot(contains('5')));
      expect(tokens, isNot(contains('b')));
      expect(tokens.every((token) => token.length >= 2), isTrue);
      expect(
        tokens.any((token) => RegExp(r'^\d+$').hasMatch(token)),
        isFalse,
      );
    });
  });
}
