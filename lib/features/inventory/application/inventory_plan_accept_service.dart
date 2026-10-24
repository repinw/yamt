import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_entry_saver.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/application/inventory_eat_service.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_entry_delete_service.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_pending_consumption_store.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_application.dart';
import 'package:yamt/features/inventory/application/prepared_meal_diary_entry.dart';
import 'package:yamt/features/inventory/application/template_plan_entry.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_eat_outcome.dart';
import 'package:yamt/features/inventory/domain/inventory_exceptions.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/inventory_plan_pack.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_rules.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

part 'inventory_plan_accept_service.g.dart';

/// An accepted plan: the diary entry, and whether the plan meant to take
/// stock that the Vorrat no longer had.
typedef InventoryPlanAcceptResult = ({CalorieEntry entry, bool missedStock});

/// The plan accept service.
@riverpod
InventoryPlanAcceptService inventoryPlanAcceptService(Ref ref) {
  return InventoryPlanAcceptService(
    plans: ref.watch(plannedEntryRepositoryProvider),
    eatService: ref.watch(inventoryEatServiceProvider),
    pendings: ref.watch(inventoryPendingConsumptionStoreProvider),
    quickEat: ref.watch(inventoryQuickEatApplicationProvider),
    saver: ref.watch(calorieEntrySaverProvider),
    deleter: ref.watch(inventoryEntryDeleteServiceProvider),
    overviewRevision: ref.watch(calorieOverviewRevisionProvider.notifier),
    templates: ref.watch(preparedMealTemplateRepositoryProvider),
    parser: ref.watch(templateIngredientParserProvider),
  );
}

/// Turns a plan into a diary entry: the food is eaten as planned, and the
/// stock comes from the Vorrat when it still has the food.
class InventoryPlanAcceptService {
  /// Creates the service.
  const new({
    required this._plans,
    required this._eatService,
    required this._pendings,
    required this._quickEat,
    required this._saver,
    required this._deleter,
    required this._overviewRevision,
    required this._templates,
    required this._parser,
  });

  final PlannedEntryRepository _plans;
  final InventoryEatService _eatService;
  final InventoryPendingConsumptionStore _pendings;
  final InventoryQuickEatApplication _quickEat;
  final CalorieEntrySaver _saver;
  final InventoryEntryDeleteService _deleter;
  final CalorieOverviewRevision _overviewRevision;
  final PreparedMealTemplateRepository _templates;
  final TemplateIngredientParser _parser;

  /// Accepts [plan] on its own day and meal, taking the stock from [items]
  /// or the portions from [meals]. Throws an [InventoryException]
  /// when nothing was saved; the plan then stays.
  Future<InventoryPlanAcceptResult> accept(
    CalorieEntry plan, {
    required List<InventoryItem> items,
    required List<PreparedMeal> meals,
  }) async {
    // The plan goes first, so the diary never counts it twice.
    await _plans.deletePlannedEntry(plan.id);
    try {
      return await _eat(plan, items, meals);
    } on Object {
      await _plans.savePlannedEntry(plan);
      rethrow;
    } finally {
      _overviewRevision.markChanged();
    }
  }

  /// Undoes [accept]: deletes [entry], gives its stock back, and saves
  /// [plan] again. Throws when the entry stays.
  Future<void> undo(CalorieEntry entry, CalorieEntry plan) async {
    final tookStock =
        entry.sourceInventoryItemId != null ||
        entry.bundleSourcePreparedMealId != null;
    final deleted = await _deleter.delete(entry, restoreToInventory: tookStock);
    if (!deleted.isSuccess) {
      throw PlanAcceptFailedException(
        'The entry ${entry.id} was not deleted: ${deleted.failureReason}.',
      );
    }
    await _plans.savePlannedEntry(plan);
    _overviewRevision.markChanged();
  }

