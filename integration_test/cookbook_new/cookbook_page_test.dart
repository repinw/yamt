import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'cookbook_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/cookbook_page.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_open_meal_card.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_template_strip.dart';
import 'package:yamt/features/home/home_page.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/support/prepared_meal_test_data.dart';

GoRoute _placeholder(String path, String label) {
  return GoRoute(
    path: path,
    builder: (context, state) => Scaffold(
      key: ValueKey<String>(path),
      body: Center(child: Text(label)),
    ),
  );
}

Widget _app({
  required List<PreparedMeal> templates,
  required List<PreparedMeal> meals,
}) {
  final router = GoRouter(
    initialLocation: AppRoutes.homeInventoryTemplates,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomePage(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [_placeholder(AppRoutes.homeInventory, 'Vorrat page')],
          ),
          StatefulShellBranch(
            routes: [_placeholder(AppRoutes.homeDiary, 'Diary page')],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homeInventoryTemplates,
                builder: (context, state) => const CookbookPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [_placeholder(AppRoutes.homeProgress, 'Progress page')],
          ),
        ],
      ),
      _placeholder(AppRoutes.homeInventoryTemplateDetail, 'Recipe page'),
      _placeholder(AppRoutes.homeCookedMeal, 'Cooked page'),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => DateTime(2026, 10, 2, 20)),
      cookbookTemplatesProvider.overrideWith((ref) => Stream.value(templates)),
      inventoryQuickEatMealsProvider.overrideWith((ref) => Stream.value(meals)),
      inventoryQuickEatItemsProvider.overrideWith(
        (ref) => Stream.value([
          InventoryItem.create(
            id: 'pasta',
            name: 'Pasta',
            entryDate: DateTime.utc(2026, 9, 29),
            storeName: 'Store',
            quantity: 1,
            initialAmount: 500,
            currentAmount: 500,
            amountUnit: InventoryAmountUnit.gram,
          ),
        ]),
      ),
    ],
  );
  addTearDown(container.dispose);

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final recipe = preparedMealTestData(
    id: 'pasta',
    name: 'One-pan pasta',
  ).copyWith(recipeIngredients: const ['200 g Pasta', '150 g Tomato sauce']);
  final template = preparedMealTestData(id: 'bowl');
  final openMeal = preparedMealTestData(
    id: 'free',
    name: 'Chicken with rice',
  ).copyWith(pendingRecipeIngredients: const ['40 g Butter', '200 g Rice']);

  testWidgets('shows pot, templates, recipes and opens a recipe', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(templates: [recipe, template], meals: [openMeal]),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 RECIPE'), findsOneWidget);
    expect(find.text('OPEN'), findsOneWidget);
    expect(find.text('Chicken with rice'), findsOneWidget);
    expect(find.text('In stock · 2 rows open'), findsOneWidget);
    expect(find.text('Rice bowl'), findsOneWidget);
    expect(find.text('One-pan pasta'), findsOneWidget);
    // The pasta recipe lacks tomato sauce; the rice bowl lacks rice.
    expect(find.text('1 missing'), findsNWidgets(2));

    // Center the card, so the dock does not cover it.
    await Scrollable.ensureVisible(
      tester.element(find.text('One-pan pasta')),
      alignment: 0.3,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('One-pan pasta'));
    await tester.pumpAndSettle();

    expect(find.text('Recipe page'), findsOneWidget);
  });

  testWidgets('sends a new template to the Vorrat', (tester) async {
    await tester.pumpWidget(_app(templates: const [], meals: [openMeal]));
    await tester.pumpAndSettle();

    expect(
      find.text('No recipes yet. Add one from a link or get an AI idea.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(CookbookTemplateStrip.createKey));
    await tester.pumpAndSettle();

    expect(find.text('Vorrat page'), findsOneWidget);
  });

  testWidgets('continues a meal in the pot on the cooked page', (tester) async {
    final potMeal = preparedMealTestData(
      id: 'pot',
      name: 'Lentil soup',
    ).copyWith(inPot: true);
    await tester.pumpWidget(_app(templates: const [], meals: [potMeal]));
    await tester.pumpAndSettle();

    // Without open rows the meal is in the pot until it is marked cooked.
    expect(find.byType(CookbookOpenMealCard), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(CookbookOpenMealCard),
        matching: find.byType(FilledButton),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>(AppRoutes.homeCookedMeal)),
      findsOneWidget,
    );
  });
}
