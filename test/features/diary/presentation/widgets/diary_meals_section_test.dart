import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section.dart';
import 'package:yamt/features/diary/provider/diary_meal_sections_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  final selectedDay = DateTime(2026, 4, 27);

  testWidgets('renders meal categories from provider data', (tester) async {
    await _pumpMealsSection(
      tester,
      selectedDay: selectedDay,
      sections: [
        _mealSection(MealType.breakfast, [
          _entry(
            id: 'oats',
            day: selectedDay,
            mealType: MealType.breakfast,
            name: 'Oats',
            kcal: 100,
            protein: 8,
            carbs: 40,
            fat: 6,
          ),
          _entry(
            id: 'yogurt',
            day: selectedDay,
            mealType: MealType.breakfast,
            name: 'Yogurt',
            kcal: 150,
            protein: 12,
            carbs: 15,
            fat: 4,
          ),
        ]),
        _mealSection(MealType.lunch, const []),
        _mealSection(MealType.dinner, [
          _entry(
            id: 'pasta',
            day: selectedDay,
            mealType: MealType.dinner,
            name: 'Pasta',
            kcal: 400,
            protein: 18,
            carbs: 70,
            fat: 16,
          ),
          _entry(
            id: 'salad',
            day: selectedDay,
            mealType: MealType.dinner,
            name: 'Salad',
            kcal: 120,
            protein: 4,
            carbs: 9,
            fat: 8,
          ),
        ]),
        _mealSection(MealType.snack, const []),
      ],
    );

    expect(find.text('Diary'), findsOneWidget);
    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Dinner'), findsOneWidget);
    expect(find.text('Snack'), findsOneWidget);
    expect(find.text('Oats'), findsOneWidget);
    expect(find.text('Pasta'), findsOneWidget);
    expect(find.text('250 kcal'), findsOneWidget);
    expect(find.text('520 kcal'), findsOneWidget);
    expect(find.text('Nothing logged yet'), findsNWidgets(2));
  });

  testWidgets('switches empty meal from collapsed to expanded state', (
    tester,
  ) async {
    await _pumpMealsSection(
      tester,
      selectedDay: selectedDay,
      sections: [
        for (final mealType in MealType.sectionOrder)
          _mealSection(mealType, const []),
      ],
    );

    expect(
      find.byKey(DiaryMealsSectionKeys.collapsedEmpty(MealType.lunch)),
      findsOneWidget,
    );
    expect(
      find.byKey(DiaryMealsSectionKeys.expandedEmpty(MealType.lunch)),
      findsNothing,
    );

    await tester.tap(find.text('Lunch'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(DiaryMealsSectionKeys.collapsedEmpty(MealType.lunch)),
      findsNothing,
    );
    expect(
      find.byKey(DiaryMealsSectionKeys.expandedEmpty(MealType.lunch)),
      findsOneWidget,
    );
  });

  testWidgets('expands and collapses meal entry details', (tester) async {
    await _pumpMealsSection(
      tester,
      selectedDay: selectedDay,
      sections: [
        _mealSection(MealType.breakfast, [
          _entry(
            id: 'ice-cream',
            day: selectedDay,
            mealType: MealType.breakfast,
            name: 'Ice cream',
            kcal: 100,
            protein: 2,
            carbs: 12,
            fat: 5,
          ),
        ]),
        _mealSection(MealType.lunch, const []),
        _mealSection(MealType.dinner, const []),
        _mealSection(MealType.snack, const []),
      ],
    );

    expect(find.text('12g'), findsNothing);

    await tester.tap(find.text('Breakfast'));
    await tester.pumpAndSettle();

    expect(find.text('12g'), findsOneWidget);
    expect(find.text('2g'), findsOneWidget);
    expect(find.text('5g'), findsOneWidget);

    await tester.tap(find.text('Breakfast'));
    await tester.pumpAndSettle();

    expect(find.text('12g'), findsNothing);
    expect(find.text('2g'), findsNothing);
    expect(find.text('5g'), findsNothing);
  });

  testWidgets('shows retry and reloads after meals load error', (
    tester,
  ) async {
    var shouldFail = true;
    await _pumpDiaryWidget(
      tester,
      DiaryMealsSection(selectedDay: selectedDay),
      overrides: [
        diaryMealSectionsProvider(selectedDay).overrideWith((ref) async {
          if (shouldFail) {
            throw StateError('load failed');
          }
          return [
            _mealSection(MealType.breakfast, [
              _entry(
                id: 'oats',
                day: selectedDay,
                mealType: MealType.breakfast,
                name: 'Oats',
                kcal: 100,
                protein: 8,
                carbs: 40,
                fat: 6,
              ),
            ]),
            _mealSection(MealType.lunch, const []),
            _mealSection(MealType.dinner, const []),
            _mealSection(MealType.snack, const []),
          ];
        }),
      ],
    );

    expect(find.text('Meals could not be loaded'), findsOneWidget);
    expect(find.byKey(DiaryMealsSectionKeys.retryButton), findsOneWidget);

    shouldFail = false;
    await tester.tap(find.byKey(DiaryMealsSectionKeys.retryButton));
    await tester.pumpAndSettle();

    expect(find.text('Meals could not be loaded'), findsNothing);
    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('Oats'), findsOneWidget);
  });
}

Future<void> _pumpMealsSection(
  WidgetTester tester, {
  required DateTime selectedDay,
  required List<CalorieMealSection> sections,
}) async {
  await _pumpDiaryWidget(
    tester,
    DiaryMealsSection(selectedDay: selectedDay),
    overrides: [
      diaryMealSectionsProvider(
        selectedDay,
      ).overrideWith((ref) async => sections),
    ],
  );
}

CalorieMealSection _mealSection(
  MealType mealType,
  List<CalorieEntry> entries,
) {
  return CalorieMealSection(
    mealType: mealType,
    entries: entries,
    totalKcal: entries.fold<double>(
      0,
      (sum, entry) => sum + entry.totalKcal,
    ),
  );
}

CalorieEntry _entry({
  required String id,
  required DateTime day,
  required MealType mealType,
  required String name,
  required double kcal,
  required double protein,
  required double carbs,
  required double fat,
}) {
  return CalorieEntry(
    id: id,
    userId: 'user-1',
    name: name,
    mealType: mealType,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: kcal,
    per100Protein: protein,
    per100Carbs: carbs,
    per100Fat: fat,
    totalKcal: kcal,
    totalProtein: protein,
    totalCarbs: carbs,
    totalFat: fat,
    loggedAt: day.add(const Duration(hours: 8)),
    createdAt: day.add(const Duration(hours: 8)),
    updatedAt: day.add(const Duration(hours: 8)),
  );
}

Future<void> _pumpDiaryWidget(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
