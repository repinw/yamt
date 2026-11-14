import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion_queue.dart';

const _milk = ShoppingSuggestion(name: 'Milk');
const _oats = ShoppingSuggestion(name: 'Oats', brand: 'Mill');
const _butter = ShoppingSuggestion(name: 'Butter');

List<String> _names(List<ShoppingSuggestion> suggestions) => [
  for (final suggestion in suggestions) suggestion.name,
];

void main() {
  test('the key ignores case and spaces and tells brands apart', () {
    expect(
      shoppingSuggestionKey(
        const ShoppingSuggestion(name: ' OATS ', brand: ' mill'),
      ),
      shoppingSuggestionKey(_oats),
    );
    expect(
      shoppingSuggestionKey(const ShoppingSuggestion(name: 'Oats')),
      isNot(shoppingSuggestionKey(_oats)),
    );
  });

  test('without anything pushed back the order stays', () {
    expect(
      _names(queueShoppingSuggestions([_milk, _oats, _butter], const [])),
      ['Milk', 'Oats', 'Butter'],
    );
  });

  test('pushed back suggestions follow the others, longest ago first', () {
    final queue = queueShoppingSuggestions(
      [_milk, _oats, _butter],
      [shoppingSuggestionKey(_oats), shoppingSuggestionKey(_milk)],
    );

    expect(_names(queue), ['Butter', 'Oats', 'Milk']);
  });

  test('when every suggestion was pushed back the first one is up again', () {
    var pushedBack = const <String>[];
    for (final suggestion in [_milk, _oats, _butter]) {
      pushedBack = pushShoppingSuggestionBack(
        pushedBack,
        suggestion,
        current: [_milk, _oats, _butter],
      );
    }

    expect(
      _names(queueShoppingSuggestions([_milk, _oats, _butter], pushedBack)),
      ['Milk', 'Oats', 'Butter'],
    );
  });

  test('pushing back again moves the suggestion to the very end', () {
    final pushedBack = pushShoppingSuggestionBack(
      [shoppingSuggestionKey(_milk), shoppingSuggestionKey(_oats)],
      _milk,
      current: [_milk, _oats],
    );

    expect(pushedBack, [
      shoppingSuggestionKey(_oats),
      shoppingSuggestionKey(_milk),
    ]);
  });

  test('pushing back forgets products that are no longer suggested', () {
    final pushedBack = pushShoppingSuggestionBack(
      [shoppingSuggestionKey(_butter), shoppingSuggestionKey(_oats)],
      _milk,
      current: [_milk, _oats],
    );

    expect(pushedBack, [
      shoppingSuggestionKey(_oats),
      shoppingSuggestionKey(_milk),
    ]);
  });

  test('a pushed back product that is still suggested keeps its turn', () {
    // Milk is on the list right now, so the strip hides it, but the Vorrat
    // still suggests it: its turn must survive the next push.
    final pushedBack = pushShoppingSuggestionBack(
      [shoppingSuggestionKey(_milk)],
      _oats,
      current: [_milk, _oats, _butter],
    );

    expect(pushedBack, [
      shoppingSuggestionKey(_milk),
      shoppingSuggestionKey(_oats),
    ]);
  });
}
