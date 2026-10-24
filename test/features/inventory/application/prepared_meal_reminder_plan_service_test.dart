import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/application/prepared_meal_diary_entry.dart';
import 'package:yamt/features/inventory/application/prepared_meal_reminder_plan_service.dart';
import 'package:yamt/features/inventory/application/template_plan_entry.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

import '../../../support/prepared_meal_test_data.dart';
import '../../calories/support/fake_planned_entry_repository.dart';

class _MockMeals extends Mock implements PreparedMealRepository;

final _now = DateTime(2026, 10, 15, 9);

/// 4 portions with 800 kcal; "Salz" is still open.
PreparedMeal _open() => preparedMealTestData(
  totalPortions: 4,
  remainingPortions: 4,
).copyWith(totalKcal: 800, pendingRecipeIngredients: const ['Salz']);

CalorieEntry _reminder(PreparedMeal meal, {String id = 'plan'}) =>
    buildConsumedPreparedMealCalorieEntry(
      meal: meal,
      consumedPortions: 1,
      mealType: MealType.lunch,
      now: () => _now,
      nextEntryId: () => id,
      loggedDay: DateTime(2026, 10, 16),
    )!;

/// A Kochbuch recipe of two portions with 200 g oats.
final _recipe = PreparedMeal(
  id: 'recipe',
  name: 'Porridge',
  totalPortions: 2,
  remainingPortions: 2,
  totalKcal: 0,
  totalProtein: 0,
  totalCarbs: 0,
  totalFat: 0,
  createdAt: DateTime(2026, 10, 5),
  updatedAt: DateTime(2026, 10, 5),
  components: const <PreparedMealComponent>[],
  recipeIngredients: const ['200 g Oats'],
);

final _oats = InventoryItem.create(
  id: 'oats',
  name: 'Oats',
  nutrition: const GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.verified,
    per100Kcal: 400,
    per100Protein: 10,
    per100Carbs: 60,
    per100Fat: 12,
  ),
  entryDate: DateTime(2026, 9),
  storeName: 'Rewe',
  quantity: 1,
  initialAmount: 500,
  currentAmount: 500,
  amountUnit: InventoryAmountUnit.gram,
);

/// A plan of one portion of [_recipe], planned while the Vorrat had no oats.
CalorieEntry _recipeReminder() => buildTemplatePlanEntry(
  template: _recipe,
  cookedPortions: 2,
  assignments: const {},
  items: const [],
  parser: const TemplateIngredientParser(),
  mealType: MealType.breakfast,
  loggedDay: DateTime(2026, 10, 16),
  now: () => _now,
  nextEntryId: () => 'recipe-plan',
)!;

/// Holds a plan until the first read, then [changed] in its place, as if
/// the user changed the plan while a refresh ran.
class _ChangedDuringRefresh extends FakePlannedEntryRepository {
  new(CalorieEntry plan, this.changed) : super(plans: [plan]);

  final CalorieEntry changed;
  var _reads = 0;

  @override
  Future<List<CalorieEntry>> loadPlannedEntries(
    DateTime first,
    DateTime last,
  ) async {
    final loaded = await super.loadPlannedEntries(first, last);
    if (_reads++ == 0) {
      plans
        ..clear()
        ..add(changed);
    }
    return loaded;
  }
}

