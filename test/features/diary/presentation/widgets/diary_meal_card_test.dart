import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_entry_nutrition.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_card/diary_expanded_meal_body.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_card/diary_meal_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('uses shared surface card styling', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(seedColor: Colors.green),
        home: Scaffold(
          body: DiaryMealCard(
            section: const DiaryMealSection(
              mealType: MealType.breakfast,
              totalKcal: 120,
              entries: [
                DiaryMealEntry(
                  id: 'oats',
                  mealType: MealType.breakfast,
                  name: 'Oats',
                  totalKcal: 120,
                  totalProtein: 8,
                  totalCarbs: 18,
                  totalFat: 4,
                ),
              ],
            ),
            isExpanded: false,
            onToggle: () {},
            onTapEntry: (_) {},
            onQuickAdd: (_) {},
          ),
        ),
      ),
    );

    final context = tester.element(find.byType(DiaryMealCard));
    final colors = Theme.of(context).colorScheme;

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration == AppQuietSurfaces.cardDecoration(colors),
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Padding &&
            widget.padding == const EdgeInsets.all(AppSpacing.md),
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders section macro totals when entries exist', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(seedColor: Colors.green),
        home: Scaffold(
          body: DiaryMealCard(
            section: const DiaryMealSection(
              mealType: MealType.breakfast,
              totalKcal: 250,
              entries: [
                DiaryMealEntry(
                  id: 'oats',
                  mealType: MealType.breakfast,
                  name: 'Oats',
                  totalKcal: 150,
                  totalProtein: 10,
                  totalCarbs: 25,
                  totalFat: 2,
                ),
                DiaryMealEntry(
                  id: 'shake',
                  mealType: MealType.breakfast,
                  name: 'Shake',
                  totalKcal: 100,
                  totalProtein: 20,
                  totalCarbs: 5,
                  totalFat: 1,
                ),
              ],
            ),
            isExpanded: false,
            onToggle: () {},
            onTapEntry: (_) {},
            onQuickAdd: (_) {},
          ),
        ),
      ),
    );

    // Section total macros: 10+20=30g P, 25+5=30g C, 2+1=3g F
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('P 30g · C 30g · F 3g'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('does not render macro totals when section has no entries', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(seedColor: Colors.green),
        home: Scaffold(
          body: DiaryMealCard(
            section: const DiaryMealSection(
              mealType: MealType.breakfast,
              totalKcal: 0,
              entries: [],
            ),
            isExpanded: false,
            onToggle: () {},
            onTapEntry: (_) {},
            onQuickAdd: (_) {},
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('P 0g'),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'hides entries when collapsed and shows portion size when expanded',
    (tester) async {
    const entry = DiaryMealEntry(
      id: 'oats',
      mealType: MealType.breakfast,
      name: 'Oats',
      totalKcal: 150,
      totalProtein: 10,
      totalCarbs: 25,
      totalFat: 2,
      consumedAmount: 75,
      consumedUnit: ConsumedUnit.grams,
    );

    // Collapsed
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(seedColor: Colors.green),
        home: Scaffold(
          body: DiaryMealCard(
            section: const DiaryMealSection(
              mealType: MealType.breakfast,
              totalKcal: 250,
              entries: [entry],
            ),
            isExpanded: false,
            onToggle: () {},
            onTapEntry: (_) {},
            onQuickAdd: (_) {},
          ),
        ),
      ),
    );

    // Header kcal is visible, but entry item details are collapsed
    expect(find.text('250 kcal'), findsOneWidget);
    expect(find.text('150 kcal'), findsNothing);
    expect(find.text('75 g'), findsNothing);

    // Expanded
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(seedColor: Colors.green),
        home: Scaffold(
          body: DiaryMealCard(
            section: const DiaryMealSection(
              mealType: MealType.breakfast,
              totalKcal: 250,
              entries: [entry],
            ),
            isExpanded: true,
            onToggle: () {},
            onTapEntry: (_) {},
            onQuickAdd: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('150 kcal'), findsOneWidget);
    expect(find.text('75 g'), findsOneWidget);
  });

  testWidgets(
    'renders section footer with targets and emphasis chip when expanded',
    (tester) async {
    const entry = DiaryMealEntry(
      id: 'oats',
      mealType: MealType.breakfast,
      name: 'Oats',
      totalKcal: 150,
      totalProtein: 10,
      totalCarbs: 25,
      totalFat: 2,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(seedColor: Colors.green),
        home: Scaffold(
          body: DiaryMealCard(
            section: const DiaryMealSection(
              mealType: MealType.breakfast,
              totalKcal: 150,
              entries: [entry],
            ),
            macroTargets: const DiaryMacroTargets(
              protein: 100,
              carbs: 200,
              fat: 50,
            ),
            isExpanded: true,
            onToggle: () {},
            onTapEntry: (_) {},
            onQuickAdd: (_) {},
          ),
        ),
      ),
    );

    // 10 / 100 = 10 %, 25 / 200 = 12.5 %, 2 / 50 = 4 %
    expect(find.text('10 % deines Tagesziels'), findsOneWidget);
    expect(find.text('12,5 % deines Tagesziels'), findsOneWidget);
    expect(find.text('4 % deines Tagesziels'), findsOneWidget);

    // Energy: Protein 40, Carbs 100, Fat 18. Total = 158.
    // Carbs leads by (100 - 40) / 158 = 37.9% >= 10% -> Kohlenhydratbetont
    expect(find.text('Kohlenhydratbetont'), findsOneWidget);

    await tester.tap(find.text('Kohlenhydratbetont'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('renders expanded meal entry in a compact two-line structure', (
    tester,
  ) async {
    const entry = DiaryMealEntry(
      id: 'oats',
      mealType: MealType.breakfast,
      name: 'Oatmeal with Berries',
      totalKcal: 250,
      totalProtein: 12,
      totalCarbs: 45,
      totalFat: 4,
      consumedAmount: 100,
      consumedUnit: ConsumedUnit.grams,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(seedColor: Colors.green),
        home: Scaffold(
          body: DiaryMealCard(
            section: const DiaryMealSection(
              mealType: MealType.breakfast,
              totalKcal: 250,
              entries: [entry],
            ),
            isExpanded: true,
            onToggle: () {},
            onTapEntry: (_) {},
            onQuickAdd: (_) {},
          ),
        ),
      ),
    );

    final entryFinder = find.byType(DiaryExpandedMealEntry);
    expect(
      find.descendant(
        of: entryFinder,
        matching: find.text('Oatmeal with Berries'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: entryFinder, matching: find.text('250 kcal')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: entryFinder, matching: find.text('100 g')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: entryFinder,
        matching: find.byType(DiaryEntryNutrition),
      ),
      findsOneWidget,
    );
  });
}
