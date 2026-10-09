import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_day_log_service.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_edits.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_plan_accept_service.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/inventory_plan_pack.dart';

part 'diary_plan_controller.g.dart';

/// Accepts and deletes plans in the diary, and undoes both.
///
/// Kept alive, so it remembers the plans it ate until the diary reloads.
@Riverpod(keepAlive: true)
class DiaryPlanController extends _$DiaryPlanController {
  @override
  FutureOr<void> build() {}

  /// Deletes [plan]. Returns false when it failed.
  Future<bool> delete(CalorieEntry plan) =>
      _write((dayLog) => dayLog.deletePlans([plan]));

  /// Saves [plan] again after a delete. Returns false when it failed.
  Future<bool> restore(CalorieEntry plan) =>
      _write((dayLog) => dayLog.savePlans([plan]));

  /// Plans [entries] on [days] too: one copy of each per day, in
  /// [mealType] or else the entry's own meal, at the entry's time of day,
  /// with a new id (see [planCalorieEntryAgain]). Returns the copies, or
  /// null when saving failed; the copies saved before the failure are
  /// removed again.
  Future<List<CalorieEntry>?> copyToDays(
    List<CalorieEntry> entries, {
    required List<DateTime> days,
    MealType? mealType,
  }) async {
    final now = ref.read(clockProvider)();
    final copies = [
      for (final day in days)
        for (final entry in entries)
          planCalorieEntryAgain(
            entry,
            id: const Uuid().v4(),
            day: day,
            now: now,
          ).copyWith(mealType: mealType ?? entry.mealType),
    ];
    final saved = await _write((dayLog) => dayLog.savePlans(copies));
    return saved ? copies : null;
  }

  /// Deletes [plans] together. Returns false when it failed.
  Future<bool> deleteAll(List<CalorieEntry> plans) =>
      _write((dayLog) => dayLog.deletePlans(plans));

  /// [changed] with the stock amount it saves after its eaten amount changed
  /// from that of [previous] (see [inventoryStockForChangedPlan]). Without
  /// the Vorrat loaded the saved amount scales.
  Future<CalorieEntry> withPlanStock(
    CalorieEntry previous,
    CalorieEntry changed,
  ) async {
    if (previous.sourceInventoryAmountToRestore == null ||
        changed.consumedAmount == previous.consumedAmount) {
      return changed;
    }
    final inventory = await _guard(
      () => _using(inventoryQuickEatInventoryProvider.future, (load) => load),
    );
    final item = inventory?.items.firstWhereOrNull(
      (item) => item.id == previous.sourceInventoryItemId,
    );
    return changed.copyWith(
      sourceInventoryAmountToRestore: inventoryStockForChangedPlan(
        previous: previous,
        changed: changed,
        item: item,
      ),
    );
  }

  /// Saves the new [plan] and lets the diary open its day. Returns false
  /// when it failed.
  Future<bool> plan(CalorieEntry plan) => _write((dayLog) => dayLog.plan(plan));

  /// Eats [plan] as planned, with stock from the Vorrat when it has the
  /// food. Returns null when it failed; the plan then stays.
  ///
  /// An eaten plan counts as accepted until its undo, so a tap on its row,
  /// which shows until the plans reload, eats nothing more.
  Future<InventoryPlanAcceptResult?> accept(CalorieEntry plan) async {
    _accepted.add(plan.id);
    final result = await _using(
      inventoryQuickEatInventoryProvider.future,
      (load) => _guard(() async {
        final inventory = await load;
        return await _using(
          inventoryPlanAcceptServiceProvider,
          (service) => service.accept(
            plan,
            items: inventory.items,
            meals: inventory.meals,
          ),
        );
      }),
    );
    if (result == null) {
      _accepted.remove(plan.id);
    }
    return result;
  }

  /// Eats [plans] one after another, skipping those that are eaten or
  /// being eaten elsewhere. Returns the eaten ones with their entries, and
  /// how many failed; a plan that fails stays.
  Future<
    ({
      List<({CalorieEntry plan, InventoryPlanAcceptResult result})> eaten,
      int failed,
    })
  >
  acceptAll(List<CalorieEntry> plans) async {
    final eaten = <({CalorieEntry plan, InventoryPlanAcceptResult result})>[];
    var failed = 0;
    for (final plan in plans) {
      if (isAccepted(plan)) {
        continue;
      }
      if (await accept(plan) case final result?) {
        eaten.add((plan: plan, result: result));
      } else {
        failed += 1;
      }
    }
    return (eaten: eaten, failed: failed);
  }

  /// Whether [plan] is being eaten or was eaten, so a second tap waits.
  bool isAccepted(CalorieEntry plan) => _accepted.contains(plan.id);

  final _accepted = <String>{};

  /// Undoes [accept]: deletes [entry] and brings [plan] back. Returns false
  /// when it failed.
  Future<bool> undoAccept(CalorieEntry entry, CalorieEntry plan) async {
    final undone = await _using(
      inventoryPlanAcceptServiceProvider,
      (service) => _guard(() async {
        await service.undo(entry, plan);
        return true;
      }),
    );
    if (undone == null) {
      return false;
    }
    _accepted.remove(plan.id);
    return true;
  }

  /// Runs [action] with [provider] listened to, so an auto-dispose provider
  /// lives until it is done.
  Future<T> _using<S, T>(
    ProviderListenable<S> provider,
    Future<T> Function(S value) action,
  ) async {
    final subscription = ref.listen(provider, (_, _) {});
    try {
      return await action(subscription.read());
    } finally {
      subscription.close();
    }
  }

  /// Runs [action] and exposes its failure as an [AsyncError]. Returns its
  /// value, or null when it failed.
  Future<T?> _guard<T extends Object>(Future<T> Function() action) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    if (ref.mounted) {
      state = switch (result) {
        AsyncError(:final error, :final stackTrace) => AsyncError(
          error,
          stackTrace,
        ),
        _ => const AsyncData(null),
      };
    }
    return result.asData?.value;
  }

  Future<bool> _write(
    Future<void> Function(CalorieDayLogService dayLog) write,
  ) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => _using(calorieDayLogServiceProvider, write),
    );
    if (ref.mounted) {
      state = result;
    }
    return !result.hasError;
  }
}
