import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/calorie_entry_editor_page.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_pending_consumption_store.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_item_eat_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../calories/support/fake_calories_repositories.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth;

class _MockUser extends Mock implements User;

User _signedInUser() {
  final user = _MockUser();
  when(() => user.uid).thenReturn('user-1');
  return user;
}

class _FakeInventoryItemRepository implements InventoryItemRepository {
  new({required List<InventoryItem> initialItems})
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
  Future<List<InventoryCalorieEntryCommitResult>?>
  commitEntryAndInventoryItems({
    required CalorieEntry entry,
    required List<PendingInventoryConsumption> pendingConsumptions,
  }) async {
    this.entry = entry;
    pendingConsumption = pendingConsumptions.single;
    return [
      InventoryCalorieEntryCommitResult(
        itemId: pendingConsumptions.single.itemId,
        quantity: 1,
        currentAmount: 500,
      ),
    ];
  }

  @override
  Future<List<InventoryCalorieEntryCommitResult>?> saveEntryAndRestoreItems({
    required CalorieEntry entry,
    required Map<String, int> amountsByItemId,
  }) async => null;

  @override
  Future<List<InventoryCalorieEntryCommitResult>?> deleteEntryAndRestoreItems({
    required CalorieEntry entry,
    required Map<String, int> amountsByItemId,
  }) => throw UnimplementedError();
}

/// Fakes the repositories the eat service writes to, signed in as [user].
List<Override> _eatServiceOverrides({
  User? user,
  _RecordingCommitStore? commitStore,
}) {
  final auth = _MockFirebaseAuth();
  when(() => auth.currentUser).thenReturn(user);
  final calorieLogRepository = FakeCalorieLogRepository();
  addTearDown(calorieLogRepository.dispose);
  return [
    firebaseAuthProvider.overrideWithValue(auth),
    calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
    inventoryCalorieEntryCommitStoreProvider.overrideWithValue(
      commitStore ?? _RecordingCommitStore(),
    ),
  ];
}

/// The real store and what was reserved in it before the eat.
typedef _Staged = ({
  InventoryPendingConsumptionStore store,
  PendingInventoryConsumption pending,
});

class _CompleteEatFlowButton extends ConsumerWidget {
  const new({
    required this.item,
    required this.request,
    this.pending,
    this.onStaged,
  });

  final InventoryItem item;
  final InventoryItemEatRequest request;

