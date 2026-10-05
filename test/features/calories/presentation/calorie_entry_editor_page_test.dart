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
    'calorie_inventory_entry_save_handler.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_inventory_create_context.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/presentation/calorie_entry_editor_page.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_editor_content.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../support/fake_calories_repositories.dart';

class _MockUser extends Mock implements User;

class _RecordingInventorySave {
  CalorieEntry? entry;
  String? pendingConsumptionId;

  Future<bool> saveEntry({
    required CalorieEntry entry,
    required String pendingConsumptionId,
  }) async {
    this.entry = entry;
    this.pendingConsumptionId = pendingConsumptionId;
    return true;
  }
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

Widget _buildHarness({
  required FakeCalorieLogRepository logRepository,
  required FakeCalorieSettingsRepository settingsRepository,
  required String initialLocation,
  Object? createExtra,
  ProviderContainer? container,
  List<Override> additionalOverrides = const <Override>[],
  Override? pendingConsumptionDiscarderOverride,
  CalorieInventoryEntrySaveHandler? inventorySaveHandler,
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
    ],
  );

  final user = _MockUser();
  when(() => user.uid).thenReturn('user-1');

  final app = MaterialApp.router(
    locale: const Locale('en'),
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
      calorieInventoryEntrySaveHandlerProvider.overrideWith(
        (ref) =>
            inventorySaveHandler ??
            ({required entry, required pendingConsumptionId}) async => false,
      ),
      pendingConsumptionDiscarderOverride ??
          calorieInventoryPendingConsumptionDiscarderProvider.overrideWith(
            (ref) => (pendingConsumptionId) async {},
          ),
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
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    final discardedPendingConsumptionIds = <String>[];
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
        calorieInventoryPendingConsumptionDiscarderProvider.overrideWith(
          (ref) => (pendingConsumptionId) async {
            discardedPendingConsumptionIds.add(pendingConsumptionId);
          },
        ),
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

    expect(discardedPendingConsumptionIds, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();

    expect(discardedPendingConsumptionIds, ['pending-1']);
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
      final saveFlow = _RecordingInventorySave();
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
          inventorySaveHandler: saveFlow.saveEntry,
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
      final saveFlow = _RecordingInventorySave();
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
          inventorySaveHandler: saveFlow.saveEntry,
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