  Future<InventoryPlanAcceptResult> _eat(
    CalorieEntry plan,
    List<InventoryItem> items,
    List<PreparedMeal> meals,
  ) async {
    if (plan.bundleSourcePreparedMealId case final mealId?) {
      final meal = meals.firstWhereOrNull((meal) => meal.id == mealId);
      if (meal != null && meal.isInPot) {
        throw PlanMealInPotException('The meal $mealId is still in the pot.');
      }
      final portions = meal == null ? 0 : preparedMealPlanShare(plan, meal);
      if (meal != null &&
          meal.allowsPortions(PreparedMealAction.eat, portions)) {
        final eaten = await _quickEat.consumePreparedMeal(
          meal: meal,
          consumedPortions: portions,
          mealType: plan.mealType,
          loggedDay: plan.loggedAt,
        );
        if (eaten == null) {
          throw PlanAcceptFailedException('The meal $mealId was not eaten.');
        }
        return (entry: eaten.entry, missedStock: false);
      }
      if (plan.nutritionPending) {
        // A reminder takes the values of its meal once every row is
        // filled, then counts like any plan without portions left.
        final counted = meal == null || meal.hasPendingRecipeIngredients
            ? null
            : preparedMealPlanWithPortions(
                plan,
                meal,
                portions,
                now: () => plan.updatedAt,
              );
        if (counted == null) {
          throw switch (meal) {
            null => PlanSourceGoneException('The meal $mealId is gone.'),
            PreparedMeal(hasPendingRecipeIngredients: true) =>
              PlanNutritionPendingException(
                'The meal $mealId still has open rows.',
              ),
            _ => PlanAcceptFailedException(
              'The meal $mealId has no nutrition to eat.',
            ),
          };
        }
        return await _saveWithoutStock(counted);
      }
      return await _saveWithoutStock(plan);
    }
    if (plan.bundleSourceTemplateId case final templateId?
        when plan.nutritionPending) {
      return await _saveWithoutStock(
        await _countedTemplatePlan(plan, templateId, items),
        missedStock: false,
      );
    }
    if (plan.sourceInventoryItemId == null) {
      return await _saveWithoutStock(plan, missedStock: false);
    }
    final pack = pickInventoryItemForPlan(plan, items);
    final pending = pack == null
        ? null
        : _pendings.stage(pack.item, pack.amount);
    if (pack == null || pending == null) {
      return await _saveWithoutStock(plan);
    }
    final item = pack.item;
    final outcome = await _eatService.log(
      item: item,
      request: InventoryItemEatRequest(
        inventoryAmount: pending.amount,
        loggedAt: plan.loggedAt,
        mealType: plan.mealType,
        calorieAmount: plan.consumedAmount,
        calorieUnit: plan.consumedUnit,
      ),
      pending: pending,
    );
    if (outcome case InventoryEatLogged(:final entry)) {
      // The stage takes at most the stock the pack has left.
      return (entry: entry, missedStock: pending.amount < pack.amount);
    }
    // The calorie editor keeps the stock reserved; accepting has no editor.
    await _pendings.discard(pending.id);
    throw PlanAcceptFailedException('The plan ${plan.id} was not eaten.');
  }

  /// The reminder [plan] of the Kochbuch recipe [templateId] with the values
  /// of the recipe's Vorrat items now. Throws while one of its ingredients
  /// still has none, or when the recipe is gone or has nothing to eat.
  Future<CalorieEntry> _countedTemplatePlan(
    CalorieEntry plan,
    String templateId,
    List<InventoryItem> items,
  ) async {
    final templates = await _templates.readAll();
    final template = templates.firstWhereOrNull(
      (template) => template.id == templateId,
    );
    if (template == null) {
      throw PlanSourceGoneException('The recipe $templateId is gone.');
    }
    final counted = replanTemplatePlan(
      plan,
      template,
      items: items,
      parser: _parser,
    );
    if (counted == null || counted.nutritionPending) {
      throw counted == null
          ? PlanAcceptFailedException(
              'The recipe $templateId has nothing to eat.',
            )
          : PlanNutritionPendingException(
              'The recipe $templateId has no nutrition to eat.',
            );
    }
    return counted;
  }

  Future<InventoryPlanAcceptResult> _saveWithoutStock(
    CalorieEntry plan, {
    bool missedStock = true,
  }) async {
    final entry = plan.copyWith(
      sourceInventoryItemId: null,
      sourceInventoryAmountToRestore: null,
      bundleSourcePreparedMealId: null,
    );
    if (!await _saver(entry)) {
      throw PlanAcceptFailedException('The plan ${plan.id} was not saved.');
    }
    return (entry: entry, missedStock: missedStock);
  }
}
