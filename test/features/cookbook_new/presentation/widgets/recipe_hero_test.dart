import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_hero.dart';

import '../../../../support/prepared_meal_test_data.dart';

void main() {
  testWidgets('a long name in large text grows the photo below the back '
      'button', (tester) async {
    final recipe = preparedMealTestData(id: 'stew').copyWith(
      name: 'Low Carb Bauerntopf mit Hackfleisch, Karotten und Paprika',
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              textScaler: TextScaler.linear(2.5),
            ),
            child: Scaffold(
              body: ListView(children: [RecipeHero(recipe: recipe)]),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final back = tester.getRect(find.byType(IconButton));
    final name = tester.getRect(find.text(recipe.name));
    expect(name.top, greaterThanOrEqualTo(back.bottom));
    expect(
      tester.getSize(find.byType(RecipeHero)).height,
      greaterThan(AppGraphit.recipeHeroHeight),
    );
  });
}
