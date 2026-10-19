import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_group/diary_meal_portion_formatter.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/l10n/app_localizations.dart';

DiaryMealEntry _entry(double amount, {double? portionAmount, String? label}) {
  return DiaryMealEntry(
    id: 'bread',
    mealType: MealType.breakfast,
    name: 'Bread',
    totalKcal: 176,
    totalProtein: 5,
    totalCarbs: 30,
    totalFat: 1,
    consumedAmount: amount,
    consumedUnit: ConsumedUnit.grams,
    portionAmount: portionAmount,
    portionLabel: label,
  );
}

void main() {
  testWidgets('shows the count of a named portion, else the amount', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (built) {
            context = built;
            return const SizedBox();
          },
        ),
      ),
    );

    String? label(DiaryMealEntry entry) =>
        formatDiaryMealPortionLabel(context, entry);

    expect(
      label(_entry(80, portionAmount: 40, label: 'Brotscheibe')),
      '2× 40 g Brotscheibe',
    );
    expect(
      label(_entry(30, portionAmount: 60, label: 'Portion')),
      '½× 60 g Portion',
    );
    expect(
      label(_entry(56.25, portionAmount: 37.5, label: 'Scheibe')),
      '1½× 37,5 g Scheibe',
    );
    expect(
      label(_entry(52, portionAmount: 40, label: 'Brotscheibe')),
      '1,3× 40 g Brotscheibe',
    );
    expect(
      label(_entry(16.7, portionAmount: 33.3, label: 'Scheibe')),
      '½× 33,3 g Scheibe',
    );
    // An amount edited off the portion grid falls back to grams.
    expect(label(_entry(55, portionAmount: 40, label: 'Brotscheibe')), '55 g');
    expect(label(_entry(37.5)), '37,5 g');
  });

  test('a meal plan reads as the meal is now', () {
    final l10n = lookupAppLocalizations(const Locale('de'));
    PreparedMeal meal({required int total, bool inPot = false}) => PreparedMeal(
      id: 'chili',
      name: 'Chili',
      totalPortions: total,
      remainingPortions: total,
      totalKcal: 2000,
      totalProtein: 100,
      totalCarbs: 200,
      totalFat: 80,
      createdAt: DateTime(2026, 10, 7),
      updatedAt: DateTime(2026, 10, 7),
      components: const <PreparedMealComponent>[],
      inPot: inPot ? true : null,
    );
    CalorieEntry plan(num consumed, int total) => CalorieEntry.bundle(
      id: 'plan-1',
      userId: 'user-1',
      name: 'Chili',
      mealType: MealType.dinner,
      totalKcal: 500,
      totalProtein: 25,
      totalCarbs: 50,
      totalFat: 20,
      bundleSourcePreparedMealId: 'chili',
      bundleConsumedPortions: consumed,
      bundleTotalPortions: total,
      bundleComponents: const [],
      loggedAt: DateTime(2026, 10, 8, 19),
    );

    // Planned in the pot, still in the pot.
    expect(
      diaryPlanPortionText(l10n, plan(0.5, 1), meal(total: 1, inPot: true)),
      '½ Topf',
    );
    expect(
      diaryPlanPortionText(l10n, plan(0.25, 1), meal(total: 1, inPot: true)),
      '¼ Topf',
    );
    // Planned in the pot, cooked into 4 portions since.
    expect(
      diaryPlanPortionText(l10n, plan(0.5, 1), meal(total: 4)),
      '2/4 Portionen',
    );
    // A cooked meal of one portion stays in portions.
    expect(
      diaryPlanPortionText(l10n, plan(1, 1), meal(total: 1)),
      '1/1 Portionen',
    );
    // Without the meal the row keeps the stored amount.
    expect(diaryPlanPortionText(l10n, plan(0.5, 1), null), isNull);
  });
}
