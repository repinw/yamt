import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_meal_ingredients_box.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../support/prepared_meal_test_data.dart';

/// Rice with a complete label, a sauce with only energy and macros, and the
/// open row "1 Zwiebel".
PreparedMeal _meal() {
  return labeledMealTestData(
    ingredients: [
      labeledIngredientTestData(
        labeledFoodTestData(
          id: 'rice',
          name: 'Reis',
          grams: 1000,
          label: riceLabelTestData,
        ),
        200,
      ),
      labeledIngredientTestData(
        labeledFoodTestData(
          id: 'sauce',
          name: 'Tomatensauce',
          grams: 500,
          label: sauceLabelTestData,
        ),
        300,
      ),
    ],
    pending: const ['1 Zwiebel'],
  );
}

Future<void> _pump(WidgetTester tester, {Locale locale = const Locale('en')}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: EatMealIngredientsBox(
            meal: _meal(),
            onFill: (_) {},
            onIgnore: (_) {},
            onUnignore: (_) {},
            onUnassign: (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('marks only the ingredient whose label lacks values', (
    tester,
  ) async {
    await _pump(tester);

    final note = find.byKey(EatMealIngredientsBox.incompleteKey('sauce'));
    expect(note, findsOneWidget);
    expect(tester.widget<Text>(note).data, 'Nutrition values incomplete');
    expect(
      find.byKey(EatMealIngredientsBox.incompleteKey('rice')),
      findsNothing,
    );
    expect(find.text('Nutrition values incomplete'), findsOneWidget);
  });

  testWidgets('says "Nährwerte unvollständig" in German', (tester) async {
    await _pump(tester, locale: const Locale('de'));

    expect(
      tester
          .widget<Text>(
            find.byKey(EatMealIngredientsBox.incompleteKey('sauce')),
          )
          .data,
      'Nährwerte unvollständig',
    );
  });
}
