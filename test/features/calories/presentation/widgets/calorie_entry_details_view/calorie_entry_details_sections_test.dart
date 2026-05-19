import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_details_sections.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_ingredient_row.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('renders one divider between ingredient rows', (tester) async {
    await tester.pumpWidget(
      _wrapSection(
        _bundleEntry(
          components: const [
            CalorieEntryBundleComponent(
              name: 'Beans',
              amountLabel: '150 g',
              totalKcal: 120,
              totalProtein: 8,
              totalCarbs: 18,
              totalFat: 1,
            ),
            CalorieEntryBundleComponent(
              name: 'Corn',
              amountLabel: '90 g',
              totalKcal: 80,
              totalProtein: 3,
              totalCarbs: 12,
              totalFat: 1,
            ),
            CalorieEntryBundleComponent(
              name: 'Rice',
              amountLabel: '120 g',
              totalKcal: 140,
              totalProtein: 4,
              totalCarbs: 30,
              totalFat: 1,
            ),
          ],
        ),
      ),
    );

    expect(find.byType(CalorieEntryIngredientRow), findsNWidgets(3));
    expect(find.byType(Divider), findsNWidgets(2));
  });

  testWidgets('handles empty bundle components without ingredient rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapSection(
        _bundleEntry(components: const <CalorieEntryBundleComponent>[]),
      ),
    );

    expect(find.byKey(CalorieEntryDetailKeys.ingredientsTable), findsOneWidget);
    expect(find.byType(CalorieEntryIngredientRow), findsNothing);
    expect(find.byType(Divider), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Widget _wrapSection(CalorieEntry entry) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: CalorieEntryIngredientsSection(entry: entry)),
  );
}

CalorieEntry _bundleEntry({
  required List<CalorieEntryBundleComponent> components,
}) {
  final loggedAt = DateTime(2026, 2, 25, 12);
  return CalorieEntry.bundle(
    id: 'bundle-1',
    userId: 'user-1',
    name: 'Chili',
    mealType: MealType.lunch,
    totalKcal: 420,
    totalProtein: 28,
    totalCarbs: 35,
    totalFat: 18,
    bundleSourcePreparedMealId: 'prepared-1',
    bundleConsumedPortions: 2,
    bundleTotalPortions: 4,
    bundleComponents: components,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}