  /// Reserved by the caller; without it the button reserves the stock.
  final PendingInventoryConsumption? pending;
  final ValueChanged<_Staged>? onStaged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        final container = ProviderScope.containerOf(context, listen: false);
        final store = container.read(inventoryPendingConsumptionStoreProvider);
        final staged = pending ?? store.stage(item, request.inventoryAmount)!;
        onStaged?.call((store: store, pending: staged));
        await InventoryItemEatFlow.complete(
          context: context,
          container: container,
          item: item,
          request: request,
          pending: staged,
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
      localizationsDelegates: appLocalizationsDelegates,
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
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

ProviderSubscription<AsyncValue<List<InventoryItem>>> _keepInventoryAlive(
  ProviderContainer container,
) {
  return container.listen(inventoryItemsControllerProvider, (_, _) {});
}

class _DirectSaveFlowHarness {
  new _({
    required this.item,
    required this.container,
    required this.commitStore,
    required this.pendingConsumption,
  });

  final InventoryItem item;
  final ProviderContainer container;
  final _RecordingCommitStore commitStore;
  final PendingInventoryConsumption pendingConsumption;

  static Future<_DirectSaveFlowHarness> pump({
    required WidgetTester tester,
    required InventoryItem item,
    required InventoryItemEatRequest request,
  }) async {
    final repository = _FakeInventoryItemRepository(
      initialItems: <InventoryItem>[item],
    );
    final calorieLogRepository = FakeCalorieLogRepository();
    final commitStore = _RecordingCommitStore();
    final auth = _MockFirebaseAuth();
    final user = _MockUser();
    addTearDown(repository.dispose);
    addTearDown(calorieLogRepository.dispose);

    when(() => user.uid).thenReturn('user-1');
    when(() => auth.currentUser).thenReturn(user);

    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(repository),
        inventoryCalorieEntryCommitStoreProvider.overrideWithValue(commitStore),
        calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
        firebaseAuthProvider.overrideWithValue(auth),
      ],
    );
    addTearDown(container.dispose);
    final inventorySubscription = _keepInventoryAlive(container);
    addTearDown(inventorySubscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    final pendingConsumption = await container
        .read(inventoryItemsControllerProvider.notifier)
        .stagePendingConsumption(item.id, request.inventoryAmount);
    expect(pendingConsumption, isNotNull);

    final harness = _DirectSaveFlowHarness._(
      item: item,
      container: container,
      commitStore: commitStore,
      pendingConsumption: pendingConsumption!,
    );
    final router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.root,
          builder: (context, state) {
            return Scaffold(
              body: _CompleteEatFlowButton(
                item: item,
                request: request,
                pending: harness.pendingConsumption,
              ),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      routerAppWithContainer(container: container, router: router),
    );
    return harness;
  }

  Future<void> complete(WidgetTester tester) async {
    await tester.tap(find.text('eat'));
    await tester.pumpAndSettle();
  }
}

void main() {
  test('shouldAwaitCompletion mirrors direct-save policy', () {
    final loggedAt = DateTime.parse('2026-04-06T12:30:00Z');

    expect(
      InventoryItemEatFlow.shouldAwaitCompletion(
        _amountItemWithNutrition(),
        InventoryItemEatRequest(
          inventoryAmount: 250,
          loggedAt: loggedAt,
          mealType: MealType.lunch,
        ),
      ),
      isTrue,
    );
    expect(
      InventoryItemEatFlow.shouldAwaitCompletion(
        _portionItemWithNutrition(),
        InventoryItemEatRequest(
          inventoryAmount: 1,
          loggedAt: loggedAt,
          mealType: MealType.lunch,
        ),
      ),
      isFalse,
    );
  });

  testWidgets(
    'complete direct-saves piece portions without opening calorie editor',
    (tester) async {
      final item = _portionItemWithNutrition();
      final loggedAt = DateTime.parse('2026-04-06T18:45:00Z');
      final harness = await _DirectSaveFlowHarness.pump(
        tester: tester,
        item: item,
        request: InventoryItemEatRequest(
          inventoryAmount: 1,
          loggedAt: loggedAt,
          mealType: MealType.dinner,
          calorieAmount: 2.5,
          calorieUnit: ConsumedUnit.grams,
          portionBaseAmount: 2.5,
          portionBaseUnit: ConsumedUnit.grams,
          portionCount: 1,
        ),
      );

      await harness.complete(tester);

      expect(find.byType(CalorieEntryEditorPage), findsNothing);
      expect(
        harness.commitStore.pendingConsumption?.id,
        harness.pendingConsumption.id,
      );
      expect(harness.commitStore.pendingConsumption?.amount, 1);
      expect(harness.commitStore.entry?.mealType, MealType.dinner);
      expect(harness.commitStore.entry?.loggedAt, loggedAt);
      expect(harness.commitStore.entry?.consumedAmount, 2.5);
      expect(harness.commitStore.entry?.consumedUnit, ConsumedUnit.grams);
    },
  );

  testWidgets(
    'complete discards pending consumption and shows feedback without '
    'nutrition',
    (tester) async {
      _Staged? staged;
      final router = GoRouter(
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.root,
            builder: (context, state) {
              return Scaffold(
                body: _CompleteEatFlowButton(
                  onStaged: (value) => staged = value,
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
          overrides: _eatServiceOverrides(user: _signedInUser()),
        ),
      );

      await tester.tap(find.text('eat'));
      await tester.pumpAndSettle();

      expect(staged!.store.pendingConsumptionById(staged!.pending.id), isNull);
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
      _Staged? staged;
      final router = GoRouter(
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.root,
            builder: (context, state) {
              return Scaffold(
                body: _CompleteEatFlowButton(
                  onStaged: (value) => staged = value,
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
      await tester.pumpWidget(
        routerApp(router: router, overrides: _eatServiceOverrides()),
      );

      await tester.tap(find.text('eat'));
      await tester.pumpAndSettle();

      expect(staged!.store.pendingConsumptionById(staged!.pending.id), isNull);
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
      final harness = await _DirectSaveFlowHarness.pump(
        tester: tester,
        item: item,
        request: InventoryItemEatRequest(
          inventoryAmount: 250,
          loggedAt: DateTime.parse('2026-04-06T12:30:00Z'),
          mealType: MealType.lunch,
        ),
      );

      await harness.complete(tester);

      expect(find.byType(CalorieEntryEditorPage), findsNothing);
      expect(
        harness.commitStore.pendingConsumption?.id,
        harness.pendingConsumption.id,
      );
      expect(harness.commitStore.pendingConsumption?.amount, 250);
      expect(harness.commitStore.entry?.mealType, MealType.lunch);
      expect(harness.commitStore.entry?.consumedAmount, 250);
      expect(
        harness.container
            .read(inventoryPendingConsumptionStoreProvider)
            .pendingConsumptionById(harness.pendingConsumption.id),
        isNull,
      );
      expect(
        harness.container
            .read(inventoryItemsControllerProvider)
            .value
            ?.single
            .currentAmount,
        500,
      );
      expect(harness.commitStore.entry?.name, item.name);
      expect(find.text('Ins Tagebuch eingetragen'), findsOneWidget);
    },
  );

  testWidgets('the calorie editor returns the entry and the flow saves it '
      'with its stock', (tester) async {
    final commitStore = _RecordingCommitStore();
    final editor = await _openCalorieEditor(tester, commitStore: commitStore);

    expect(editor.page.preselectedMealType, MealType.lunch);
    expect(editor.page.preselectedLoggedAt, _editorLoggedAt);
    expect(editor.page.prefilledAmount, 120);
    expect(editor.page.prefilledUnit, ConsumedUnit.milliliters);

    await tester.tap(find.byKey(CalorieEntryEditorKeys.saveButton));
    await tester.pumpAndSettle();

    final staged = editor.staged!;
    expect(commitStore.entry?.name, 'Waffelhörnchen Haselnuss-Vanille');
    expect(commitStore.entry?.consumedAmount, 120);
    expect(commitStore.entry?.sourceInventoryItemId, staged.pending.itemId);
    expect(
      commitStore.entry?.sourceInventoryAmountToRestore,
      staged.pending.amount,
    );
    expect(commitStore.pendingConsumption?.id, staged.pending.id);
    expect(staged.store.pendingConsumptionById(staged.pending.id), isNull);
    expect(find.text('Ins Tagebuch eingetragen'), findsOneWidget);
    expect(find.text('Rückgängig'), findsOneWidget);
  });

  testWidgets('leaving the calorie editor releases the stock', (tester) async {
    final commitStore = _RecordingCommitStore();
    final editor = await _openCalorieEditor(tester, commitStore: commitStore);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    final staged = editor.staged!;
    expect(commitStore.entry, isNull);
    expect(staged.store.pendingConsumptionById(staged.pending.id), isNull);
    expect(find.text('Ins Tagebuch eingetragen'), findsNothing);
  });
}

final DateTime _editorLoggedAt = DateTime.parse('2026-04-06T12:30:00Z');

/// What the eat flow staged and the calorie editor it opened.
class _OpenedEditor {
  _Staged? staged;
  late CalorieEntryEditorPage page;
}

/// Eats 120 ml of an item the eat page cannot log directly, so the flow
/// opens the real calorie editor.
Future<_OpenedEditor> _openCalorieEditor(
  WidgetTester tester, {
  required _RecordingCommitStore commitStore,
}) async {
  final opened = _OpenedEditor();
  final user = _signedInUser();
  final router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) {
          return Scaffold(
            body: _CompleteEatFlowButton(
              onStaged: (value) => opened.staged = value,
              item: _amountItemWithNutrition(),
              request: InventoryItemEatRequest(
                inventoryAmount: 1,
                loggedAt: _editorLoggedAt,
                mealType: MealType.lunch,
                calorieAmount: 120,
                calorieUnit: ConsumedUnit.milliliters,
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
        ..._eatServiceOverrides(user: user, commitStore: commitStore),
        authStateChangesProvider.overrideWith(
          (ref) => Stream<User?>.value(user),
        ),
      ],
    ),
  );
  await tester.tap(find.text('eat'));
  await tester.pumpAndSettle();
  opened.page = tester.widget(find.byType(CalorieEntryEditorPage));
  return opened;
}
