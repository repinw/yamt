import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
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
    'renders portion size under calories when collapsed and expanded',
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

    expect(find.text('150 kcal'), findsOneWidget);
    expect(find.text('75 g'), findsOneWidget);

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
}
