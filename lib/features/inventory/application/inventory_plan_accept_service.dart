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
import 'package:yamt/features/inventory/domain/inventory_eat_outcome.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_policy.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/inventory_plan_pack.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

part 'inventory_plan_accept_service.g.dart';

/// An accepted plan: the diary entry, and whether the plan meant to take
/// stock that the Vorrat no longer had.
typedef InventoryPlanAcceptResult = ({CalorieEntry entry, bool missedStock});

/// Thrown when a plan could not be eaten or its eat could not be undone.
class InventoryPlanAcceptException implements Exception {
  /// Creates the exception for [message].
  const new(this.message);

  /// What failed.
  final String message;

  @override
  String toString() => 'InventoryPlanAcceptException: $message';
}

/// The plan accept service.
@riverpod
InventoryPlanAcceptService inventoryPlanAcceptService(Ref ref) {
  return InventoryPlanAcceptService(
    plans: ref.watch(plannedEntryRepositoryProvider),
    eatService: ref.watch(inventoryEatServiceProvider),
    pendings: ref.watch(inventoryPendingConsumptionStoreProvider),
    quickEat: ref.watch(inventoryQuickEatActionsProvider),
    saver: ref.watch(calorieEntrySaverProvider),
    deleter: ref.watch(inventoryEntryDeleteServiceProvider),
    overviewRevision: ref.watch(calorieOverviewRevisionProvider.notifier),
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
  });

  final PlannedEntryRepository _plans;
  final InventoryEatService _eatService;
  final InventoryPendingConsumptionStore _pendings;
  final InventoryQuickEatActions _quickEat;
  final CalorieEntrySaver _saver;
  final InventoryEntryDeleteService _deleter;
  final CalorieOverviewRevision _overviewRevision;

  /// Accepts [plan] on its own day and meal, taking the stock from [items]
  /// or the portions from [meals]. Throws when nothing was saved; the plan
  /// then stays.
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
      throw InventoryPlanAcceptException(
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
      final portions = plan.bundleConsumedPortions ?? 0;
      if (meal != null && !meal.isInPot && meal.remainingPortions >= portions) {
        final eaten = await _quickEat.consumePreparedMeal(
          meal: meal,
          consumedPortions: portions,
          mealType: plan.mealType,
          loggedDay: plan.loggedAt,
        );
        if (eaten == null) {
          throw InventoryPlanAcceptException('The meal $mealId was not eaten.');
        }
        return (entry: eaten.entry, missedStock: false);
      }
      return await _saveWithoutStock(plan);
    }
    if (plan.sourceInventoryItemId == null) {
      return await _saveWithoutStock(plan, missedStock: false);
    }
    final item = pickInventoryItemForPlan(plan, items);
    final amount = item == null ? null : _inventoryAmount(plan, item);
    final pending = item == null || amount == null
        ? null
        : _pendings.stage(item, amount);
    if (item == null || pending == null) {
      return await _saveWithoutStock(plan);
    }
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
      return (entry: entry, missedStock: false);
    }
    // The calorie editor keeps the stock reserved; accepting has no editor.
    await _pendings.discard(pending.id);
    throw InventoryPlanAcceptException('The plan ${plan.id} was not eaten.');
  }

  /// The stock amount [plan] takes from [item]: the planned amount from the
  /// planned pack, else the eaten amount when it is in the item's unit.
  static int? _inventoryAmount(CalorieEntry plan, InventoryItem item) {
    final planned = plan.sourceInventoryAmountToRestore;
    if (item.id == plan.sourceInventoryItemId && planned != null) {
      return planned;
    }
    return plan.consumedUnit == inventoryItemConsumedUnit(item)
        ? plan.consumedAmount.round()
        : null;
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
      throw InventoryPlanAcceptException('The plan ${plan.id} was not saved.');
    }
    return (entry: entry, missedStock: missedStock);
  }
}