void main() {
  late FakePlannedEntryRepository plans;
  late _MockMeals meals;
  late ProviderContainer container;

  setUp(() {
    plans = FakePlannedEntryRepository();
    meals = _MockMeals();
    container = ProviderContainer(
      overrides: [
        plannedEntryRepositoryProvider.overrideWithValue(plans),
        preparedMealRepositoryProvider.overrideWithValue(meals),
        clockProvider.overrideWithValue(() => _now),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> refresh(String mealId) =>
      container.read(preparedMealReminderPlanServiceProvider).refresh(mealId);

  test('a meal with open rows plans a reminder without kcal', () {
    final plan = _reminder(_open());

    expect(plan.nutritionPending, isTrue);
    expect(plan.totalKcal, 0);
    expect(plan.totalProtein, 0);
    expect(plan.bundleConsumedPortions, 1);
    expect(CalorieEntry.fromJson(plan.toJson()).nutritionPending, isTrue);
    // Only a reminder stores the key.
    final counted = _reminder(_open().copyWith(pendingRecipeIngredients: []));
    expect(counted.toJson().containsKey('nutrition_pending'), isFalse);
    expect(CalorieEntry.fromJson(counted.toJson()).nutritionPending, isFalse);
  });

  test('the reminders get the values once no row is open', () async {
    final open = _open();
    final reminder = _reminder(open);
    plans.plans.addAll([
      reminder,
      _reminder(open.copyWith(id: 'other'), id: 'other-plan'),
    ]);
    final filled = open.copyWith(pendingRecipeIngredients: const []);
    when(() => meals.readAllForChange()).thenAnswer((_) async => [filled]);
    final revision = container.read(calorieOverviewRevisionProvider);

    await refresh(open.id);

    final counted = plans.plans.firstWhere((plan) => plan.id == 'plan');
    expect(counted.nutritionPending, isFalse);
    expect(counted.totalKcal, 200);
    // It stays on its day and time.
    expect(counted.loggedAt, reminder.loggedAt);
    // A plan of another meal stays a reminder.
    expect(
      plans.plans
          .firstWhere((plan) => plan.id == 'other-plan')
          .nutritionPending,
      isTrue,
    );
    expect(container.read(calorieOverviewRevisionProvider), isNot(revision));
  });

  test('plans turn back into reminders when a row opens again', () async {
    final filled = _open().copyWith(pendingRecipeIngredients: const []);
    plans.plans.add(_reminder(filled));
    expect(plans.plans.single.totalKcal, 200);
    when(() => meals.readAllForChange()).thenAnswer((_) async => [_open()]);

    await refresh(filled.id);

    expect(plans.plans.single.nutritionPending, isTrue);
    expect(plans.plans.single.totalKcal, 0);
  });

  test('the reminders wait while a row is still open', () async {
    final open = _open();
    plans.plans.add(_reminder(open));
    when(() => meals.readAllForChange()).thenAnswer((_) async => [open]);

    await refresh(open.id);

    expect(plans.plans.single.nutritionPending, isTrue);
    expect(plans.plans.single.totalKcal, 0);
  });

  group('recipe reminders', () {
    Future<void> refreshRecipes(List<InventoryItem> items) => container
        .read(preparedMealReminderPlanServiceProvider)
        .refreshRecipes([_recipe], items);

    test('get the values once each ingredient has an item', () async {
      final reminder = _recipeReminder();
      expect(reminder.nutritionPending, isTrue);
      plans.plans.add(reminder);
      final revision = container.read(calorieOverviewRevisionProvider);

      await refreshRecipes([_oats]);

      final counted = plans.plans.single;
      expect(counted.id, reminder.id);
      expect(counted.nutritionPending, isFalse);
      // One of two portions of 200 g oats: 100 g at 400 kcal.
      expect(counted.totalKcal, closeTo(400, 0.01));
      expect(counted.loggedAt, reminder.loggedAt);
      expect(counted.bundleSourceTemplateId, 'recipe');
      expect(container.read(calorieOverviewRevisionProvider), isNot(revision));
    });

    test('wait while an ingredient has no item', () async {
      plans.plans.add(_recipeReminder());
      final revision = container.read(calorieOverviewRevisionProvider);

      await refreshRecipes(const []);

      expect(plans.plans.single.nutritionPending, isTrue);
      expect(container.read(calorieOverviewRevisionProvider), revision);
    });

    test('leave a plan alone that changed while they were counted', () async {
      final reminder = _recipeReminder();
      final changed = reminder.copyWith(
        mealType: MealType.dinner,
        updatedAt: _now.add(const Duration(minutes: 1)),
      );
      final changing = _ChangedDuringRefresh(reminder, changed);
      final scoped = ProviderContainer(
        overrides: [
          plannedEntryRepositoryProvider.overrideWithValue(changing),
          preparedMealRepositoryProvider.overrideWithValue(meals),
          clockProvider.overrideWithValue(() => _now),
        ],
      );
      addTearDown(scoped.dispose);

      await scoped
          .read(preparedMealReminderPlanServiceProvider)
          .refreshRecipes([_recipe], [_oats]);

      expect(changing.plans.single, changed);
    });
  });
}
