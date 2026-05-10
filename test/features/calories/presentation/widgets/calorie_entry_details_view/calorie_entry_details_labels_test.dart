import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_details_labels.dart';
import 'package:yamt/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();
  const material = DefaultMaterialLocalizations();

  test('logged day label formats today', () {
    expect(
      calorieEntryLoggedDayLabel(l10n, material, DateTime.now()),
      'Today',
    );
  });

  test('logged day label formats previous days', () {
    final loggedAt = DateTime.now().subtract(const Duration(days: 2));

    expect(
      calorieEntryLoggedDayLabel(l10n, material, loggedAt),
      material.formatShortDate(loggedAt),
    );
  });

  testWidgets('logged at meta label combines date and time', (tester) async {
    final loggedAt = DateTime(2026, 2, 25, 8, 30);
    String? actualLabel;
    String? expectedLabel;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final material = MaterialLocalizations.of(context);
            final dateLabel = material.formatShortDate(loggedAt);
            final timeLabel = material.formatTimeOfDay(
              TimeOfDay.fromDateTime(loggedAt),
              alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(
                context,
              ),
            );
            expectedLabel = '$dateLabel, $timeLabel';
            actualLabel = calorieEntryLoggedAtMetaLabel(
              context,
              l10n,
              material,
              loggedAt,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(actualLabel, expectedLabel);
  });

  test('consumed amount label formats regular entries', () {
    expect(
      calorieEntryConsumedAmountLabel(
        l10n,
        _regularEntry(consumedAmount: 200),
      ),
      '200 g',
    );
  });

  test('consumed amount label formats bundle entries', () {
    expect(
      calorieEntryConsumedAmountLabel(
        l10n,
        _bundleEntry(bundleConsumedPortions: 0.5),
      ),
      '0.5/4 portions',
    );
  });

  test('nutrition metric formatting handles integers and fractions', () {
    expect(formatCalorieEntryNutritionMetricValue(10), '10');
    expect(formatCalorieEntryNutritionMetricValue(10.5), '10.5');
    expect(formatCalorieEntryNutritionMetricValue(10.000000001), '10');
  });
}

CalorieEntry _regularEntry({required double consumedAmount}) {
  final loggedAt = DateTime(2026, 2, 25, 8);
  return CalorieEntry.create(
    id: 'entry-1',
    userId: 'user-1',
    name: 'Skyr',
    mealType: MealType.breakfast,
    consumedAmount: consumedAmount,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 100,
    per100Protein: 10,
    per100Carbs: 5,
    per100Fat: 1,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

CalorieEntry _bundleEntry({required num bundleConsumedPortions}) {
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
    bundleConsumedPortions: bundleConsumedPortions,
    bundleTotalPortions: 4,
    bundleComponents: const [
      CalorieEntryBundleComponent(
        name: 'Beans',
        amountLabel: '150 g',
        totalKcal: 120,
        totalProtein: 8,
        totalCarbs: 18,
        totalFat: 1,
      ),
    ],
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}
