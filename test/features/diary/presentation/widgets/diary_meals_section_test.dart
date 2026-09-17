import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/diary_quick_eat_flow.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_group/diary_meal_group.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_meal_group/diary_meals_skeleton.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../support/diary_dashboard_test_support.dart';

void main() {
  final selectedDay = DateTime(2026, 4, 27);

  testWidgets('empty day shows only large quick-eat buttons', (tester) async {
    await _pumpMealsSection(
      tester,
      selectedDay: selectedDay,
      sections: [
        for (final mealType in MealType.sectionOrder)
          _mealSection(mealType, const []),
      ],
    );

    for (final source in DiaryQuickEatSource.values) {
      expect(
        find.byKey(DiaryMealsSectionKeys.quickEatSource(source)),
        findsOneWidget,
      );
    }
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('Barcode'), findsOneWidget);
    expect(find.byType(DiaryMealGroup), findsNothing);
  });

  testWidgets('logged meals render groups with readable entry rows', (
    tester,
  ) async {
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
            amount: 80,
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
        ]),
        _mealSection(MealType.snack, const []),
      ],
    );

    // Buttons shrink to emoji only once food is logged.
    expect(find.text('Inventory'), findsNothing);
    expect(
      find.byKey(
        DiaryMealsSectionKeys.quickEatSource(DiaryQuickEatSource.inventory),
      ),
      findsOneWidget,
    );

    expect(
      find.byKey(DiaryMealsSectionKeys.mealGroup(MealType.breakfast)),
      findsOneWidget,
    );
    expect(
      find.byKey(DiaryMealsSectionKeys.mealGroup(MealType.dinner)),
      findsOneWidget,
    );
    expect(find.text('Lunch'), findsNothing);
    expect(find.text('Snack'), findsNothing);

    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('250 kcal'), findsOneWidget);
    // Dinner has one food, so its heading repeats no kcal.
    expect(find.text('Dinner'), findsOneWidget);
    expect(find.text('400 kcal'), findsOneWidget);
    expect(find.text('P 20g · C 55g · F 10g'), findsNothing);

    final oats = find.byKey(DiaryMealsSectionKeys.entryTile('oats'));
    expect(
      find.descendant(of: oats, matching: find.text('Oats')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: oats, matching: find.text('100 kcal')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: oats, matching: find.text('P 8g · C 40g · F 6g')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: oats, matching: find.text('80 g')),
      findsOneWidget,
    );

    final yogurt = find.byKey(DiaryMealsSectionKeys.entryTile('yogurt'));
    expect(
      find.descendant(of: yogurt, matching: find.textContaining(' g')),
      findsNothing,
    );
    expect(find.text('Pasta'), findsOneWidget);
  });

  testWidgets('shows retry and reloads after meals load error', (tester) async {
    var shouldFail = true;
    await _pumpDiaryWidget(
      tester,
      DiaryMealsSection(selectedDay: selectedDay),
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
                mealSections: [
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
                ],
              );
            },
          ),
        ),
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

  testWidgets('keeps previous meals visible while meals reload', (
    tester,
  ) async {
    final controller = FakeDiaryDayDashboardController(
      diaryDashboardLoadedStateForTest(
        selectedDay: selectedDay,
        mealSections: [
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
        ],
      ),
    );
    final container = ProviderContainer(
      overrides: [
        diaryDayDashboardControllerProvider(selectedDay)
            .overrideWith(() => controller),
      ],
    );
    addTearDown(container.dispose);

    await _pumpMealsSectionWithContainer(
      tester,
      container: container,
      selectedDay: selectedDay,
    );

    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('Oats'), findsOneWidget);

    replaceFakeDiaryDashboardState(
      controller,
      controller.state.copyWith(isRefreshing: true),
    );
    await tester.pump();

    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('Oats'), findsOneWidget);
    expect(find.byType(DiaryMealsSkeleton), findsNothing);
  });
}

Future<void> _pumpMealsSection(
  WidgetTester tester, {
  required DateTime selectedDay,
  required List<DiaryMealSection> sections,
}) async {
  await _pumpDiaryWidget(
    tester,
    DiaryMealsSection(selectedDay: selectedDay),
    overrides: [
      diaryDayDashboardControllerProvider(selectedDay).overrideWithValue(
        diaryDashboardLoadedStateForTest(
          selectedDay: selectedDay,
          mealSections: sections,
        ),
      ),
    ],
  );
}

Future<void> _pumpMealsSectionWithContainer(
  WidgetTester tester, {
  required ProviderContainer container,
  required DateTime selectedDay,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DiaryMealsSection(selectedDay: selectedDay),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

DiaryMealSection _mealSection(MealType mealType, List<DiaryMealEntry> entries) {
  return DiaryMealSection(
    mealType: mealType,
    entries: entries,
    totalKcal: entries.fold<double>(0, (sum, entry) => sum + entry.totalKcal),
  );
}

DiaryMealEntry _entry({
  required String id,
  required DateTime day,
  required MealType mealType,
  required String name,
  required double kcal,
  required double protein,
  required double carbs,
  required double fat,
  double? amount,
}) {
  return DiaryMealEntry(
    id: id,
    name: name,
    mealType: mealType,
    totalKcal: kcal,
    totalProtein: protein,
    totalCarbs: carbs,
    totalFat: fat,
    consumedAmount: amount,
    consumedUnit: amount == null ? null : ConsumedUnit.grams,
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
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
