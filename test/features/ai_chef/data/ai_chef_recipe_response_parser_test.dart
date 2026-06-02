import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_recipe_response_parser.dart';

void main() {
  const parser = AiChefRecipeResponseParser();

  test('parse reads complete recipe json', () {
    final draft = parser.parse('''
{
  "name": "Tomato Pasta",
  "portions": 3,
  "kcal": 720,
  "protein": 31.5,
  "carbs": 92,
  "fat": 21,
  "ingredients": ["Tomato", "Pasta"],
  "instructions": ["Cook pasta", "Add sauce"],
  "image_prompt": "tomato pasta on a plate"
}
''');

    expect(draft, isNotNull);
    expect(draft?.name, 'Tomato Pasta');
    expect(draft?.portions, 3);
    expect(draft?.kcal, 720);
    expect(draft?.protein, 31.5);
    expect(draft?.carbs, 92);
    expect(draft?.fat, 21);
    expect(draft?.ingredients, <String>['Tomato', 'Pasta']);
    expect(draft?.instructions, <String>['Cook pasta', 'Add sauce']);
    expect(draft?.imagePrompt, 'tomato pasta on a plate');
  });

  test('parse accepts fenced json responses', () {
    final draft = parser.parse('''
```json
{
  "ingredients": ["Rice"],
  "instructions": ["Boil rice"]
}
```
''');

    expect(draft, isNotNull);
    expect(draft?.name, 'AI Recipe');
    expect(draft?.portions, 2);
    expect(draft?.kcal, 0);
    expect(draft?.ingredients, <String>['Rice']);
    expect(draft?.instructions, <String>['Boil rice']);
  });

  test('parse extracts json from surrounding model text', () {
    final draft = parser.parse('''
Here is the recipe:

```json
{
  "ingredients": ["Tomato"],
  "instructions": ["Slice tomato"]
}
```

Enjoy!
''');

    expect(draft?.ingredients, <String>['Tomato']);
    expect(draft?.instructions, <String>['Slice tomato']);
  });

  test('parse stringifies ingredient and instruction values', () {
    final draft = parser.parse('''
{
  "ingredients": ["Salt", 2],
  "instructions": ["Season", true]
}
''');

    expect(draft?.ingredients, <String>['Salt', '2']);
    expect(draft?.instructions, <String>['Season', 'true']);
  });

  test('parse returns null for malformed or incomplete responses', () {
    expect(parser.parse('not json'), isNull);
    expect(parser.parse('[]'), isNull);
    expect(
      parser.parse('{"ingredients": [], "instructions": ["Cook"]}'),
      isNull,
    );
    expect(
      parser.parse('{"ingredients": ["Rice"], "instructions": []}'),
      isNull,
    );
  });
}
