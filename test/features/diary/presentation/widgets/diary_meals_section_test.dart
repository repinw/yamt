import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_bundle_component.dart';
import 'package:yamt/features/calories/domain/quick_calorie_entry.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashed_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_group/diary_meal_group.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_meal_group/diary_meals_skeleton.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../calories/support/fake_planned_entry_repository.dart';
import '../../support/diary_dashboard_test_support.dart';

void main() {
  final selectedDay = DateTime(2026, 4, 27);

  testWidgets('empty day shows a hint instead of meal groups', (tester) async {
    await _pumpMealsSection(
      tester,
      selectedDay: selectedDay,
      sections: [
        for (final mealType in MealType.sectionOrder)
          _mealSection(mealType, const []),
      ],
    );

    expect(find.byType(DiaryMealGroup), findsNothing);
    expect(find.byType(DiaryMealsSkeleton), findsNothing);
    expect(find.byKey(DiaryMealsSectionKeys.emptyState), findsOneWidget);
    expect(find.text('Nothing eaten yet'), findsOneWidget);
  });

  testWidgets('empty future day speaks of planning', (tester) async {
    await _pumpMealsSection(
      tester,
      selectedDay: selectedDay,
      sections: [
        for (final mealType in MealType.sectionOrder)
          _mealSection(mealType, const []),
      ],
      now: selectedDay.subtract(const Duration(hours: 12)),
    );

    expect(find.byKey(DiaryMealsSectionKeys.emptyState), findsOneWidget);
    expect(find.text('Nothing planned yet'), findsOneWidget);
    expect(find.text('Nothing eaten yet'), findsNothing);
  });

  testWidgets('a plan shows below the eaten food; a tap deletes it', (
    tester,
  ) async {
    final plan = buildQuickCalorieEntry(
      id: 'plan',
      userId: 'user-1',
      name: 'Pasta',
      mealType: MealType.dinner,
      loggedAt: selectedDay.add(const Duration(hours: 19)),
      now: selectedDay,
      kcal: 700,
    );
    final repository = FakePlannedEntryRepository(plans: [plan]);
    DiaryMealEntry row(String id, String name) => _entry(
      id: id,
      day: selectedDay,
      mealType: MealType.dinner,
      name: name,
      kcal: 700,
      protein: 0,
      carbs: 0,
      fat: 0,
    );
    await _pumpMealsSection(
      tester,
      selectedDay: selectedDay,
      sections: [
        _mealSection(
          MealType.dinner,
          [row('eaten', 'Soup')],
          plannedEntries: [row('plan', 'Pasta')],
        ),
      ],
      plannedEntries: [plan],
      overrides: [plannedEntryRepositoryProvider.overrideWithValue(repository)],
    );

    final planRow = find.byKey(DiaryMealsSectionKeys.plannedEntryTile('plan'));
    expect(planRow, findsOneWidget);
    expect(
      tester.getTopLeft(planRow).dy,
      greaterThan(
        tester
            .getTopLeft(find.byKey(DiaryMealsSectionKeys.entryTile('eaten')))
            .dy,
      ),
    );

    await tester.tap(planRow);
    await tester.pumpAndSettle();
    expect(repository.plans, isEmpty);
    expect(find.text('Plan deleted'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(repository.plans, [plan]);
  });

  testWidgets('only a plan of a cooked meal carries the Meal Prep tag', (
    tester,
  ) async {
    await _pumpMealsSection(
      tester,
      selectedDay: selectedDay,
      sections: [
        _mealSection(
          MealType.dinner,
          const [],
          plannedEntries: [
            _entry(
              id: 'curry',
              day: selectedDay,
              mealType: MealType.dinner,
              name: 'Curry',
              kcal: 540,
              protein: 0,
              carbs: 0,
              fat: 0,
              bundleConsumedPortions: 1,
              bundleTotalPortions: 5,
            ),
            _entry(
              id: 'bread',
              day: selectedDay,
              mealType: MealType.dinner,
              name: 'Bread',
              kcal: 200,
              protein: 0,
              carbs: 0,
              fat: 0,
            ),
          ],
        ),
      ],
    );

    expect(find.text('MEAL PREP'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(DiaryMealsSectionKeys.plannedEntryTile('curry')),
        matching: find.text('MEAL PREP'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a day with only plans shows them instead of the hint', (
    tester,
  ) async {
    await _pumpMealsSection(
      tester,
      selectedDay: selectedDay,
      sections: [
        _mealSection(
          MealType.lunch,
          const [],
          plannedEntries: [
            _entry(
              id: 'plan',
              day: selectedDay,
              mealType: MealType.lunch,
              name: 'Rice',
              kcal: 400,
              protein: 0,
              carbs: 0,
              fat: 0,
            ),
          ],
        ),
      ],
    );

    expect(find.byKey(DiaryMealsSectionKeys.emptyState), findsNothing);
    expect(
      find.byKey(DiaryMealsSectionKeys.plannedEntryTile('plan')),
      findsOneWidget,
    );
  });

  for (final countsPlans in [true, false]) {
    testWidgets('the meal total adds plans only when they count '
        '(countsPlans: $countsPlans)', (tester) async {
      DiaryMealEntry plan(String id, double kcal) => _entry(
        id: id,
        day: selectedDay,
        mealType: MealType.dinner,
        name: id,
        kcal: kcal,
        protein: 0,
        carbs: 0,
        fat: 0,
      );
      await _pumpMealsSection(
        tester,
        selectedDay: selectedDay,
        sections: [
          _mealSection(
            MealType.dinner,
            const [],
            plannedEntries: [plan('soup', 400), plan('bread', 300)],
            countsPlans: countsPlans,
          ),
        ],
      );

      expect(
        find.text('700 kcal'),
        countsPlans ? findsOneWidget : findsNothing,
      );
      expect(find.text('0 kcal'), findsNothing);
    });
  }

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

    expect(
      find.byKey(DiaryMealsSectionKeys.mealGroup(MealType.breakfast)),
      findsOneWidget,
    );
    // Only the empty day sits between dashed lines.
    expect(find.byType(DiaryDashedSection), findsNothing);
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

  testWidgets('merges identical foods and expands them on tap', (tester) async {
    DiaryMealEntry oats(String id) => _entry(
      id: id,
      day: selectedDay,
      mealType: MealType.lunch,
      name: 'Oats',
      kcal: 75,
      protein: 2,
      carbs: 12,
      fat: 1,
      amount: 20,
    );

    await _pumpMealsSection(
      tester,
      selectedDay: selectedDay,
      sections: [
        _mealSection(MealType.lunch, [
          oats('oats-1'),
          oats('oats-2'),
          oats('oats-3'),
        ]),
      ],
    );

    expect(find.text('Oats'), findsOneWidget);
    expect(find.text('225 kcal'), findsOneWidget);
    expect(find.text('60 g'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel(RegExp('3 entries')), findsOneWidget);
    semantics.dispose();
    expect(find.text('75 kcal'), findsNothing);

    await tester.tap(find.text('Oats'));
    await tester.pumpAndSettle();

    expect(find.text('Oats'), findsNWidgets(4));
    expect(find.text('75 kcal'), findsNWidgets(3));

    await tester.tap(find.text('Oats').first);
    await tester.pumpAndSettle();

    expect(find.text('Oats'), findsOneWidget);
  });

  testWidgets('a combined entry expands to its foods', (tester) async {
    const food = CalorieEntryBundleComponent(
      name: 'Bread',
      amountLabel: '80 g',
      totalKcal: 190,
      totalProtein: 6,
      totalCarbs: 36,
      totalFat: 2,
    );
    final combined = DiaryMealEntry(
      id: 'combined-1',
      mealType: MealType.lunch,
      name: 'Bread + Gouda',
      totalKcal: 407,
      totalProtein: 21,
      totalCarbs: 36,
      totalFat: 19,
      consumedAmount: 100,
      consumedUnit: ConsumedUnit.grams,
      combinedFoods: [
        food,
        food.copyWith(name: 'Gouda', amountLabel: '60 g', totalKcal: 217),
      ],
    );

    await _pumpMealsSection(
      tester,
      selectedDay: selectedDay,
      sections: [
        _mealSection(MealType.lunch, [combined]),
      ],
    );

    expect(find.text('Bread + Gouda'), findsOneWidget);
    expect(find.text('2 foods'), findsOneWidget);
    expect(find.text('100 g'), findsNothing);
    expect(find.text('Gouda'), findsNothing);

    await tester.tap(find.text('Bread + Gouda'));
    await tester.pumpAndSettle();

    expect(find.text('Bread'), findsOneWidget);
    expect(find.text('Gouda'), findsOneWidget);
    expect(find.text('60 g'), findsOneWidget);
    expect(find.text('217 kcal'), findsOneWidget);
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
  DateTime? now,
  List<CalorieEntry> plannedEntries = const [],
  List<Override> overrides = const [],
}) async {
  await _pumpDiaryWidget(
    tester,
    DiaryMealsSection(selectedDay: selectedDay),
    overrides: [
      if (now != null) diaryCalendarNowProvider.overrideWithValue(() => now),
      diaryDayDashboardControllerProvider(selectedDay).overrideWithValue(
        diaryDashboardLoadedStateForTest(
          selectedDay: selectedDay,
          mealSections: sections,
          plannedEntries: plannedEntries,
        ),
      ),
      ...overrides,
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

DiaryMealSection _mealSection(
  MealType mealType,
  List<DiaryMealEntry> entries, {
  List<DiaryMealEntry> plannedEntries = const [],
  bool countsPlans = false,
}) {
  return DiaryMealSection(
    mealType: mealType,
    entries: entries,
    plannedEntries: plannedEntries,
    countsPlans: countsPlans,
    totalKcal: [
      ...entries,
      if (countsPlans) ...plannedEntries,
    ].fold<double>(0, (sum, entry) => sum + entry.totalKcal),
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
  num? bundleConsumedPortions,
  int? bundleTotalPortions,
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
    bundleConsumedPortions: bundleConsumedPortions,
    bundleTotalPortions: bundleTotalPortions,
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
