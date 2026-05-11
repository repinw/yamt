import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_instruction_matcher.dart';

void main() {
  test('matches ingredient mentions with word boundaries', () {
    final matches = findCookflowIngredientMentionMatches(
      instruction: 'Zwiebel hacken, dann zwiebel glasig braten.',
      ingredientName: 'Zwiebel',
    ).toList();

    expect(matches, hasLength(2));
    expect(matches.map((match) => match.group(0)), <String>[
      'Zwiebel',
      'zwiebel',
    ]);
  });

  test('does not match inside larger words or numbers', () {
    final matches = findCookflowIngredientMentionMatches(
      instruction: 'Zwiebelpulver und 2Zwiebelwerte sind keine Zwiebel.',
      ingredientName: 'Zwiebel',
    ).toList();

    expect(matches, hasLength(1));
    expect(matches.single.group(0), 'Zwiebel');
  });

  test('trims ingredient names and ignores empty input', () {
    expect(
      findCookflowIngredientMentionMatches(
        instruction: 'Apfel schneiden.',
        ingredientName: ' Apfel ',
      ).single.group(0),
      'Apfel',
    );
    expect(
      findCookflowIngredientMentionMatches(
        instruction: '',
        ingredientName: 'Apfel',
      ),
      isEmpty,
    );
    expect(
      findCookflowIngredientMentionMatches(
        instruction: 'Apfel schneiden.',
        ingredientName: ' ',
      ),
      isEmpty,
    );
  });
}
