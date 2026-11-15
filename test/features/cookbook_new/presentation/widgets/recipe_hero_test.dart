import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_planned_nutrition.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_estimate_line.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_hero.dart';
import 'package:yamt/features/inventory/domain/recipe_estimate.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_cover.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../support/prepared_meal_test_data.dart';

void main() {
  testWidgets('a long name in large text grows the photo below the back '
      'and remove buttons', (tester) async {
    final recipe = preparedMealTestData(id: 'stew').copyWith(
      name: 'Low Carb Bauerntopf mit Hackfleisch, Karotten und Paprika',
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              textScaler: TextScaler.linear(2.5),
            ),
            child: Scaffold(
              body: ListView(
                children: [RecipeHero(recipe: recipe, onRemove: () {})],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final back = tester.getRect(
      find.ancestor(
        of: find.byType(BackButtonIcon),
        matching: find.byType(IconButton),
      ),
    );
    final remove = tester.getRect(find.byKey(RecipeHero.removeKey));
    final name = tester.getRect(find.text(recipe.name));
    expect(name.top, greaterThanOrEqualTo(back.bottom));
    expect(name.top, greaterThanOrEqualTo(remove.bottom));
    expect(
      tester.getSize(find.byType(RecipeHero)).height,
      greaterThan(AppGraphit.recipeHeroHeight),
    );
  });

  testWidgets('shows the estimate under the name, and none without one', (
    tester,
  ) async {
    final recipe = preparedMealTestData(id: 'stew').copyWith(name: 'Stew');
    final estimate = RecipeEstimate(
      kcal: 400,
      protein: 20,
      carbs: 40,
      fat: 10,
      portions: 2,
      linesKey: '',
      createdAt: DateTime.utc(2026, 11, 7),
    );
    Future<void> pump(RecipeEstimate? estimate) => tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              children: [
                RecipeHero(
                  recipe: recipe,
                  onRemove: () {},
                  portion: estimate == null
                      ? null
                      : (values: estimateValues(estimate), estimated: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await pump(null);
    expect(find.byKey(RecipeEstimateLine.lineKey), findsNothing);

    await pump(estimate);
    expect(tester.takeException(), isNull);
    final line = find.byKey(RecipeEstimateLine.lineKey);
    expect(line, findsOneWidget);
    expect(
      find.descendant(of: find.byType(RecipeHero), matching: line),
      findsOneWidget,
    );
    expect(
      tester.getRect(line).top,
      greaterThanOrEqualTo(tester.getRect(find.text('Stew')).bottom),
    );
  });

  testWidgets('without a photo the hero shows no initial under the name, on '
      'a dark background in the light theme too', (tester) async {
    final recipe = preparedMealTestData(id: 'pan').copyWith(
      name: 'Buchweizen-Pfanne',
      imageUrl: null,
      imageAssetId: null,
      components: const [],
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              children: [RecipeHero(recipe: recipe, onRemove: () {})],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Buchweizen-Pfanne'), findsOneWidget);
    expect(find.text('B'), findsNothing);
    final background = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(PreparedMealCover),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = background.decoration as BoxDecoration;
    expect(decoration.color, FoodLabelColors.dark.card);
    expect(decoration.gradient, isNull);
  });
}
