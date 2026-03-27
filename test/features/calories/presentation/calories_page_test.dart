import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/data/local_image_store.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/calories/data/calorie_entry_image_ref.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/calories_page.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../support/fake_calories_repositories.dart';
import '../../../support/fake_local_image_store.dart';

CalorieEntry _entry(
  String id, {
  required DateTime loggedAt,
  required MealType mealType,
  String name = 'Skyr',
  String? imageUrl,
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
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

CalorieEntry _bundleEntry(
  String id, {
  required DateTime loggedAt,
  required MealType mealType,
  String? imageBase64,
}) {
  return CalorieEntry.bundle(
    id: id,
    userId: 'user-1',
    name: 'Chili',
    imageBase64: imageBase64,
    mealType: mealType,
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

Finder get _pageScrollable => find.byType(Scrollable).first;

Future<void> _scrollUntilVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 300, scrollable: _pageScrollable);
  await tester.pumpAndSettle();
}

void main() {
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
      initialSettings: CalorieGoalSettings(
        dailyKcalGoal: 2200,
        updatedAt: DateTime(today.year, today.month, today.day, 9),
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

  testWidgets('meal add button opens create route with preselected meal', (
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

    await _scrollUntilVisible(
      tester,
      find.byKey(CaloriesPageKeys.sectionAddButton(MealType.breakfast.name)),
    );
    await tester.tap(
      find.byKey(CaloriesPageKeys.sectionAddButton(MealType.breakfast.name)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create:breakfast'), findsOneWidget);
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

    final imageWidget = tester.widget<Image>(imageFinder);
    final provider = imageWidget.image as NetworkImage;
    expect(provider.url, 'https://images.example.com/skyr.jpg');
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

    final imageWidget = tester.widget<Image>(imageFinder);
    final provider = imageWidget.image as NetworkImage;
    expect(provider.url, 'https://images.example.com/beans.jpg');
  });

  testWidgets('renders prepared meal image when bundle entry has imageBase64', (
    tester,
  ) async {
    final today = DateTime.now();
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _bundleEntry(
          'bundle-image-entry',
          loggedAt: DateTime(today.year, today.month, today.day, 12),
          mealType: MealType.lunch,
          imageBase64: base64Encode(<int>[1, 2, 3]),
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
      find.byKey(CaloriesPageKeys.entryTile('bundle-image-entry')),
    );

    final imageFinder = find.byKey(
      CaloriesPageKeys.entryImage('bundle-image-entry'),
    );
    expect(imageFinder, findsOneWidget);

    final imageWidget = tester.widget<Image>(imageFinder);
    expect(imageWidget.image, isA<MemoryImage>());
  });

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
          ),
        ],
      );
      final settingsRepository = FakeCalorieSettingsRepository();
      final localImageStore = FakeLocalImageStore();
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      await localImageStore.saveBytes(
        imageRef: calorieEntryImageRef('bundle-local-image-entry'),
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
      initialSettings: CalorieGoalSettings(
        dailyKcalGoal: 2200,
        updatedAt: DateTime(today.year, today.month, today.day, 9),
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
    expect(find.byKey(CaloriesPageKeys.weekBufferCard), findsOneWidget);
    expect(find.byKey(CaloriesPageKeys.summaryCard), findsOneWidget);
  });
}
