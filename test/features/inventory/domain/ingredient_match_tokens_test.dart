import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/ingredient_match_tokens.dart';

bool _names(String sentence, String ingredient) =>
    ingredientFoodWords(ingredient).any(ingredientFoodWords(sentence).contains);

void main() {
  test('food words leave out the amount, units, and filler words', () {
    expect(ingredientFoodWords('2 Scheiben Toast'), {'toast'});
    expect(ingredientFoodWords('500 g Möhren'), {'karotte'});
    expect(ingredientFoodWords('4 Eier'), {'ei'});
    expect(ingredientFoodWords('1 Becher Schmand (200 g)'), {'schmand'});
  });

  test('a sentence names an ingredient in its singular or alias form', () {
    expect(_names('Tomate halbieren.', '400 g Tomaten'), isTrue);
    expect(_names('Die Möhren schälen.', '200 g Karotten'), isTrue);
    expect(_names('Das Ei unterheben.', '4 Eier'), isTrue);
    expect(_names('Öl erhitzen.', '2 EL Öl'), isTrue);
    expect(_names('Chop the onions.', '2 onions'), isTrue);
  });

  test('similar words of other foods or of the sentence do not count', () {
    for (final (sentence, ingredient) in [
      ('Eine Pfanne erhitzen.', '1 Ei'),
      ('Dabei rühren.', '1 Ei'),
      ('Knoblauch hacken.', '1 Stange Lauch'),
      ('Tomaten in Scheiben schneiden.', '2 Scheiben Toast'),
      ('Zwiebeln schälen und würfeln.', 'Salz und Pfeffer'),
      ('In einer Pfanne Öl erhitzen.', 'Saft einer Zitrone'),
      ('Die rote Paprika würfeln.', '1 rote Zwiebel'),
      ('Kartoffeln oder Nudeln kochen.', 'Butter oder Margarine'),
      ('Nach 10 Minuten wenden.', 'Salz nach Geschmack'),
      ('Den Ofen auf 200 Grad vorheizen.', '1 Becher Schmand (200 g)'),
      ('Chop the onions and garlic.', 'Salt and pepper'),
      ('Add 2 tbsp of the sauce.', '1 tbsp oil'),
      ('Add the ground beef.', 'Freshly ground black pepper'),
    ]) {
      expect(_names(sentence, ingredient), isFalse, reason: sentence);
    }
  });
}
