import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/recipes/domain/cook_line_not_counted.dart';

void main() {
  group('cookLineNotCounted', () {
    test('a pinch does not count', () {
      for (final text in [
        '1 Prise Salz',
        '2 Prisen Zucker',
        'Msp. Muskat',
        'eine Messerspitze Zimt',
        'a pinch of nutmeg',
      ]) {
        expect(cookLineNotCounted(text), isTrue, reason: text);
      }
    });

    test('salt, pepper and water alone do not count', () {
      for (final text in [
        'Salz',
        'Pfeffer',
        'Wasser',
        'Salz und Pfeffer',
        'Salz nach Geschmack',
        'Pfeffer nach Geschmack',
        'etwas Salz',
        'salt to taste',
        'frisch gemahlener Pfeffer',
      ]) {
        expect(cookLineNotCounted(text), isTrue, reason: text);
      }
    });

    test('"etwas" and "nach Geschmack" alone do not leave a line out', () {
      for (final text in [
        'etwas Öl',
        'etwas Butter',
        'Zucker nach Geschmack',
        'sugar to taste',
        'Öl nach Geschmack',
      ]) {
        expect(cookLineNotCounted(text), isFalse, reason: text);
      }
    });

    test('a food with an amount counts', () {
      for (final text in ['200 g Mehl', '1 Zwiebel', '2 EL Öl']) {
        expect(cookLineNotCounted(text), isFalse, reason: text);
      }
    });

    test('measured water counts as water: it does not count', () {
      // What the function documents: "500 ml Wasser" is left out.
      expect(cookLineNotCounted('500 ml Wasser'), isTrue);
      expect(cookLineNotCounted('200 ml Wasser'), isTrue);
    });

    test('salt with another food does not leave the line out', () {
      expect(cookLineNotCounted('Salz und Butter'), isFalse);
      expect(cookLineNotCounted('Pfeffer, Paprika'), isFalse);
    });

    test('salt, pepper and water with a kind word do not count', () {
      for (final text in [
        '1/2 TL Schwarzer Pfeffer',
        'Schwarzer Pfeffer',
        'Frisch gemahlener schwarzer Pfeffer',
        'Warmes Wasser',
        'Grobes Meersalz',
        '200 ml Kaltes Wasser',
      ]) {
        expect(cookLineNotCounted(text), isTrue, reason: text);
      }
    });

    test('a kind word alone or beside another food keeps the line', () {
      for (final text in [
        'Schwarzer Tee',
        '2 EL Schwarzer Tee',
        'Warmer Apfelstrudel',
        'Schwarzer Pfeffer und Butter',
      ]) {
        expect(cookLineNotCounted(text), isFalse, reason: text);
      }
    });
  });
}
