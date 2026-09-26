import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/application/calorie_entry_saver.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_bundle_component.dart';
import 'package:yamt/features/calories/domain/calorie_nutrient_details.dart';
import 'package:yamt/features/calories/domain/combined_calorie_entry.dart';
import 'package:yamt/features/inventory/application/inventory_calorie_bridge_flow.dart';
import 'package:yamt/features/inventory/application/inventory_pending_consumption_store.dart';
import 'package:yamt/features/inventory/data/inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';

part 'inventory_combined_eat_service.g.dart';

/// A stock item, the amount to eat of it, and its staged consumption.
typedef InventoryCombinedFood = ({
  InventoryItem item,
  InventoryItemEatRequest request,
  PendingInventoryConsumption pending,
});

/// The combined eat service.
@riverpod
InventoryCombinedEatService inventoryCombinedEatService(Ref ref) {
  return InventoryCombinedEatService(
    saver: ref.watch(calorieEntrySaverProvider),
    commitStore: ref.watch(inventoryCalorieEntryCommitStoreProvider),
    pendingStore: ref.watch(inventoryPendingConsumptionStoreProvider),
    userId: ref.watch(firebaseAuthProvider).currentUser?.uid,
    clock: ref.watch(clockProvider),
  );
}

/// Logs several stock items as one combined diary entry.
///
/// The entry and every stock change go out in one write, so either all of
/// them are saved or none.
class InventoryCombinedEatService {
  /// Creates the service.
  const new({
    required this._saver,
    required this._commitStore,
    required this._pendingStore,
    required this._userId,
    required this._clock,
  });

  static const _uuid = Uuid();

  final CalorieEntrySaver _saver;
  final InventoryCalorieEntryCommitStore _commitStore;
  final InventoryPendingConsumptionStore _pendingStore;
  final String? _userId;
  final DateTime Function() _clock;

  /// Whether [item] can be part of a combined entry: it needs nutrition
  /// values to add up.
  static bool canCombine(InventoryItem item) {
    return item.nutrition?.hasAnyNutritionValue ?? false;
  }

  /// Saves [foods] as one entry and finalizes their staged consumptions.
  /// Returns the entry, or null when nothing was saved.
  Future<CalorieEntry?> save({
    required List<InventoryCombinedFood> foods,
    required DateTime loggedAt,
    required MealType mealType,
  }) async {
    final userId = _userId;
    if (userId == null) {
      return null;
    }
    final parts = [for (final food in foods) _component(food)];
    final entry = buildCombinedCalorieEntry(
      id: _uuid.v4(),
      userId: userId,
      mealType: mealType,
      loggedAt: loggedAt,
      now: _clock(),
      components: [for (final part in parts) part.component],
      imageUrl: foods.first.item.imageUrl,
      nutrientDetails: combineCalorieNutrientDetails(
        parts.map((part) => (details: part.details, amount: part.amount)),
      ),
    );

    final saved = await _saver(
      entry,
      isNewEntry: true,
      persistEntry: (entry) => _commit(entry, foods),
    );
    return saved ? entry : null;
  }

  Future<bool> _commit(
    CalorieEntry entry,
    List<InventoryCombinedFood> foods,
  ) async {
    final results = await _commitStore.commitEntryAndInventoryItems(
      entry: entry,
      pendingConsumptions: [for (final food in foods) food.pending],
    );
    if (results == null) {
      return false;
    }
    for (final (index, result) in results.indexed) {
      await _pendingStore.finalize(
        id: foods[index].pending.id,
        itemId: result.itemId,
        quantity: result.quantity,
        currentAmount: result.currentAmount,
        consumedAt: entry.loggedAt,
      );
    }
    return true;
  }

  /// The diary component for eating [request] of [item], as the combine
  /// list shows it before saving.
  static CalorieEntryBundleComponent componentFor(
    InventoryItem item,
    InventoryItemEatRequest request,
  ) {
    return _component((
      item: item,
      request: request,
      pending: PendingInventoryConsumption(
        id: '',
        itemId: item.id,
        amount: request.inventoryAmount,
      ),
    )).component;
  }

  static ({
    CalorieEntryBundleComponent component,
    CalorieNutrientDetails? details,
    double amount,
  })
  _component(InventoryCombinedFood food) {
    final profile = InventoryCalorieBridgeFlow.buildProfileFromInventoryItem(
      food.item,
    );
    if (profile == null) {
      throw ArgumentError.value(
        food.item.id,
        'foods',
        'Only items with nutrition values can be combined.',
      );
    }
    final context = InventoryCalorieBridgeFlow.buildInventoryContext(
      item: food.item,
      pendingConsumptionId: food.pending.id,
      request: food.request,
    );
    final amount = context.consumedAmount;
    final factor = amount / 100;
    return (
      component: CalorieEntryBundleComponent(
        name: food.item.name,
        brand: food.item.brand,
        imageUrl: food.item.imageUrl,
        amountLabel:
            '${_formatAmount(amount)} ${context.consumedUnit.jsonValue}',
        totalKcal: profile.per100Kcal * factor,
        totalProtein: profile.per100Protein * factor,
        totalCarbs: profile.per100Carbs * factor,
        totalFat: profile.per100Fat * factor,
        sourceInventoryItemId: food.item.id,
        // The commit takes the staged amount, which the stock may have capped.
        sourceInventoryAmountToRestore: food.pending.amount,
      ),
      details: profile.nutrientDetails,
      amount: amount,
    );
  }

  static String _formatAmount(double amount) {
    final text = amount.toStringAsFixed(1);
    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }
}
