import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/nutrition_facts.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/eat_meal_nutrition.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_meal_table.dart';
import 'package:yamt/l10n/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester,
  EatMealNutrition meal, {
  int portions = 1,
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: EatMealTable(meal: meal, portions: portions),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows per 100 g and the total of all foods', (tester) async {
    await _pump(
      tester,
      EatMealNutrition.combine(const [
        (
          eaten: NutritionFacts(kcal: 200, sugar: 2),
          amount: 50,
          unit: ConsumedUnit.grams,
        ),
        (
          eaten: NutritionFacts(kcal: 100, sugar: 4),
          amount: 150,
          unit: ConsumedUnit.grams,
        ),
      ]),
    );

    expect(find.text('Per 100 g'), findsOneWidget);
    expect(find.text('total 200\u00A0g'), findsOneWidget);
    expect(find.text('3 g'), findsOneWidget);
    expect(find.text('6 g'), findsOneWidget);
  });

  testWidgets('shows one portion when the meal makes several', (tester) async {
    await _pump(
      tester,
      EatMealNutrition.combine(const [
        (
          eaten: NutritionFacts(kcal: 200, sugar: 2),
          amount: 50,
          unit: ConsumedUnit.grams,
        ),
        (
          eaten: NutritionFacts(kcal: 100, sugar: 4),
          amount: 150,
          unit: ConsumedUnit.grams,
        ),
      ]),
      portions: 4,
    );

    expect(find.text('per portion 50\u00A0g'), findsOneWidget);
    expect(find.text('Per 100 g'), findsOneWidget);
    expect(find.textContaining('75 kcal'), findsOneWidget);
    expect(find.text('1.5 g'), findsOneWidget);
  });

  testWidgets('shows a dash for a nutrient one food lacks', (tester) async {
    await _pump(
      tester,
      EatMealNutrition.combine(const [
        (
          eaten: NutritionFacts(kcal: 200, sugar: 2),
          amount: 50,
          unit: ConsumedUnit.grams,
        ),
        (
          eaten: NutritionFacts(kcal: 100),
          amount: 150,
          unit: ConsumedUnit.grams,
        ),
      ]),
    );

    expect(find.text('–'), findsNWidgets(2));
  });

  testWidgets('drops per 100 when grams and milliliters mix', (tester) async {
    await _pump(
      tester,
      EatMealNutrition.combine(const [
        (
          eaten: NutritionFacts(kcal: 128),
          amount: 200,
          unit: ConsumedUnit.milliliters,
        ),
        (
          eaten: NutritionFacts(kcal: 186),
          amount: 50,
          unit: ConsumedUnit.grams,
        ),
      ]),
    );

    expect(find.textContaining('Per 100'), findsNothing);
    expect(find.text('total 200\u00A0ml + 50\u00A0g'), findsOneWidget);
  });
}
