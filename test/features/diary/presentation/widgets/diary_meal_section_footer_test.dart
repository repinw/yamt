import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_card/diary_meal_section_footer.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  Widget buildApp(
    Widget child, {
    Locale locale = const Locale('de'),
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );
  }

  testWidgets('renders macro values and target percentages', (tester) async {
    const section = DiaryMealSection(
      mealType: MealType.lunch,
      totalKcal: 500,
      entries: [
        DiaryMealEntry(
          id: '1',
          name: 'Chicken Rice',
          mealType: MealType.lunch,
          totalKcal: 500,
          totalProtein: 40,
          totalCarbs: 50,
          totalFat: 15,
        ),
      ],
    );
    const targets = DiaryMacroTargets(protein: 100, carbs: 200, fat: 50);

    await tester.pumpWidget(
      buildApp(
        const DiaryMealSectionFooter(
          section: section,
          macroTargets: targets,
        ),
      ),
    );

    // Protein: 40g (40 %)
    expect(find.text('P 40g'), findsOneWidget);
    expect(find.text('40 % deines Tagesziels'), findsOneWidget);

    // Carbs: 50g (25 %)
    expect(find.text('K 50g'), findsOneWidget);
    expect(find.text('25 % deines Tagesziels'), findsOneWidget);

    // Fat: 15g (30 %)
    expect(find.text('F 15g'), findsOneWidget);
    expect(find.text('30 % deines Tagesziels'), findsOneWidget);
  });

  testWidgets('renders without targets when macroTargets is null', (
    tester,
  ) async {
    const section = DiaryMealSection(
      mealType: MealType.dinner,
      totalKcal: 300,
      entries: [
        DiaryMealEntry(
          id: '1',
          name: 'Salad',
          mealType: MealType.dinner,
          totalKcal: 300,
          totalProtein: 20,
          totalCarbs: 30,
          totalFat: 10,
        ),
      ],
    );

    await tester.pumpWidget(
      buildApp(
        const DiaryMealSectionFooter(
          section: section,
        ),
      ),
    );

    expect(find.text('P 20g'), findsOneWidget);
    expect(find.text('K 30g'), findsOneWidget);
    expect(find.text('F 10g'), findsOneWidget);
    expect(find.textContaining('deines Tagesziels'), findsNothing);
  });

  testWidgets('identifies fat emphasis and opens dialog on tap', (
    tester,
  ) async {
    // Protein 10g * 4 = 40 kcal, Carbs 10g * 4 = 40 kcal,
    // Fat 30g * 9 = 270 kcal. Fat dominates heavily.
    const section = DiaryMealSection(
      mealType: MealType.snack,
      totalKcal: 350,
      entries: [
        DiaryMealEntry(
          id: 'nuts',
          name: 'Nuts',
          mealType: MealType.snack,
          totalKcal: 350,
          totalProtein: 10,
          totalCarbs: 10,
          totalFat: 30,
        ),
      ],
    );

    await tester.pumpWidget(
      buildApp(
        const DiaryMealSectionFooter(
          section: section,
        ),
      ),
    );

    expect(find.text('Fettbetont'), findsOneWidget);

    await tester.tap(find.text('Fettbetont'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('Fett:'), findsOneWidget);
    expect(find.textContaining('Schwerpunkt'), findsOneWidget);

    // Dismiss dialog
    await tester.tap(find.text('Schließen'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('identifies protein emphasis', (tester) async {
    // Protein 50g * 4 = 200 kcal, Carbs 5g * 4 = 20 kcal, Fat 2g * 9 = 18 kcal.
    const section = DiaryMealSection(
      mealType: MealType.lunch,
      totalKcal: 238,
      entries: [
        DiaryMealEntry(
          id: 'shake',
          name: 'Protein Shake',
          mealType: MealType.lunch,
          totalKcal: 238,
          totalProtein: 50,
          totalCarbs: 5,
          totalFat: 2,
        ),
      ],
    );

    await tester.pumpWidget(
      buildApp(
        const DiaryMealSectionFooter(
          section: section,
        ),
      ),
    );

    expect(find.text('Eiweißbetont'), findsOneWidget);
  });
}
