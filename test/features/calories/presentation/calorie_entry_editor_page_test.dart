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
import 'package:yamt/features/calories/application/calorie_entry_delete_flow.dart';
import 'package:yamt/features/calories/application/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/calorie_entry_editor_page.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../support/fake_calories_repositories.dart';

class _MockUser extends Mock implements User {}

class _FakeInventoryItemRepository implements InventoryItemRepository {
  _FakeInventoryItemRepository({required List<InventoryItem> initialItems})
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
  }) async {
    this.entry = entry;
    this.pendingConsumptionId = pendingConsumptionId;
    return true;
  }
}

class _AutoOpenCreateRoutePage extends StatefulWidget {
  const _AutoOpenCreateRoutePage({this.extra});

  final Object? extra;

  @override
  State<_AutoOpenCreateRoutePage> createState() =>
      _AutoOpenCreateRoutePageState();
}

class _AutoOpenCreateRoutePageState extends State<_AutoOpenCreateRoutePage> {
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
      GoRouter.of(
        context,
      ).push(AppRoutes.homeCaloriesEntryCreate, extra: widget.extra);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.shrink());
  }
}

CalorieEntry _entry(String id) {
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

@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
  calorieEntryDeleteFlow,
])
Widget _buildHarness({
  required FakeCalorieLogRepository logRepository,
  required FakeCalorieSettingsRepository settingsRepository,
  required String initialLocation,
  Object? createExtra,
  ProviderContainer? container,
  List<Override> additionalOverrides = const <Override>[],
  bool openCreateFromRoot = false,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    initialExtra: createExtra,
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) {
          if (openCreateFromRoot) {
            return _AutoOpenCreateRoutePage(extra: createExtra);
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
    locale: const Locale('en'),
    routerConfig: router,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );

  if (container != null) {
    return UncontrolledProviderScope(container: container, child: app);
  }

  final providerContainer = ProviderContainer(
    overrides: [
      authStateChangesProvider.overrideWith((ref) => Stream<User?>.value(user)),
      calorieLogRepositoryProvider.overrideWithValue(logRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      ...additionalOverrides,
    ],
  );
  addTearDown(providerContainer.dispose);
  return UncontrolledProviderScope(container: providerContainer, child: app);
}

@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
  calorieEntryDeleteFlow,
])
void main() {
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
  });

  testWidgets('details flow loads and updates the meal window', (
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
    expect(find.byKey(CalorieEntryDetailKeys.ingredientsTable), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(CalorieEntryDetailKeys.mealSelector),
      200,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CalorieEntryDetailKeys.mealSelector));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Snack').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CalorieEntryEditorKeys.saveButton));
    await tester.pumpAndSettle();

    final updated = logRepository.entries.single;
    expect(updated.id, 'entry-1');
    expect(updated.name, 'Skyr');
    expect(updated.mealType, MealType.snack);
  });

  testWidgets('details flow updates the logged diary day', (tester) async {
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

    await tester.scrollUntilVisible(
      find.byKey(CalorieEntryDetailKeys.loggedDayButton),
      200,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CalorieEntryDetailKeys.loggedDayButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('27').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CalorieEntryEditorKeys.saveButton));
    await tester.pumpAndSettle();

    final updated = logRepository.entries.single;
    expect(updated.id, 'entry-day');
    expect(updated.loggedAt.year, 2026);
    expect(updated.loggedAt.month, 2);
    expect(updated.loggedAt.day, 27);
    expect(updated.loggedAt.hour, existing.loggedAt.hour);
    expect(updated.loggedAt.minute, existing.loggedAt.minute);
  });

  testWidgets('prepared meal details view shows ingredient table', (
    tester,
  ) async {
    final existing = _bundleEntry('bundle-1');
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
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CalorieEntryDetailKeys.brandValue), findsOneWidget);
    expect(find.text('Kitchen Club'), findsOneWidget);

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
    final inventoryRepository = _FakeInventoryItemRepository(
      initialItems: <InventoryItem>[_inventoryItem()],
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);
    addTearDown(inventoryRepository.dispose);

    final user = _MockUser();
    when(() => user.uid).thenReturn('user-1');

    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith(
          (ref) => Stream<User?>.value(user),
        ),
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        inventoryItemRepositoryProvider.overrideWithValue(inventoryRepository),
      ],
    );
    addTearDown(container.dispose);
    final inventorySubscription = container.listen(
      inventoryItemsControllerProvider,
      (_, _) {},
    );
    addTearDown(inventorySubscription.close);

    await container.read(inventoryItemsControllerProvider.future);
    final pendingConsumption = await container
        .read(inventoryItemsControllerProvider.notifier)
        .stagePendingConsumption('inventory-1', 2);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        initialLocation: AppRoutes.root,
        createExtra: CalorieEntryCreateArgs(
          prefilledProfile: null,
          inventoryContext: CalorieInventoryCreateContext(
            inventoryItemId: 'inventory-1',
            foodFingerprint: 'milk',
            globalFoodItemId: 'off-milk',
            pendingConsumptionId: pendingConsumption!.id,
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
    await tester.pumpAndSettle();

    expect(
      container.read(inventoryItemsControllerProvider).value?.single.quantity,
      3,
    );
    expect(
      container
          .read(inventoryItemsControllerProvider.notifier)
          .hasPendingConsumption(pendingConsumption.id),
      isTrue,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(
      container.read(inventoryItemsControllerProvider).value?.single.quantity,
      3,
    );
    expect(
      container
          .read(inventoryItemsControllerProvider.notifier)
          .hasPendingConsumption(pendingConsumption.id),
      isFalse,
    );
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
