import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/provider/calorie_resolved_goal_provider.dart';
import 'package:yamt/features/diary/application/diary_nutrition_bars_provider.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_nutrition_bars.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../calories/support/fake_calories_repositories.dart';
import '../../support/diary_dashboard_test_support.dart';

void main() {
  final selectedDay = DateTime(2026, 4, 27);

  test('provider totals macros from entries', () async {
    final repository = FakeCalorieLogRepository(
      initialEntries: [
        _entry(
          id: 'breakfast',
          day: selectedDay,
          mealType: MealType.breakfast,
          carbs: 30,
          protein: 12,
          fat: 8,
        ),
        _entry(
          id: 'lunch',
          day: selectedDay,
          mealType: MealType.lunch,
          carbs: 42,
          protein: 28,
          fat: 14,
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(repository),
        resolvedCalorieGoalForDayProvider(
          selectedDay,
        ).overrideWith((ref) => _resolvedGoal(selectedDay, goalKcal: 2400)),
      ],
    );
    addTearDown(repository.dispose);
    addTearDown(container.dispose);

    final subscription = container.listen(
      diaryNutritionBarsDataProvider(selectedDay),
      (_, _) {},
    );
    addTearDown(subscription.close);

    final data = await container.read(
      diaryNutritionBarsDataProvider(selectedDay).future,
    );

    expect(data.carbs, 72);
    expect(data.protein, 40);
    expect(data.fat, 22);
    expect(data.goals.carbs, 270);
    expect(data.goals.protein, 150);
    expect(data.goals.fat, 80);
  });

  testWidgets('zero macro targets render empty progress without throwing', (
    tester,
  ) async {
    await _pumpNutritionBars(
      tester,
      selectedDay: selectedDay,
      data: const DiaryNutritionBarsData(
        carbs: 24,
        protein: 18,
        fat: 9,
        goals: DiaryMacroTargets(carbs: 0, protein: 0, fat: 0),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      tester
          .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .map((widget) => widget.widthFactor),
      everyElement(0),
    );
    expect(find.textContaining('24 / 0g', findRichText: true), findsOneWidget);
    expect(find.textContaining('18 / 0g', findRichText: true), findsOneWidget);
    expect(find.textContaining('9 / 0g', findRichText: true), findsOneWidget);
  });

  testWidgets('embedded mode renders macros without standalone title', (
    tester,
  ) async {
    await _pumpNutritionBars(
      tester,
      selectedDay: selectedDay,
      embedded: true,
      data: const DiaryNutritionBarsData(
        carbs: 24,
        protein: 18,
        fat: 9,
        goals: DiaryMacroTargets(carbs: 120, protein: 90, fat: 45),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Nutrition'), findsNothing);
    expect(
      find.textContaining('24 / 120g', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('18 / 90g', findRichText: true), findsOneWidget);
    expect(find.textContaining('9 / 45g', findRichText: true), findsOneWidget);
  });

  test(
    'provider clamps negative calorie goals to zero macro targets',
    () async {
      final repository = FakeCalorieLogRepository();
      final container = ProviderContainer(
        overrides: [
          calorieLogRepositoryProvider.overrideWithValue(repository),
          resolvedCalorieGoalForDayProvider(
            selectedDay,
          ).overrideWith((ref) => _resolvedGoal(selectedDay, goalKcal: -838)),
        ],
      );
      addTearDown(repository.dispose);
      addTearDown(container.dispose);

      final subscription = container.listen(
        diaryNutritionBarsDataProvider(selectedDay),
        (_, _) {},
      );
      addTearDown(subscription.close);

      final data = await container.read(
        diaryNutritionBarsDataProvider(selectedDay).future,
      );

      expect(data.goals.carbs, 0);
      expect(data.goals.protein, 0);
      expect(data.goals.fat, 0);
    },
  );

  testWidgets('shows retry and reloads after nutrition load error', (
    tester,
  ) async {
    var shouldFail = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          diaryDayDashboardControllerProvider(selectedDay).overrideWith(
            () => FakeDiaryDayDashboardController(
              diaryDashboardErrorStateForTest(StateError('load failed')),
              onRetry: (_) {
                if (shouldFail) {
                  return null;
                }
                return diaryDashboardLoadedStateForTest(
                  selectedDay: selectedDay,
                  nutritionBars: const DiaryNutritionBarsData(
                    carbs: 24,
                    protein: 18,
                    fat: 9,
                    goals: DiaryMacroTargets(
                      carbs: 120,
                      protein: 90,
                      fat: 45,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: DiaryNutritionBars(selectedDay: selectedDay),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nutrition could not be loaded'), findsOneWidget);
    expect(find.byKey(DiaryNutritionBarsKeys.retryButton), findsOneWidget);

    shouldFail = false;
    await tester.tap(find.byKey(DiaryNutritionBarsKeys.retryButton));
    await tester.pumpAndSettle();

    expect(find.text('Nutrition could not be loaded'), findsNothing);
    expect(
      find.textContaining('24 / 120g', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('keeps previous data visible while nutrition reloads', (
    tester,
  ) async {
    final controller = FakeDiaryDayDashboardController(
      diaryDashboardLoadedStateForTest(
        selectedDay: selectedDay,
        nutritionBars: const DiaryNutritionBarsData(
          carbs: 24,
          protein: 18,
          fat: 9,
          goals: DiaryMacroTargets(
            carbs: 120,
            protein: 90,
            fat: 45,
          ),
        ),
      ),
    );
    final container = ProviderContainer(
      overrides: [
        diaryDayDashboardControllerProvider(
          selectedDay,
        ).overrideWith(() => controller),
      ],
    );
    addTearDown(container.dispose);

    await _pumpNutritionBarsWithContainer(
      tester,
      container: container,
      selectedDay: selectedDay,
    );

    expect(
      find.textContaining('24 / 120g', findRichText: true),
      findsOneWidget,
    );

    replaceFakeDiaryDashboardState(
      controller,
      const DiaryDayDashboardState(
        data: null,
        isFromCache: false,
        isRefreshing: true,
        error: null,
      ),
    );
    await tester.pump();

    expect(
      find.textContaining('24 / 120g', findRichText: true),
      findsOneWidget,
    );
  });
}

Future<void> _pumpNutritionBars(
  WidgetTester tester, {
  required DateTime selectedDay,
  required DiaryNutritionBarsData data,
  bool embedded = false,
}) async {
  final nutritionBars = embedded
      ? DiaryNutritionBars.embedded(selectedDay: selectedDay)
      : DiaryNutritionBars(selectedDay: selectedDay);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        diaryDayDashboardControllerProvider(
          selectedDay,
        ).overrideWithValue(
          diaryDashboardLoadedStateForTest(
            selectedDay: selectedDay,
            nutritionBars: data,
          ),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: nutritionBars,
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpNutritionBarsWithContainer(
  WidgetTester tester, {
  required ProviderContainer container,
  required DateTime selectedDay,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: DiaryNutritionBars(selectedDay: selectedDay),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ResolvedCalorieGoalData _resolvedGoal(
  DateTime day, {
  required double goalKcal,
}) {
  return ResolvedCalorieGoalData(
    day: day,
    storedGoalKcal: goalKcal,
    goalKcal: goalKcal,
    activityDeltaKcal: 0,
    lastWeekAverageActiveKcal: 0,
    todayActiveKcal: 0,
    usedLearnedTdee: false,
    usesPreLearningActivityBonus: false,
    wasClampedToMinimum: false,
  );
}

CalorieEntry _entry({
  required String id,
  required DateTime day,
  required MealType mealType,
  required double carbs,
  required double protein,
  required double fat,
}) {
  final loggedAt = day.add(const Duration(hours: 8));
  return CalorieEntry(
    id: id,
    userId: 'user-1',
    name: id,
    mealType: mealType,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 100,
    per100Protein: protein,
    per100Carbs: carbs,
    per100Fat: fat,
    totalKcal: 100,
    totalProtein: protein,
    totalCarbs: carbs,
    totalFat: fat,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}
