import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_item_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _RecordingInventoryItemsController extends InventoryItemsController {
  _RecordingInventoryItemsController({List<InventoryItem>? initialItems})
    : _initialItems = initialItems ?? const <InventoryItem>[];

  final List<InventoryItem> _initialItems;
  final List<String> discardedPendingIds = <String>[];

  @override
  Future<List<InventoryItem>> build() async => _initialItems;

  @override
  Future<bool> discardPendingConsumption(String draftId) async {
    discardedPendingIds.add(draftId);
    return true;
  }
}

class _CompleteEatFlowButton extends ConsumerWidget {
  const _CompleteEatFlowButton({required this.item, required this.request});

  final InventoryItem item;
  final InventoryItemEatRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        await InventoryItemEatFlow.complete(
          context: context,
          ref: ref,
          itemBeforeMutation: item,
          request: request,
          pendingConsumptionId: 'pending-1',
        );
      },
      child: const Text('eat'),
    );
  }
}

InventoryItem _amountItemWithNutrition() {
  return InventoryItem.create(
    id: 'item-1',
    globalFoodItemId: 'off-4061458029995',
    name: 'Waffelhörnchen Haselnuss-Vanille',
    brand: 'Mucci',
    barcode: '4061458029995',
    imageUrl: 'https://example.com/waffel.png',
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 215,
      per100Protein: 4.2,
      per100Carbs: 24.8,
      per100Fat: 9.6,
    ),
    entryDate: DateTime.parse('2026-03-01T12:00:00Z'),
    storeName: 'Aldi',
    quantity: 1,
    initialAmount: 1000,
    currentAmount: 750,
    amountUnit: InventoryAmountUnit.gram,
  );
}

InventoryItem _portionItemWithNutrition() {
  return InventoryItem.create(
    id: 'item-portion',
    name: 'Milk',
    brand: 'Brand',
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 42,
      per100Protein: 3.4,
      per100Carbs: 4.9,
      per100Fat: 1.5,
    ),
    entryDate: DateTime.parse('2026-03-01T12:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialQuantity: 1,
  );
}

InventoryItem _itemWithoutNutrition() {
  return InventoryItem.create(
    id: 'item-1',
    name: 'Milk',
    brand: 'Brand',
    entryDate: DateTime.parse('2026-03-01T12:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 1000,
    currentAmount: 750,
    amountUnit: InventoryAmountUnit.gram,
  );
}

Widget routerApp({
  required GoRouter router,
  List<Override> overrides = const <Override>[],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  testWidgets(
    'complete opens calorie editor with loggedAt and mealType prefilled',
    (tester) async {
      CalorieEntryCreateArgs? openedArgs;
      final loggedAt = DateTime.parse('2026-04-06T18:45:00Z');
      final router = GoRouter(
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.root,
            builder: (context, state) {
              return Scaffold(
                body: _CompleteEatFlowButton(
                  item: _portionItemWithNutrition(),
                  request: InventoryItemEatRequest(
                    inventoryAmount: 1,
                    loggedAt: loggedAt,
                    mealType: MealType.dinner,
                    calorieAmount: 2.5,
                    calorieUnit: ConsumedUnit.grams,
                  ),
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.homeCaloriesEntryCreate,
            builder: (context, state) {
              openedArgs = state.extra as CalorieEntryCreateArgs?;
              return const Scaffold(body: Text('editor'));
            },
          ),
        ],
      );

      await tester.pumpWidget(routerApp(router: router));

      await tester.tap(find.text('eat'));
      await tester.pumpAndSettle();

      expect(openedArgs, isNotNull);
      expect(openedArgs?.preselectedMealType, MealType.dinner);
      expect(openedArgs?.preselectedLoggedAt, loggedAt);
      expect(openedArgs?.inventoryContext?.consumedAmount, 2.5);
      expect(openedArgs?.inventoryContext?.consumedUnit, ConsumedUnit.grams);
    },
  );

  testWidgets(
    'complete discards pending consumption and shows feedback without '
    'nutrition',
    (tester) async {
      final inventoryController = _RecordingInventoryItemsController();
      final router = GoRouter(
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.root,
            builder: (context, state) {
              return Scaffold(
                body: _CompleteEatFlowButton(
                  item: _itemWithoutNutrition(),
                  request: InventoryItemEatRequest(
                    inventoryAmount: 250,
                    loggedAt: DateTime.parse('2026-04-06T12:30:00Z'),
                    mealType: MealType.lunch,
                  ),
                ),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        routerApp(
          router: router,
          overrides: [
            inventoryItemsControllerProvider.overrideWith(
              () => inventoryController,
            ),
          ],
        ),
      );

      await tester.tap(find.text('eat'));
      await tester.pumpAndSettle();

      expect(inventoryController.discardedPendingIds, <String>['pending-1']);
      expect(
        find.text('Aktion fehlgeschlagen. Bitte erneut versuchen.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'complete discards pending consumption and shows save error when direct '
    'save fails',
    (tester) async {
      final inventoryController = _RecordingInventoryItemsController();
      final auth = _MockFirebaseAuth();
      final router = GoRouter(
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.root,
            builder: (context, state) {
              return Scaffold(
                body: _CompleteEatFlowButton(
                  item: _amountItemWithNutrition(),
                  request: InventoryItemEatRequest(
                    inventoryAmount: 250,
                    loggedAt: DateTime.parse('2026-04-06T12:30:00Z'),
                    mealType: MealType.lunch,
                  ),
                ),
              );
            },
          ),
        ],
      );
      when(() => auth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        routerApp(
          router: router,
          overrides: [
            firebaseAuthProvider.overrideWithValue(auth),
            inventoryItemsControllerProvider.overrideWith(
              () => inventoryController,
            ),
          ],
        ),
      );

      await tester.tap(find.text('eat'));
      await tester.pumpAndSettle();

      expect(inventoryController.discardedPendingIds, <String>['pending-1']);
      expect(
        find.text('Eintrag konnte nicht gespeichert werden.'),
        findsOneWidget,
      );
    },
  );
}
