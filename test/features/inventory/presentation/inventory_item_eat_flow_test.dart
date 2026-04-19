import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/application/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/'
    'inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_item_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../calories/support/fake_calories_repositories.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _FakeInventoryItemRepository implements InventoryItemRepository {
  _FakeInventoryItemRepository({required List<InventoryItem> initialItems})
    : _items = List<InventoryItem>.from(initialItems);

  final StreamController<List<InventoryItem>> _controller =
      StreamController<List<InventoryItem>>.broadcast();
  List<InventoryItem> _items;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    return true;
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    return List<InventoryItem>.from(_items);
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async {
    _items = List<InventoryItem>.from(items);
    _controller.add(List<InventoryItem>.from(_items));
    return true;
  }

  @override
  Stream<List<InventoryItem>> watchAll() {
    return Stream<List<InventoryItem>>.multi((controller) {
      controller.add(List<InventoryItem>.from(_items));
      final subscription = _controller.stream.listen(controller.add);
      controller.onCancel = () {
        unawaited(subscription.cancel());
      };
    });
  }

  Future<void> dispose() {
    return _controller.close();
  }
}

class _RecordingCommitStore implements InventoryCalorieEntryCommitStore {
  PendingInventoryConsumption? pendingConsumption;
  CalorieEntry? entry;

  @override
  Future<InventoryCalorieEntryCommitResult?> commitEntryAndInventory({
    required CalorieEntry entry,
    required PendingInventoryConsumption pendingConsumption,
  }) async {
    this.entry = entry;
    this.pendingConsumption = pendingConsumption;
    return const InventoryCalorieEntryCommitResult(
      itemId: 'item-1',
      quantity: 1,
      currentAmount: 500,
    );
  }
}

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

@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
])
class _CompleteEatFlowButton extends ConsumerWidget {
  const _CompleteEatFlowButton({
    required this.item,
    required this.request,
    this.pendingConsumptionId = 'pending-1',
  });

  final InventoryItem item;
  final InventoryItemEatRequest request;
  final String pendingConsumptionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        await InventoryItemEatFlow.complete(
          context: context,
          ref: ref,
          itemBeforeMutation: item,
          request: request,
          pendingConsumptionId: pendingConsumptionId,
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

Widget routerAppWithContainer({
  required ProviderContainer container,
  required GoRouter router,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

@Dependencies([InventoryItemsController])
ProviderSubscription<AsyncValue<List<InventoryItem>>> _keepInventoryAlive(
  ProviderContainer container,
) {
  return container.listen(inventoryItemsControllerProvider, (_, _) {});
}

ProviderSubscription<AsyncValue<List<CalorieEntry>>> _keepCaloriesAlive(
  ProviderContainer container,
) {
  return container.listen(calorieEntriesControllerProvider, (_, _) {});
}

@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
])
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

  testWidgets(
    'complete direct-saves successfully without navigating to the editor',
    (tester) async {
      final item = _amountItemWithNutrition();
      final repository = _FakeInventoryItemRepository(
        initialItems: <InventoryItem>[item],
      );
      final calorieLogRepository = FakeCalorieLogRepository();
      final commitStore = _RecordingCommitStore();
      final auth = _MockFirebaseAuth();
      final user = _MockUser();
      CalorieEntryCreateArgs? openedArgs;
      addTearDown(repository.dispose);
      addTearDown(calorieLogRepository.dispose);

      when(() => user.uid).thenReturn('user-1');
      when(() => auth.currentUser).thenReturn(user);

      final container = ProviderContainer(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(repository),
          inventoryCalorieEntryCommitStoreProvider.overrideWithValue(
            commitStore,
          ),
          calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
          firebaseAuthProvider.overrideWithValue(auth),
        ],
      );
      addTearDown(container.dispose);
      final inventorySubscription = _keepInventoryAlive(container);
      final caloriesSubscription = _keepCaloriesAlive(container);
      addTearDown(inventorySubscription.close);
      addTearDown(caloriesSubscription.close);

      await container.read(inventoryItemsControllerProvider.future);
      final pendingConsumption = await container
          .read(inventoryItemsControllerProvider.notifier)
          .stagePendingConsumption(item.id, 250);
      expect(pendingConsumption, isNotNull);
      final resolvedPendingConsumption = pendingConsumption!;
      final loggedAt = DateTime.now();

      final router = GoRouter(
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.root,
            builder: (context, state) {
              return Scaffold(
                body: _CompleteEatFlowButton(
                  item: item,
                  request: InventoryItemEatRequest(
                    inventoryAmount: 250,
                    loggedAt: loggedAt,
                    mealType: MealType.lunch,
                  ),
                  pendingConsumptionId: resolvedPendingConsumption.id,
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

      await tester.pumpWidget(
        routerAppWithContainer(container: container, router: router),
      );

      await tester.tap(find.text('eat'));
      await tester.pumpAndSettle();

      expect(find.text('editor'), findsNothing);
      expect(openedArgs, isNull);
      expect(commitStore.pendingConsumption?.id, resolvedPendingConsumption.id);
      expect(commitStore.pendingConsumption?.amount, 250);
      expect(commitStore.entry?.mealType, MealType.lunch);
      expect(commitStore.entry?.consumedAmount, 250);
      expect(
        container
            .read(inventoryItemsControllerProvider.notifier)
            .hasPendingConsumption(resolvedPendingConsumption.id),
        isFalse,
      );
      expect(
        container
            .read(inventoryItemsControllerProvider)
            .value
            ?.single
            .currentAmount,
        500,
      );
      expect(
        container.read(calorieEntriesControllerProvider).value?.single.name,
        item.name,
      );
      expect(
        find.text('${item.name} gegessen.'),
        findsOneWidget,
      );
    },
  );
}
