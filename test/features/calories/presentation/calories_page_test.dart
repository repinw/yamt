import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/calories_page.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/provider/calorie_day_controller.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../support/fake_calories_repositories.dart';
import '../../../helpers/memory_app_preferences.dart';
import '../../../support/fake_local_image_store.dart';

CalorieEntry _entry(
  String id, {
  required DateTime loggedAt,
  required MealType mealType,
  String name = 'Skyr',
  String? imageUrl,
  String? sourceInventoryItemId,
  int? sourceInventoryAmountToRestore,
}) {
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: name,
    imageUrl: imageUrl,
    mealType: mealType,
    consumedAmount: 200,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 100,
    per100Protein: 10,
    per100Carbs: 5,
    per100Fat: 1,
    sourceInventoryItemId: sourceInventoryItemId,
    sourceInventoryAmountToRestore: sourceInventoryAmountToRestore,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

CalorieEntry _bundleEntry(
  String id, {
  required DateTime loggedAt,
  required MealType mealType,
  String? imageAssetId,
  List<CalorieEntryBundleComponent>? bundleComponents,
}) {
  return CalorieEntry.bundle(
    id: id,
    userId: 'user-1',
    name: 'Chili',
    imageAssetId: imageAssetId,
    mealType: mealType,
    totalKcal: 420,
    totalProtein: 28,
    totalCarbs: 35,
    totalFat: 18,
    bundleSourcePreparedMealId: 'prepared-1',
    bundleConsumedPortions: 2,
    bundleTotalPortions: 4,
    bundleComponents:
        bundleComponents ??
        const [
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
        ],
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

Widget _buildHarness({
  required FakeCalorieLogRepository logRepository,
  required FakeCalorieSettingsRepository settingsRepository,
  List<dynamic> overrides = const <dynamic>[],
}) {
  final router = GoRouter(
    initialLocation: AppRoutes.homeCalories,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.homeCalories,
        builder: (context, state) => const Scaffold(body: CaloriesPage()),
      ),
      GoRoute(
        path: AppRoutes.homeCaloriesEntryCreate,
        builder: (context, state) {
          final args = state.extra is CalorieEntryCreateArgs
              ? state.extra! as CalorieEntryCreateArgs
              : null;
          final mealType = args?.preselectedMealType?.name ?? 'none';
          return Scaffold(body: Text('Create:$mealType'));
        },
      ),
      GoRoute(
        path: AppRoutes.homeCaloriesEntryEdit,
        builder: (context, state) => const Scaffold(body: Text('Edit')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      calorieLogRepositoryProvider.overrideWithValue(logRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      ...overrides,
    ],
    child: MaterialApp.router(
      locale: const Locale('en'),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

Widget _buildHarnessWithContainer({required ProviderContainer container}) {
  final router = GoRouter(
    initialLocation: AppRoutes.homeCalories,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.homeCalories,
        builder: (context, state) => const Scaffold(body: CaloriesPage()),
      ),
      GoRoute(
        path: AppRoutes.homeCaloriesEntryCreate,
        builder: (context, state) {
          final args = state.extra is CalorieEntryCreateArgs
              ? state.extra! as CalorieEntryCreateArgs
              : null;
          final mealType = args?.preselectedMealType?.name ?? 'none';
          return Scaffold(body: Text('Create:$mealType'));
        },
      ),
      GoRoute(
        path: AppRoutes.homeCaloriesEntryEdit,
        builder: (context, state) => const Scaffold(body: Text('Edit')),
      ),
    ],
  );

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      locale: const Locale('en'),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

class _FakePreparedMealRepository implements PreparedMealRepository {
  @override
  Future<List<PreparedMeal>> readAll() async => const <PreparedMeal>[];

  @override
  Future<bool> saveAll(List<PreparedMeal> meals) async => true;

  @override
  Stream<List<PreparedMeal>> watchAll() {
    return Stream<List<PreparedMeal>>.value(const <PreparedMeal>[]);
  }
}

Finder get _pageScrollable => find.byType(Scrollable).first;

Future<void> _scrollUntilVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 300, scrollable: _pageScrollable);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows loading indicator while entries are loading', (
    tester,
  ) async {
    final logRepository = FakeCalorieLogRepository()
      ..initialEmissionDelay = const Duration(seconds: 1);
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(CaloriesPageKeys.summaryCard), findsNothing);
  });

  testWidgets('shows error state and retries loading entries', (tester) async {
    final today = DateTime.now();
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'retry-entry',
          loggedAt: DateTime(today.year, today.month, today.day, 8),
          mealType: MealType.breakfast,
          name: 'Retry entry',
        ),
      ],
    )..watchError = StateError('permission denied');
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pump();

    expect(find.text('Could not load calorie entries.'), findsOneWidget);
    expect(find.byKey(CaloriesPageKeys.retryButton), findsOneWidget);

    logRepository.watchError = null;
    await tester.tap(find.byKey(CaloriesPageKeys.retryButton));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(CaloriesPageKeys.summaryCard), findsOneWidget);
    await _scrollUntilVisible(
      tester,
      find.byKey(CaloriesPageKeys.entryTile('retry-entry')),
    );
    expect(
      find.byKey(CaloriesPageKeys.entryTile('retry-entry')),
      findsOneWidget,
    );
  });

  testWidgets('renders redesigned diary summary and meal sections', (
    tester,
  ) async {
    final today = DateTime.now();
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'b-1',
          loggedAt: DateTime(today.year, today.month, today.day, 8),
          mealType: MealType.breakfast,
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: DateTime(today.year, today.month, today.day, 9),
      ),
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CaloriesPageKeys.summaryCard), findsOneWidget);
    expect(find.byKey(CaloriesPageKeys.weekStrip), findsOneWidget);
    await _scrollUntilVisible(
      tester,
      find.byKey(CaloriesPageKeys.weekBufferCard),
    );
    expect(find.byKey(CaloriesPageKeys.weekBufferCard), findsOneWidget);
    await _scrollUntilVisible(
      tester,
      find.byKey(CaloriesPageKeys.sectionCard(MealType.breakfast.name)),
    );
    expect(
      find.byKey(CaloriesPageKeys.sectionCard(MealType.breakfast.name)),
      findsOneWidget,
    );
    expect(find.text('Skyr'), findsOneWidget);
  });

  testWidgets(
    'defaults to balance mode first and persists a switch to classic',
    (tester) async {
      final today = DateTime.now();
      final preferences = MemoryAppPreferences();
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _entry(
            'b-1',
            loggedAt: DateTime(today.year, today.month, today.day, 8),
            mealType: MealType.breakfast,
          ),
        ],
      );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2200,
          calculatorProfile: null,
          effectiveDate: DateTime(today.year, today.month, today.day, 9),
        ),
      );
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      await tester.pumpWidget(
        _buildHarness(
          logRepository: logRepository,
          settingsRepository: settingsRepository,
          overrides: [appPreferencesProvider.overrideWithValue(preferences)],
        ),
      );
      await tester.pumpAndSettle();

      final balanceModeFinder = find.byKey(
        CaloriesPageKeys.summaryModeOption('balance'),
      );
      final classicModeFinder = find.byKey(
        CaloriesPageKeys.summaryModeOption('classic'),
      );

      expect(find.byKey(CaloriesPageKeys.summaryBalanceBar), findsOneWidget);
      expect(
        tester.getCenter(balanceModeFinder).dx,
        lessThan(tester.getCenter(classicModeFinder).dx),
      );

      await tester.tap(classicModeFinder);
      await tester.pumpAndSettle();

      expect(find.byKey(CaloriesPageKeys.summaryBalanceBar), findsNothing);
      expect(
        await preferences.getString('calories_summary_view_mode'),
        'classic',
      );

      await tester.pumpWidget(
        _buildHarness(
          logRepository: logRepository,
          settingsRepository: settingsRepository,
          overrides: [appPreferencesProvider.overrideWithValue(preferences)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(CaloriesPageKeys.summaryBalanceBar), findsNothing);
    },
  );

  testWidgets('keeps diary visible while switching days', (tester) async {
    final today = DateTime.now();
    final currentDay = DateTime(today.year, today.month, today.day);
    final previousDay = currentDay.subtract(const Duration(days: 1));
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'today-entry',
          loggedAt: DateTime(
            currentDay.year,
            currentDay.month,
            currentDay.day,
            8,
          ),
          mealType: MealType.breakfast,
          name: 'Today entry',
        ),
        _entry(
          'previous-entry',
          loggedAt: DateTime(
            previousDay.year,
            previousDay.month,
            previousDay.day,
            8,
          ),
          mealType: MealType.breakfast,
          name: 'Previous entry',
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository();
    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildHarnessWithContainer(container: container));
    await tester.pumpAndSettle();

    expect(find.byKey(CaloriesPageKeys.summaryCard), findsOneWidget);
    expect(find.byKey(CaloriesPageKeys.weekStrip), findsOneWidget);

    logRepository.initialEmissionDelay = const Duration(seconds: 1);
    container.read(calorieDayControllerProvider.notifier).setDay(previousDay);
    await tester.pump();

    expect(find.byKey(CaloriesPageKeys.summaryCard), findsOneWidget);
    expect(find.byKey(CaloriesPageKeys.weekStrip), findsOneWidget);
    expect(
      find.byKey(CaloriesPageKeys.reloadProgressIndicator),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    await _scrollUntilVisible(
      tester,
      find.byKey(CaloriesPageKeys.entryTile('previous-entry')),
    );
    expect(
      find.byKey(CaloriesPageKeys.entryTile('previous-entry')),
      findsOneWidget,
    );
  });

  testWidgets('delete action removes entry after confirmation', (tester) async {
    final today = DateTime.now();
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'delete-me',
          loggedAt: DateTime(today.year, today.month, today.day, 8),
          mealType: MealType.breakfast,
          name: 'Delete Me',
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pumpAndSettle();

    await _scrollUntilVisible(
      tester,
      find.byKey(CaloriesPageKeys.entryTile('delete-me')),
    );
    await tester.longPress(find.byKey(CaloriesPageKeys.entryTile('delete-me')));
    await tester.pumpAndSettle();

    expect(find.text('Delete entry?'), findsOneWidget);

    final dialogDeleteButton = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(TextButton, 'Delete'),
    );
    await tester.tap(dialogDeleteButton);
    await tester.pumpAndSettle();

    expect(find.text('Delete Me'), findsNothing);
    expect(
      logRepository.entries.where((entry) => entry.id == 'delete-me'),
      isEmpty,
    );
  });

  testWidgets('delete dialog asks about returning inventory food', (
    tester,
  ) async {
    final today = DateTime.now();
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'inventory-delete',
          loggedAt: DateTime(today.year, today.month, today.day, 8),
          mealType: MealType.breakfast,
          name: 'Inventory Milk',
          sourceInventoryItemId: 'inventory-1',
          sourceInventoryAmountToRestore: 250,
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pumpAndSettle();

    await _scrollUntilVisible(
      tester,
      find.byKey(CaloriesPageKeys.entryTile('inventory-delete')),
    );
    await tester.longPress(
      find.byKey(CaloriesPageKeys.entryTile('inventory-delete')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add the food back to inventory?'), findsOneWidget);
    expect(
      find.byKey(CaloriesPageKeys.deleteRestoreCheckbox('inventory-delete')),
      findsOneWidget,
    );
  });

  testWidgets('bundle delete dialog returns meal to inventory', (tester) async {
    final today = DateTime.now();
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _bundleEntry(
          'bundle-delete',
          loggedAt: DateTime(today.year, today.month, today.day, 12),
          mealType: MealType.lunch,
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        overrides: [
          preparedMealRepositoryProvider.overrideWithValue(
            _FakePreparedMealRepository(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await _scrollUntilVisible(
      tester,
      find.byKey(CaloriesPageKeys.entryTile('bundle-delete')),
    );
    await tester.longPress(
      find.byKey(CaloriesPageKeys.entryTile('bundle-delete')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Return meal to inventory?'), findsOneWidget);
    expect(
      find.text('Return "Chili" to inventory and remove it from the diary?'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextButton, 'Return to inventory'),
      findsOneWidget,
    );
  });

  testWidgets('does not render meal add buttons in diary sections', (
    tester,
  ) async {
    final today = DateTime.now();
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'goal',
          loggedAt: DateTime(today.year, today.month, today.day, 8),
          mealType: MealType.breakfast,
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(CaloriesPageKeys.sectionAddButton(MealType.breakfast.name)),
      findsNothing,
    );
  });

  testWidgets('renders product image when diary entry has imageUrl', (
    tester,
  ) async {
    final today = DateTime.now();
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'image-entry',
          loggedAt: DateTime(today.year, today.month, today.day, 8),
          mealType: MealType.breakfast,
          imageUrl: 'https://images.example.com/skyr.jpg',
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pumpAndSettle();

    await _scrollUntilVisible(
      tester,
      find.byKey(CaloriesPageKeys.entryTile('image-entry')),
    );

    final imageFinder = find.byKey(CaloriesPageKeys.entryImage('image-entry'));
    expect(imageFinder, findsOneWidget);

    final imageWidget = tester.widget<AppCachedNetworkImage>(imageFinder);
    expect(imageWidget.imageUrl, 'https://images.example.com/skyr.jpg');
  });

  testWidgets('renders ingredient image in bundle details sheet', (
    tester,
  ) async {
    final today = DateTime.now();
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _bundleEntry(
          'bundle-entry',
          loggedAt: DateTime(today.year, today.month, today.day, 12),
          mealType: MealType.lunch,
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pumpAndSettle();

    await _scrollUntilVisible(
      tester,
      find.byKey(CaloriesPageKeys.entryTile('bundle-entry')),
    );
    await tester.tap(find.byKey(CaloriesPageKeys.entryTile('bundle-entry')));
    await tester.pumpAndSettle();

    final imageFinder = find.byKey(
      CaloriesPageKeys.bundleComponentImage('bundle-entry', 0),
    );
    expect(imageFinder, findsOneWidget);

    final imageWidget = tester.widget<AppCachedNetworkImage>(imageFinder);
    expect(imageWidget.imageUrl, 'https://images.example.com/beans.jpg');
  });

  testWidgets(
    'renders prepared meal image when bundle entry has imageAssetId',
    (tester) async {
      final today = DateTime.now();
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _bundleEntry(
            'bundle-image-entry',
            loggedAt: DateTime(today.year, today.month, today.day, 12),
            mealType: MealType.lunch,
            imageAssetId: 'asset-bundle-image-entry',
          ),
        ],
      );
      final settingsRepository = FakeCalorieSettingsRepository();
      final localImageStore = FakeLocalImageStore();
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      await localImageStore.saveBytes(
        imageRef: localImageAssetRef('asset-bundle-image-entry'),
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
      );

      await tester.pumpWidget(
        _buildHarness(
          logRepository: logRepository,
          settingsRepository: settingsRepository,
          overrides: [
            localImageStoreProvider.overrideWithValue(localImageStore),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await _scrollUntilVisible(
        tester,
        find.byKey(CaloriesPageKeys.entryTile('bundle-image-entry')),
      );

      final imageFinder = find.byKey(
        CaloriesPageKeys.entryImage('bundle-image-entry'),
      );
      expect(imageFinder, findsOneWidget);

      final imageWidget = tester.widget<Image>(imageFinder);
      expect(imageWidget.image, isA<MemoryImage>());
    },
  );

  testWidgets(
    'renders prepared meal image from local device storage for bundle entry',
    (tester) async {
      final today = DateTime.now();
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _bundleEntry(
            'bundle-local-image-entry',
            loggedAt: DateTime(today.year, today.month, today.day, 12),
            mealType: MealType.lunch,
            imageAssetId: 'asset-bundle-local-image-entry',
          ),
        ],
      );
      final settingsRepository = FakeCalorieSettingsRepository();
      final localImageStore = FakeLocalImageStore();
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      await localImageStore.saveBytes(
        imageRef: localImageAssetRef('asset-bundle-local-image-entry'),
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
      );

      await tester.pumpWidget(
        _buildHarness(
          logRepository: logRepository,
          settingsRepository: settingsRepository,
          overrides: [
            localImageStoreProvider.overrideWithValue(localImageStore),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await _scrollUntilVisible(
        tester,
        find.byKey(CaloriesPageKeys.entryTile('bundle-local-image-entry')),
      );

      final imageFinder = find.byKey(
        CaloriesPageKeys.entryImage('bundle-local-image-entry'),
      );
      expect(imageFinder, findsOneWidget);

      final imageWidget = tester.widget<Image>(imageFinder);
      expect(imageWidget.image, isA<MemoryImage>());
    },
  );

  testWidgets('bundle details sheet does not overflow on small screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 520);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final today = DateTime.now();
    final components = List<CalorieEntryBundleComponent>.generate(
      8,
      (index) => CalorieEntryBundleComponent(
        name: 'Ingredient $index',
        amountLabel: '${100 + index * 10} g',
        brand: 'Brand $index',
        imageUrl: 'https://images.example.com/item_$index.jpg',
        totalKcal: 50 + index.toDouble(),
        totalProtein: 5,
        totalCarbs: 6,
        totalFat: 2,
      ),
    );
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _bundleEntry(
          'overflow-bundle-entry',
          loggedAt: DateTime(today.year, today.month, today.day, 12),
          mealType: MealType.lunch,
          bundleComponents: components,
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pumpAndSettle();

    await _scrollUntilVisible(
      tester,
      find.byKey(CaloriesPageKeys.entryTile('overflow-bundle-entry')),
    );
    await tester.tap(
      find.byKey(CaloriesPageKeys.entryTile('overflow-bundle-entry')),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders empty state text for meal sections without entries', (
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
      ),
    );
    await tester.pumpAndSettle();

    await _scrollUntilVisible(
      tester,
      find.byKey(CaloriesPageKeys.sectionCard(MealType.breakfast.name)),
    );

    expect(find.text('No entries yet.'), findsWidgets);
  });

  testWidgets('falls back to zeroed week overview when provider errors', (
    tester,
  ) async {
    final today = DateTime.now();
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'b-1',
          loggedAt: DateTime(today.year, today.month, today.day, 8),
          mealType: MealType.breakfast,
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: DateTime(today.year, today.month, today.day, 9),
      ),
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        overrides: <dynamic>[
          calorieWeekOverviewProvider.overrideWith(
            (ref) async => throw StateError('week overview failed'),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CaloriesPageKeys.weekStrip), findsOneWidget);
    expect(find.byKey(CaloriesPageKeys.summaryCard), findsOneWidget);
    await _scrollUntilVisible(
      tester,
      find.byKey(CaloriesPageKeys.weekBufferCard),
    );
    expect(find.byKey(CaloriesPageKeys.weekBufferCard), findsOneWidget);
  });
}
