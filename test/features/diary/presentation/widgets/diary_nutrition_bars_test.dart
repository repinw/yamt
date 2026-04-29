import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_summary_card_macros.dart';
import 'package:yamt/features/calories/provider/calorie_resolved_goal_provider.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_nutrition_bars.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../calories/support/fake_calories_repositories.dart';

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
        goals: CaloriesSummaryMacroGoals(carbs: 0, protein: 0, fat: 0),
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
}

Future<void> _pumpNutritionBars(
  WidgetTester tester, {
  required DateTime selectedDay,
  required DiaryNutritionBarsData data,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        diaryNutritionBarsDataProvider(
          selectedDay,
        ).overrideWith((ref) async => data),
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
