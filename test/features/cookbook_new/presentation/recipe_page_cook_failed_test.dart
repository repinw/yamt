import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_page.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_cooking_service.dart';
import 'package:yamt/features/inventory/application/prepared_meal_from_vorlage.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/fake_cook_run_repository.dart';
import '../../../helpers/fake_inventory_item_repository.dart';
import '../../../helpers/fake_prepared_meal_template_repository.dart';
import '../../../helpers/fake_signed_in_user.dart';
import '../../../support/prepared_meal_test_data.dart';
import '../../shoppinglist/support/fake_shopping_list_repository.dart';

const _cookbookKey = ValueKey<String>('cookbook-page');

/// Answers `cookVorlage` when [answer] completes: `null` is a failed save.
class _SlowCooking implements PreparedMealCookingService {
  final answer = Completer<String?>();

  @override
  Future<PreparedMealCreationResult> cookVorlage({
    required PreparedMeal vorlage,
    required int portions,
    required List<VorlageFood> foods,
  }) async {
    final mealId = await answer.future;
    return mealId == null
        ? const PreparedMealCreationResult.failure(
            PreparedMealCreationFailureReason.mealSaveFailed,
          )
        : PreparedMealCreationResult.success(mealId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

InventoryItem _item() => InventoryItem.create(
  id: 'mince',
  name: 'Hackfleisch',
  entryDate: DateTime.utc(2026, 10, 9),
  storeName: 'Store',
  quantity: 1,
  initialAmount: 2000,
  currentAmount: 2000,
  amountUnit: InventoryAmountUnit.gram,
);

// A Vorlage: a pot of one food and no recipe lines.
PreparedMeal _vorlage() => preparedMealTestData(id: 'stew').copyWith(
  name: 'Bauerntopf',
  totalPortions: 2,
  recipeIngredients: const <String>[],
  components: [
    PreparedMealComponent(
      inventoryItemId: 'mince',
      name: 'Hackfleisch',
      brand: null,
      imageUrl: null,
      usedAmount: 500,
      usedUnit: InventoryAmountUnit.gram,
      totalKcal: 0,
      totalProtein: 0,
      totalCarbs: 0,
      totalFat: 0,
      sourceItemSnapshot: _item(),
    ),
  ],
);

void main() {
  testWidgets('a failed cook says so also after the recipe page was popped', (
    tester,
  ) async {
    final shopping = FakeShoppingListRepository();
    addTearDown(shopping.dispose);
    final cooking = _SlowCooking();
    final router = GoRouter(
      initialLocation: AppRoutes.homeInventoryTemplates,
      routes: [
        GoRoute(
          path: AppRoutes.homeInventoryTemplates,
          builder: (context, state) => const Scaffold(key: _cookbookKey),
        ),
        GoRoute(
          path: AppRoutes.homeRecipe,
          builder: (context, state) =>
              RecipePage(recipeId: state.pathParameters['recipeId']!),
        ),
      ],
    );
    addTearDown(router.dispose);
    final container = ProviderContainer(
      overrides: [
        preparedMealTemplateRepositoryProvider.overrideWithValue(
          FakePreparedMealTemplateRepository(templates: [_vorlage()]),
        ),
        authStateChangesProvider.overrideWith(
          (ref) => Stream.value(FakeSignedInUser('uid-1')),
        ),
        cookRunRepositoryProvider.overrideWithValue(FakeCookRunRepository()),
        inventoryItemRepositoryProvider.overrideWithValue(
          FakeInventoryItemRepository([_item()]),
        ),
        shoppingListRepositoryProvider.overrideWithValue(shopping),
        preparedMealCookingServiceProvider.overrideWithValue(cooking),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(router.push<void>(AppRoutes.homeRecipePath('stew')));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byKey(RecipePage.cookKey)),
    )!;

    await tester.tap(find.byKey(RecipePage.cookKey));
    await tester.pump();
    // The cook closes the page while the save is still on its way.
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(RecipePage.cookKey), findsNothing);
    expect(find.text(l10n.cookingSaveFailed), findsNothing);

    cooking.answer.complete(null);
    await tester.pumpAndSettle();

    expect(find.byKey(_cookbookKey), findsOneWidget);
    expect(find.text(l10n.cookingSaveFailed), findsOneWidget);
  });
}
