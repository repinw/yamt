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
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/application/'
    'calorie_entry_amount_edit_flow.dart';
import 'package:yamt/features/calories/application/calorie_entry_delete_flow.dart';
import 'package:yamt/features/calories/application/'
    'calorie_inventory_entry_save_handler.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_inventory_create_context.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_inventory_stock_adjustment.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/presentation/calorie_entry_editor_page.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_editor_content.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../support/fake_calories_repositories.dart';

class _MockUser extends Mock implements User;

class _FakeInventoryItemRepository implements InventoryItemRepository {
  new({required List<InventoryItem> initialItems})
    : _items = List<InventoryItem>.from(initialItems);

  final StreamController<List<InventoryItem>> _controller =
      StreamController<List<InventoryItem>>.broadcast();
  List<InventoryItem> _items;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async => true;

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

  Future<void> dispose() => _controller.close();
}

class _RecordingInventorySaveFlow
    implements InventoryBackedCalorieEntrySaveFlow {
  CalorieEntry? entry;
  String? pendingConsumptionId;

  @override
  Future<bool> saveEntry({
    required CalorieEntry entry,
    required String pendingConsumptionId,
    PendingInventoryConsumption? pendingConsumption,
    InventoryItemsController? inventoryController,
  }) async {
    this.entry = entry;
    this.pendingConsumptionId = pendingConsumptionId;
    return true;
  }
}

class _DiscardRecordingInventoryItemsController
    extends InventoryItemsController {
  var _hasPendingConsumption = true;

  @override
  FutureOr<List<InventoryItem>> build() {
    return <InventoryItem>[_inventoryItem()];
  }

  @override
  bool hasPendingConsumption(String draftId) {
    return _hasPendingConsumption && draftId == 'pending-1';
  }

  @override
  Future<bool> discardPendingConsumption(String draftId) async {
    if (!hasPendingConsumption(draftId)) {
      return false;
    }
    _hasPendingConsumption = false;
    return true;
  }
}

CalorieEntryDeleteFlow _calorieEntryDeleteFlow({
  Future<bool> Function(String entryId)? deleteEntryById,
  Future<bool> Function(String itemId, int amount)? restoreConsumedItem,
  Future<bool> Function(String itemId, int amount, {DateTime? consumedAt})?
  rollbackRestoredItem,
  Future<bool> Function(String itemId)? sourceInventoryItemExists,
  Future<bool> Function({required String mealId, required num portions})?
  restorePreparedMealPortions,
  Future<bool> Function({
    required String mealId,
    required num discardedPortions,
  })?
  rollbackRestoredPreparedMeal,
  Future<bool> Function(String mealId)? sourcePreparedMealExists,
}) {
  return CalorieEntryDeleteFlow(
    deleteEntryById: deleteEntryById ?? (entryId) async => true,
    restoreConsumedItem: restoreConsumedItem ?? (itemId, amount) async => true,
    rollbackRestoredItem:
        rollbackRestoredItem ?? (itemId, amount, {consumedAt}) async => true,
    sourceInventoryItemExists:
        sourceInventoryItemExists ?? (itemId) async => true,
    restorePreparedMealPortions:
        restorePreparedMealPortions ??
        ({required mealId, required portions}) async => true,
    rollbackRestoredPreparedMeal:
        rollbackRestoredPreparedMeal ??
        ({required mealId, required discardedPortions}) async => true,
    sourcePreparedMealExists:
        sourcePreparedMealExists ?? (mealId) async => true,
  );
}

CalorieEntryDeleteFlow _restoreFailingDeleteFlow() {
  return _calorieEntryDeleteFlow(
    restoreConsumedItem: (itemId, amount) async => false,
    restorePreparedMealPortions: ({required mealId, required portions}) async =>
        false,
  );
}

CalorieEntryDeleteFlow _sourceDisappearsDeleteFlow() {
  var sourceChecks = 0;
  return _calorieEntryDeleteFlow(
    sourceInventoryItemExists: (itemId) async {
      sourceChecks += 1;
      return sourceChecks == 1;
    },
  );
}

class _AutoOpenRoutePage extends StatefulWidget {
  const new({required this.location, this.extra});

  final String location;
  final Object? extra;

  @override
  State<_AutoOpenRoutePage> createState() => _AutoOpenRoutePageState();
}

class _AutoOpenRoutePageState extends State<_AutoOpenRoutePage> {
  var _didOpenRoute = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didOpenRoute) {
      return;
    }
    _didOpenRoute = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        GoRouter.of(context).push(widget.location, extra: widget.extra),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.shrink());
  }
}

