import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/domain/food_word_match.dart';
import 'package:yamt/features/inventory/domain/ingredient_match_tokens.dart';

List<String> _named(String step, List<String> ingredients) =>
    foodsNamedBy(ingredientFoodWords(step), [
      for (final label in ingredients)
        (label: label, words: ingredientFoodWords(label)),
    ]);

void main() {
  test('a part of a food or a plural names the food', () {
    expect(_named('Die Knoblauchzehen hacken.', ['2 Knoblauch']), [
      '2 Knoblauch',
    ]);
    expect(_named('Den Knoblauch hacken.', ['2 Knoblauchzehen']), [
      '2 Knoblauchzehen',
    ]);
    expect(_named('Add the tomatoes.', ['2 tomato', 'tomato paste']), [
      '2 tomato',
      'tomato paste',
    ]);
    expect(_named('Beat the egg.', ['2 eggs']), ['2 eggs']);
  });

  test('the closest form wins', () {
    const ingredients = [
      '1 Tomate',
      '1 EL Tomatenmark',
      '200 ml Milch',
      '400 ml Kokosmilch',
    ];
    expect(_named('Tomatenmark anrösten.', ingredients), ['1 EL Tomatenmark']);
    expect(_named('Die Tomaten würfeln.', ingredients), ['1 Tomate']);
    expect(_named('Kokosmilch einrühren.', ingredients), ['400 ml Kokosmilch']);
  });

  test('another food that starts or ends with a food does not', () {
    expect(_named('Tomaten würfeln.', ['1 EL Tomatenmark']), isEmpty);
    expect(_named('Beat until creamy.', ['200 ml cream']), isEmpty);
    expect(_named('Frühlingszwiebeln schneiden.', ['1 Zwiebel']), isEmpty);
    expect(_named('Preiselbeeren dazugeben.', ['200 g Reis']), isEmpty);
    expect(_named('Das Ei aufschlagen.', ['1 Eis']), isEmpty);
  });
}