CalorieEntry _entry(
  String id, {
  String? sourceInventoryItemId,
  int? sourceInventoryAmountToRestore,
}) {
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: 'Skyr',
    mealType: MealType.breakfast,
    consumedAmount: 200,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 100,
    per100Protein: 10,
    per100Carbs: 5,
    per100Fat: 1,
    sourceInventoryItemId: sourceInventoryItemId,
    sourceInventoryAmountToRestore: sourceInventoryAmountToRestore,
    loggedAt: DateTime(2026, 2, 25, 8),
    createdAt: DateTime(2026, 2, 25, 8),
    updatedAt: DateTime(2026, 2, 25, 8),
  );
}

InventoryItem _inventoryItem({int quantity = 3}) {
  return InventoryItem.create(
    id: 'inventory-1',
    name: 'Milk',
    entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
    storeName: 'Store',
    quantity: quantity,
    initialQuantity: 3,
  );
}

CalorieEntry _bundleEntry(String id) {
  final loggedAt = DateTime(2026, 2, 25, 12);
  return CalorieEntry.bundle(
    id: id,
    userId: 'user-1',
    name: 'Chili',
    brand: 'Kitchen Club',
    mealType: MealType.lunch,
    totalKcal: 420,
    totalProtein: 28,
    totalCarbs: 35,
    totalFat: 18,
    bundleSourcePreparedMealId: 'prepared-1',
    bundleConsumedPortions: 2,
    bundleTotalPortions: 4,
    bundleComponents: const [
      CalorieEntryBundleComponent(
        name: 'Beans',
        amountLabel: '150 g',
        brand: 'Acme',
        imageUrl: 'https://images.example.com/beans.jpg',
        totalKcal: 120,
        totalProtein: 8,
        totalCarbs: 18,
        totalFat: 1,
      ),
      CalorieEntryBundleComponent(
        name: 'Corn',
        amountLabel: '90 g',
        brand: 'Farm Fresh',
        imageUrl: 'https://images.example.com/corn.jpg',
        totalKcal: 80,
        totalProtein: 3,
        totalCarbs: 12,
        totalFat: 1,
      ),
    ],
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

Widget _buildHarness({
  required FakeCalorieLogRepository logRepository,
  required FakeCalorieSettingsRepository settingsRepository,
  required String initialLocation,
  Object? createExtra,
  ProviderContainer? container,
  List<Override> additionalOverrides = const <Override>[],
  Override? pendingConsumptionDiscarderOverride,
  bool openCreateFromRoot = false,
  String? autoOpenLocationFromRoot,
  Locale locale = const Locale('en'),
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    initialExtra: createExtra,
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) {
          if (autoOpenLocationFromRoot != null) {
            return _AutoOpenRoutePage(
              location: autoOpenLocationFromRoot,
              extra: createExtra,
            );
          }
          if (openCreateFromRoot) {
            return _AutoOpenRoutePage(
              location: AppRoutes.homeCaloriesEntryCreate,
              extra: createExtra,
            );
          }
          return const Scaffold(body: Text('Root'));
        },
      ),
      GoRoute(
        path: AppRoutes.homeCaloriesEntryCreate,
        builder: (context, state) {
          final args = state.extra is CalorieEntryCreateArgs
              ? state.extra! as CalorieEntryCreateArgs
              : null;
          return CalorieEntryEditorPage(
            prefilledProfile: args?.prefilledProfile,
            scannedSourceRef: args?.scannedSourceRef,
            inventoryContext: args?.inventoryContext,
            preselectedMealType: args?.preselectedMealType,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.homeInventory,
        builder: (context, state) {
          return const Scaffold(body: Text('Inventory Home'));
        },
      ),
      GoRoute(
        path: AppRoutes.homeCalories,
        builder: (context, state) {
          return const Scaffold(body: Text('Calories Home'));
        },
      ),
      GoRoute(
        path: AppRoutes.homeCaloriesEntryDetails,
        builder: (context, state) {
          return CalorieEntryEditorPage(
            entryId: state.pathParameters['entryId'],
          );
        },
      ),
    ],
  );

  final user = _MockUser();
  when(() => user.uid).thenReturn('user-1');

  final app = MaterialApp.router(
    locale: locale,
    routerConfig: router,
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );

  if (container != null) {
    return UncontrolledProviderScope(container: container, child: app);
  }

  final providerContainer = ProviderContainer(
    overrides: [
      authStateChangesProvider.overrideWith((ref) => Stream<User?>.value(user)),
      firebaseFirestoreProvider.overrideWith((ref) => null),
      userProfileProvider.overrideWith((ref) => Stream.value(null)),
      calorieLogRepositoryProvider.overrideWithValue(logRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      calorieInventoryEntrySaveHandlerProvider.overrideWith((ref) {
        return ref.read(inventoryBackedCalorieEntrySaveFlowProvider).saveEntry;
      }),
      pendingConsumptionDiscarderOverride ??
          calorieInventoryPendingConsumptionDiscarderProvider.overrideWith((
            ref,
          ) {
            return ref
                .read(inventoryItemsControllerProvider.notifier)
                .discardPendingConsumption;
          }),
      ...additionalOverrides,
    ],
  );
  addTearDown(providerContainer.dispose);
  return UncontrolledProviderScope(container: providerContainer, child: app);
}

Widget _buildDirectEditorHarness({
  required ProviderContainer container,
  required User user,
  required String barcode,
  required MealType mealType,
  required DateTime loggedAt,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: CalorieEntryEditorContent(
        key: const ValueKey('editor-content'),
        user: user,
        prefilledProfile: CalorieProductProfile(
          barcode: barcode,
          name: 'Greek Yogurt',
          brand: 'Test Brand',
          per100Kcal: 95,
          per100Protein: 9.8,
          per100Carbs: 4.1,
          per100Fat: 0.5,
          source: CalorieProductSource.offBarcode,
          offProductId: 'off-$barcode',
          createdAt: DateTime(2026, 2, 25, 8),
          updatedAt: DateTime(2026, 2, 25, 8),
        ),
        preselectedMealType: mealType,
        preselectedLoggedAt: loggedAt,
      ),
    ),
  );
}

void main() {
  testWidgets('create editor refreshes draft when create context changes', (
    tester,
  ) async {
    final logRepository = FakeCalorieLogRepository();
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);
    final user = _MockUser();
    when(() => user.uid).thenReturn('user-1');
    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        inventoryItemsControllerProvider.overrideWith(
          _DiscardRecordingInventoryItemsController.new,
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _buildDirectEditorHarness(
        container: container,
        user: user,
        barcode: '4006381333931',
        mealType: MealType.lunch,
        loggedAt: DateTime(2026, 2, 25, 12),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Greek Yogurt'), findsOneWidget);

    await tester.pumpWidget(
      _buildDirectEditorHarness(
        container: container,
        user: user,
        barcode: '4012345678901',
        mealType: MealType.snack,
        loggedAt: DateTime(2026, 2, 26, 15),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Greek Yogurt'), findsOneWidget);
  });

  testWidgets('create flow saves a new entry and pops back', (tester) async {
    final logRepository = FakeCalorieLogRepository();
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        initialLocation: AppRoutes.homeCaloriesEntryCreate,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.nameField),
      'Greek Yogurt',
    );
    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.per100KcalField),
      '95',
    );
    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.per100ProteinField),
      '9.8',
    );
    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.per100CarbsField),
      '4.1',
    );
    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.per100FatField),
      '0.5',
    );

    await tester.tap(find.byKey(CalorieEntryEditorKeys.saveButton));
    await tester.pumpAndSettle();

    expect(logRepository.entries, hasLength(1));
    expect(logRepository.entries.single.name, 'Greek Yogurt');
    expect(find.text('Inventory Home'), findsOneWidget);
  });

  testWidgets('create flow closes before the save completes', (tester) async {
    final saveGate = Completer<void>();
    final logRepository = FakeCalorieLogRepository()
      ..saveGate = saveGate.future;
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        initialLocation: AppRoutes.homeCaloriesEntryCreate,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.nameField),
      'Greek Yogurt',
    );
    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.per100KcalField),
      '95',
    );
    await tester.tap(find.byKey(CalorieEntryEditorKeys.saveButton));
    await tester.pumpAndSettle();

    expect(find.text('Inventory Home'), findsOneWidget);
    expect(logRepository.entries, isEmpty);

    saveGate.complete();
    await tester.pumpAndSettle();

    expect(logRepository.entries.single.name, 'Greek Yogurt');
  });

  testWidgets('create flow reports a failed save after closing', (
    tester,
  ) async {
    final logRepository = FakeCalorieLogRepository()..saveShouldFail = true;
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        initialLocation: AppRoutes.homeCaloriesEntryCreate,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.nameField),
      'Greek Yogurt',
    );
    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.per100KcalField),
      '95',
    );
    await tester.tap(find.byKey(CalorieEntryEditorKeys.saveButton));
    await tester.pumpAndSettle();

    expect(find.text('Inventory Home'), findsOneWidget);
    expect(find.text('Could not save entry.'), findsOneWidget);
    expect(logRepository.entries, isEmpty);
  });

  testWidgets('details flow saves a meal change at once and can undo it', (
    tester,
  ) async {
    final existing = _entry('entry-1');
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[existing],
    );
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        initialLocation: AppRoutes.homeCaloriesEntryDetailsPath('entry-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Skyr'), findsOneWidget);
    expect(find.byKey(CalorieEntryEditorKeys.saveButton), findsNothing);

    await tester.tap(find.byKey(CalorieEntryDetailKeys.mealSelector));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Snack').last);
    await tester.pumpAndSettle();

    expect(logRepository.entries.single.mealType, MealType.snack);
    expect(find.text('Entry updated'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(logRepository.entries.single.mealType, MealType.breakfast);
  });

  testWidgets(
    'details flow moves the entry to another day and keeps the time',
    (tester) async {
      final existing = _entry('entry-day');
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[existing],
      );
      final settingsRepository = FakeCalorieSettingsRepository();
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      await tester.pumpWidget(
        _buildHarness(
          logRepository: logRepository,
          settingsRepository: settingsRepository,
          initialLocation: AppRoutes.homeCaloriesEntryDetailsPath('entry-day'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(CalorieEntryDetailKeys.loggedDayButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('27').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.byType(TimePickerDialog), findsNothing);
      final updated = logRepository.entries.single;
      expect(updated.id, 'entry-day');
      expect(updated.loggedAt, DateTime(2026, 2, 27, 8));
    },
  );

  testWidgets('details flow changes the amount and rescales totals', (
    tester,
  ) async {
    final existing = _entry('entry-amount');
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[existing],
    );
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        initialLocation: AppRoutes.homeCaloriesEntryDetailsPath('entry-amount'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CalorieEntryDetailKeys.amountValue));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(CalorieEntryDetailKeys.amountField),
      '150',
    );
    await tester.tap(find.byKey(CalorieEntryDetailKeys.amountSaveButton));
    await tester.pumpAndSettle();

    final updated = logRepository.entries.single;
    expect(updated.consumedAmount, 150);
    expect(updated.totalKcal, 150);
    expect(find.text('150 g'), findsWidgets);
  });

  testWidgets('details flow moves the stock with an inventory entry amount', (
    tester,
  ) async {
    final existing = _entry(
      'entry-stock',
      sourceInventoryItemId: 'inventory-1',
      sourceInventoryAmountToRestore: 200,
    );
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[existing],
    );
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);
    final adjustedAmounts = <double>[];

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        initialLocation: AppRoutes.homeCaloriesEntryDetailsPath('entry-stock'),
        additionalOverrides: <Override>[
          calorieInventoryStockAdjusterProvider.overrideWith((ref) {
            return ({
              required itemId,
              required reservedAmount,
              required consumedAmount,
            }) async {
              adjustedAmounts.add(consumedAmount);
              return CalorieInventoryStockAdjustment(
                status: CalorieInventoryStockAdjustmentStatus.applied,
                reservedAmount: consumedAmount.round(),
              );
            };
          }),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CalorieEntryDetailKeys.amountValue));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(CalorieEntryDetailKeys.amountField),
      '300',
    );
    await tester.tap(find.byKey(CalorieEntryDetailKeys.amountSaveButton));
    await tester.pumpAndSettle();

    final updated = logRepository.entries.single;
    expect(updated.consumedAmount, 300);
    expect(updated.sourceInventoryAmountToRestore, 300);
    expect(adjustedAmounts, <double>[300]);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    final undone = logRepository.entries.single;
    expect(undone.consumedAmount, 200);
    expect(undone.sourceInventoryAmountToRestore, 200);
    expect(adjustedAmounts, <double>[300, 200]);
  });

  testWidgets('details flow removes a plain entry and can undo it', (
    tester,
  ) async {
    final existing = _entry('entry-plain');
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[existing],
    );
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        initialLocation: AppRoutes.root,
        autoOpenLocationFromRoot: AppRoutes.homeCaloriesEntryDetailsPath(
          'entry-plain',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(CalorieEntryDetailKeys.returnToInventoryButton),
    );
    await tester.pumpAndSettle();

    expect(logRepository.entries, isEmpty);
    expect(find.text('Entry removed'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(logRepository.entries.single.id, 'entry-plain');
  });

  testWidgets('details flow logs the same food again', (tester) async {
    final existing = _entry('entry-again');
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[existing],
    );
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        initialLocation: AppRoutes.homeCaloriesEntryDetailsPath('entry-again'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CalorieEntryDetailKeys.eatAgainButton));
    await tester.pumpAndSettle();

    expect(logRepository.entries, hasLength(2));
    final repeated = logRepository.entries.firstWhere(
      (entry) => entry.id != 'entry-again',
    );
    expect(repeated.name, 'Skyr');
    expect(repeated.consumedAmount, 200);
    expect(find.text('Logged again'), findsOneWidget);
  });

  testWidgets('prepared meal details view shows ingredient table', (
    tester,
  ) async {
    final existing = _bundleEntry('bundle-1')
        .copyWith(bundleConsumedPortions: 0.5);
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[existing],
    );
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        initialLocation: AppRoutes.homeCaloriesEntryDetailsPath('bundle-1'),
        locale: const Locale('de'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CalorieEntryDetailKeys.brandValue), findsOneWidget);
    expect(find.text('Kitchen Club'), findsOneWidget);
    expect(find.text('0,5/4 Portionen'), findsWidgets);

    await tester.scrollUntilVisible(
      find.byKey(CalorieEntryDetailKeys.ingredientsTable),
      250,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CalorieEntryDetailKeys.ingredientsTable), findsOneWidget);
    expect(
      find.byKey(CalorieEntryDetailKeys.ingredientNameCell(0)),
      findsOneWidget,
    );
    expect(find.text('Beans'), findsOneWidget);
    expect(find.text('150 g'), findsOneWidget);
    expect(
      find.byKey(CalorieEntryDetailKeys.returnToInventoryButton),
      findsOneWidget,
    );
  });

  testWidgets('prepared meal details view does not overflow on small screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 520);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final existing = _bundleEntry('bundle-small');
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[existing],
    );
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        initialLocation: AppRoutes.homeCaloriesEntryDetailsPath('bundle-small'),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('details flow shows snackbar when saving changes fails', (
    tester,
  ) async {
    final existing = _entry('entry-save-fail');
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[existing],
    )..saveShouldFail = true;
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        initialLocation: AppRoutes.homeCaloriesEntryDetailsPath(
          'entry-save-fail',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CalorieEntryDetailKeys.mealSelector));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Snack').last);
    await tester.pumpAndSettle();

    expect(find.text('Could not save entry.'), findsOneWidget);
    expect(find.text('Breakfast'), findsOneWidget);
    expect(logRepository.entries.single.mealType, MealType.breakfast);
  });

  testWidgets(
    'details flow shows inventory restore snackbar when return fails',
    (tester) async {
      final existing = _entry(
        'entry-restore-fail',
        sourceInventoryItemId: 'inventory-1',
        sourceInventoryAmountToRestore: 2,
      );
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[existing],
      );
      final settingsRepository = FakeCalorieSettingsRepository();
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      await tester.pumpWidget(
        _buildHarness(
          logRepository: logRepository,
          settingsRepository: settingsRepository,
          initialLocation: AppRoutes.homeCaloriesEntryDetailsPath(
            'entry-restore-fail',
          ),
          additionalOverrides: [
            calorieEntryDeleteFlowProvider.overrideWithValue(
              _restoreFailingDeleteFlow(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(CalorieEntryDetailKeys.returnToInventoryButton),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Return to inventory').last);
      await tester.pumpAndSettle();

      expect(
        find.text('The food could not be added back to inventory.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<IconButton>(
              find.byKey(CalorieEntryDetailKeys.returnToInventoryButton),
            )
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets(
    'details flow deletes diary entry without restore when chosen in dialog',
    (tester) async {
      final existing = _entry(
        'entry-delete-only',
        sourceInventoryItemId: 'inventory-1',
        sourceInventoryAmountToRestore: 2,
      );
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[existing],
      );
      final settingsRepository = FakeCalorieSettingsRepository();
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      bool? capturedRestoreToInventory;
      final testDeleteFlow = _calorieEntryDeleteFlow(
        deleteEntryById: logRepository.deleteEntry,
        restoreConsumedItem: (id, amount) async {
          capturedRestoreToInventory = true;
          return true;
        },
      );

      await tester.pumpWidget(
        _buildHarness(
          logRepository: logRepository,
          settingsRepository: settingsRepository,
          initialLocation: AppRoutes.homeCaloriesEntryDetailsPath(
            'entry-delete-only',
          ),
          additionalOverrides: [
            calorieEntryDeleteFlowProvider.overrideWithValue(testDeleteFlow),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(CalorieEntryDetailKeys.returnToInventoryButton),
      );
      await tester.pumpAndSettle();

      expect(find.text('Remove entry'), findsOneWidget);
      expect(
        find.text('Would you like to return this food to the inventory?'),
        findsOneWidget,
      );

      await tester.tap(find.text('Delete from diary only'));
      await tester.pumpAndSettle();

      expect(logRepository.entries, isEmpty);
      expect(capturedRestoreToInventory, isNull);
    },
  );

  testWidgets(
    'details flow deletes diary entry only when inventory source is gone',
    (tester) async {
      final existing = _entry(
        'entry-source-gone',
        sourceInventoryItemId: 'missing-item',
        sourceInventoryAmountToRestore: 2,
      );
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[existing],
      );
      final settingsRepository = FakeCalorieSettingsRepository();
      final inventoryRepository = _FakeInventoryItemRepository(
        initialItems: const <InventoryItem>[],
      );
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);
      addTearDown(inventoryRepository.dispose);

      await tester.pumpWidget(
        _buildHarness(
          logRepository: logRepository,
          settingsRepository: settingsRepository,
          initialLocation: AppRoutes.homeCaloriesEntryDetailsPath(
            'entry-source-gone',
          ),
          additionalOverrides: [
            inventoryItemRepositoryProvider.overrideWithValue(
              inventoryRepository,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(CalorieEntryDetailKeys.returnToInventoryButton),
      );
      await tester.pumpAndSettle();

      expect(find.text('Food no longer in inventory'), findsOneWidget);
      expect(
        find.text(
          '"Skyr" is no longer in inventory, so it cannot be returned. '
          'Delete it from the diary only?',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Delete from diary'));
      await tester.pumpAndSettle();

      expect(logRepository.entries, isEmpty);
      expect(find.text('Calorie entry details'), findsNothing);
    },
  );

  testWidgets(
    'details flow asks delete-only when source disappears during restore',
    (tester) async {
      final existing = _entry(
        'entry-source-race',
        sourceInventoryItemId: 'inventory-1',
        sourceInventoryAmountToRestore: 2,
      );
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[existing],
      );
      final settingsRepository = FakeCalorieSettingsRepository();
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      await tester.pumpWidget(
        _buildHarness(
          logRepository: logRepository,
          settingsRepository: settingsRepository,
          initialLocation: AppRoutes.homeCaloriesEntryDetailsPath(
            'entry-source-race',
          ),
          additionalOverrides: [
            calorieEntryDeleteFlowProvider.overrideWithValue(
              _sourceDisappearsDeleteFlow(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(CalorieEntryDetailKeys.returnToInventoryButton),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Return to inventory').last);
      await tester.pumpAndSettle();

      expect(find.text('Food no longer in inventory'), findsOneWidget);

      await tester.tap(find.text('Delete from diary'));
      await tester.pumpAndSettle();

      expect(find.text('Calorie entry details'), findsNothing);
    },
  );

  testWidgets(
    'prepared meal details show snackbar when return to inventory fails',
    (tester) async {
      final existing = _bundleEntry('bundle-restore-fail');
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[existing],
      );
      final settingsRepository = FakeCalorieSettingsRepository();
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      await tester.pumpWidget(
        _buildHarness(
          logRepository: logRepository,
          settingsRepository: settingsRepository,
          initialLocation: AppRoutes.homeCaloriesEntryDetailsPath(
            'bundle-restore-fail',
          ),
          additionalOverrides: [
            calorieEntryDeleteFlowProvider.overrideWithValue(
              _restoreFailingDeleteFlow(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(CalorieEntryDetailKeys.returnToInventoryButton),
        250,
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(CalorieEntryDetailKeys.returnToInventoryButton),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Return to inventory').last);
      await tester.pumpAndSettle();

      expect(
        find.text('The meal could not be returned to inventory.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<IconButton>(
              find.byKey(CalorieEntryDetailKeys.returnToInventoryButton),
            )
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('validation blocks save for empty name', (tester) async {
    final logRepository = FakeCalorieLogRepository();
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        initialLocation: AppRoutes.homeCaloriesEntryCreate,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(CalorieEntryEditorKeys.nameField), '');
    await tester.tap(find.byKey(CalorieEntryEditorKeys.saveButton));
    await tester.pumpAndSettle();

    expect(find.text('This field is required.'), findsOneWidget);
    expect(logRepository.entries, isEmpty);
  });

  testWidgets('validation blocks save for negative consumed amount', (
    tester,
  ) async {
    final logRepository = FakeCalorieLogRepository();
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        initialLocation: AppRoutes.homeCaloriesEntryCreate,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.nameField),
      'Greek Yogurt',
    );
    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.amountField),
      '-10',
    );
    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.per100KcalField),
      '95',
    );

    await tester.tap(find.byKey(CalorieEntryEditorKeys.saveButton));
    await tester.pumpAndSettle();

    expect(
      find.text('Please enter a number greater than zero.'),
      findsOneWidget,
    );
    expect(logRepository.entries, isEmpty);
  });

  testWidgets('validation blocks save for invalid number characters', (
    tester,
  ) async {
    final logRepository = FakeCalorieLogRepository();
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        initialLocation: AppRoutes.homeCaloriesEntryCreate,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.nameField),
      'Greek Yogurt',
    );
    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.amountField),
      '200',
    );
    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.per100KcalField),
      '95',
    );
    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.per100ProteinField),
      'abc',
    );

    await tester.tap(find.byKey(CalorieEntryEditorKeys.saveButton));
    await tester.pumpAndSettle();

    expect(
      find.text('Please enter a number equal to or greater than zero.'),
      findsOneWidget,
    );
    expect(logRepository.entries, isEmpty);
  });

  testWidgets('create flow keeps imageUrl from prefilled profile', (
    tester,
  ) async {
    final logRepository = FakeCalorieLogRepository();
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        initialLocation: AppRoutes.homeCaloriesEntryCreate,
        createExtra: CalorieEntryCreateArgs(
          prefilledProfile: CalorieProductProfile(
            barcode: '4006381333931',
            name: 'Greek Yogurt',
            brand: 'Test Brand',
            per100Kcal: 95,
            per100Protein: 9.8,
            per100Carbs: 4.1,
            per100Fat: 0.5,
            source: CalorieProductSource.offBarcode,
            offProductId: 'off-123',
            imageUrl: 'https://images.example.com/yogurt.jpg',
            createdAt: DateTime(2026, 2, 25, 8),
            updatedAt: DateTime(2026, 2, 25, 8),
          ),
          preselectedMealType: MealType.breakfast,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CalorieEntryEditorKeys.saveButton));
    await tester.pumpAndSettle();

    expect(logRepository.entries, hasLength(1));
    expect(
      logRepository.entries.single.imageUrl,
      'https://images.example.com/yogurt.jpg',
    );
  });

  testWidgets('back navigation discards pending inventory consumption', (
    tester,
  ) async {
    final logRepository = FakeCalorieLogRepository();
    final settingsRepository = FakeCalorieSettingsRepository();
    final inventoryController = _DiscardRecordingInventoryItemsController();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    String? discardedPendingConsumptionId;
    Future<bool>? discardFuture;
    final user = _MockUser();
    when(() => user.uid).thenReturn('user-1');

    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith(
          (ref) => Stream<User?>.value(user),
        ),
        firebaseFirestoreProvider.overrideWith((ref) => null),
        userProfileProvider.overrideWith((ref) => Stream.value(null)),
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        inventoryItemsControllerProvider.overrideWith(
          () => inventoryController,
        ),
        calorieInventoryPendingConsumptionDiscarderProvider.overrideWith((ref) {
          final discardPendingConsumption = ref
              .read(inventoryItemsControllerProvider.notifier)
              .discardPendingConsumption;
          return (pendingConsumptionId) {
            discardedPendingConsumptionId = pendingConsumptionId;
            discardFuture = discardPendingConsumption(pendingConsumptionId);
            return discardFuture!;
          };
        }),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        initialLocation: AppRoutes.root,
        createExtra: const CalorieEntryCreateArgs(
          prefilledProfile: null,
          inventoryContext: CalorieInventoryCreateContext(
            inventoryItemId: 'inventory-1',
            foodFingerprint: 'milk',
            globalFoodItemId: 'off-milk',
            pendingConsumptionId: 'pending-1',
            inventoryAmountToRestore: 2,
            itemName: 'Milk',
            itemBrand: null,
            consumedAmount: 100,
            consumedUnit: ConsumedUnit.grams,
          ),
        ),
        container: container,
        openCreateFromRoot: true,
      ),
    );
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();

    expect(inventoryController.hasPendingConsumption('pending-1'), isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();

    expect(discardedPendingConsumptionId, 'pending-1');
    await tester.runAsync(() async {
      await discardFuture;
    });
    await tester.pump();

    expect(inventoryController.hasPendingConsumption('pending-1'), isFalse);
  });

  testWidgets('pending inventory discard no-ops when handler is null', (
    tester,
  ) async {
    final logRepository = FakeCalorieLogRepository();
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        initialLocation: AppRoutes.homeCaloriesEntryCreate,
        createExtra: const CalorieEntryCreateArgs(
          prefilledProfile: null,
          inventoryContext: CalorieInventoryCreateContext(
            inventoryItemId: 'inventory-1',
            foodFingerprint: 'milk',
            globalFoodItemId: 'off-milk',
            pendingConsumptionId: 'pending-1',
            inventoryAmountToRestore: 2,
            itemName: 'Milk',
            itemBrand: null,
            consumedAmount: 100,
            consumedUnit: ConsumedUnit.grams,
          ),
        ),
        pendingConsumptionDiscarderOverride:
            calorieInventoryPendingConsumptionDiscarderProvider.overrideWith(
              (ref) => null,
            ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('pending inventory discard catches handler errors', (
    tester,
  ) async {
    final logRepository = FakeCalorieLogRepository();
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        initialLocation: AppRoutes.homeCaloriesEntryCreate,
        createExtra: const CalorieEntryCreateArgs(
          prefilledProfile: null,
          inventoryContext: CalorieInventoryCreateContext(
            inventoryItemId: 'inventory-1',
            foodFingerprint: 'milk',
            globalFoodItemId: 'off-milk',
            pendingConsumptionId: 'pending-1',
            inventoryAmountToRestore: 2,
            itemName: 'Milk',
            itemBrand: null,
            consumedAmount: 100,
            consumedUnit: ConsumedUnit.grams,
          ),
        ),
        pendingConsumptionDiscarderOverride:
            calorieInventoryPendingConsumptionDiscarderProvider.overrideWith((
              ref,
            ) {
              return (pendingConsumptionId) async {
                throw StateError('container disposed');
              };
            }),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'create flow delegates inventory-backed save when pending exists',
    (tester) async {
      final logRepository = FakeCalorieLogRepository();
      final settingsRepository = FakeCalorieSettingsRepository();
      final saveFlow = _RecordingInventorySaveFlow();
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      await tester.pumpWidget(
        _buildHarness(
          logRepository: logRepository,
          settingsRepository: settingsRepository,
          initialLocation: AppRoutes.homeCaloriesEntryCreate,
          createExtra: const CalorieEntryCreateArgs(
            prefilledProfile: null,
            inventoryContext: CalorieInventoryCreateContext(
              inventoryItemId: 'inventory-1',
              foodFingerprint: 'milk',
              globalFoodItemId: 'off-milk',
              pendingConsumptionId: 'pending-1',
              inventoryAmountToRestore: 2,
              itemName: 'Milk',
              itemBrand: null,
              consumedAmount: 100,
              consumedUnit: ConsumedUnit.grams,
            ),
          ),
          additionalOverrides: [
            inventoryBackedCalorieEntrySaveFlowProvider.overrideWithValue(
              saveFlow,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(CalorieEntryEditorKeys.nameField),
        'Greek Yogurt',
      );
      await tester.enterText(
        find.byKey(CalorieEntryEditorKeys.per100KcalField),
        '95',
      );
      await tester.enterText(
        find.byKey(CalorieEntryEditorKeys.per100ProteinField),
        '9.8',
      );
      await tester.enterText(
        find.byKey(CalorieEntryEditorKeys.per100CarbsField),
        '4.1',
      );
      await tester.enterText(
        find.byKey(CalorieEntryEditorKeys.per100FatField),
        '0.5',
      );

      await tester.tap(find.byKey(CalorieEntryEditorKeys.saveButton));
      await tester.pumpAndSettle();

      expect(saveFlow.pendingConsumptionId, 'pending-1');
      expect(saveFlow.entry?.sourceInventoryItemId, 'inventory-1');
      expect(logRepository.entries, isEmpty);
    },
  );

  testWidgets(
    'inventory-backed save does not use widget ref after page unmount',
    (tester) async {
      final logRepository = FakeCalorieLogRepository()
        ..onReadEntriesForDay = (day) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return const <CalorieEntry>[];
        };
      final settingsRepository = FakeCalorieSettingsRepository();
      final saveFlow = _RecordingInventorySaveFlow();
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      await tester.pumpWidget(
        _buildHarness(
          logRepository: logRepository,
          settingsRepository: settingsRepository,
          initialLocation: AppRoutes.root,
          createExtra: const CalorieEntryCreateArgs(
            prefilledProfile: null,
            inventoryContext: CalorieInventoryCreateContext(
              inventoryItemId: 'inventory-1',
              foodFingerprint: 'milk',
              globalFoodItemId: 'off-milk',
              pendingConsumptionId: 'pending-1',
              inventoryAmountToRestore: 2,
              itemName: 'Milk',
              itemBrand: null,
              consumedAmount: 100,
              consumedUnit: ConsumedUnit.grams,
            ),
          ),
          additionalOverrides: [
            inventoryBackedCalorieEntrySaveFlowProvider.overrideWithValue(
              saveFlow,
            ),
          ],
          openCreateFromRoot: true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(CalorieEntryEditorKeys.nameField),
        'Greek Yogurt',
      );
      await tester.enterText(
        find.byKey(CalorieEntryEditorKeys.per100KcalField),
        '95',
      );
      await tester.enterText(
        find.byKey(CalorieEntryEditorKeys.per100ProteinField),
        '9.8',
      );
      await tester.enterText(
        find.byKey(CalorieEntryEditorKeys.per100CarbsField),
        '4.1',
      );
      await tester.enterText(
        find.byKey(CalorieEntryEditorKeys.per100FatField),
        '0.5',
      );

      await tester.tap(find.byKey(CalorieEntryEditorKeys.saveButton));
      await tester.pump();
      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      expect(saveFlow.pendingConsumptionId, 'pending-1');
      expect(saveFlow.entry?.sourceInventoryItemId, 'inventory-1');
      expect(tester.takeException(), isNull);
    },
  );
}
