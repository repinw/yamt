import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/application/last_planned_day_provider.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_plan_accept_service.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';

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
      _write((repository) => repository.deletePlannedEntry(plan.id));

  /// Saves [plan] again after a delete. Returns false when it failed.
  Future<bool> restore(CalorieEntry plan) =>
      _write((repository) => repository.savePlannedEntry(plan));

  /// Plans [plan] on [days] too: one copy per day in [mealType], at the
  /// plan's time of day, with a new id. Returns the copies, or null when
  /// saving failed; the copies saved before the failure are removed again.
  Future<List<CalorieEntry>?> copyToDays(
    CalorieEntry plan, {
    required List<DateTime> days,
    required MealType mealType,
  }) async {
    final now = ref.read(clockProvider)();
    final copies = [
      for (final day in days)
        plan.copyWith(
          id: const Uuid().v4(),
          mealType: mealType,
          loggedAt: loggedAtOnDay(day, now: plan.loggedAt),
          createdAt: now,
          updatedAt: now,
        ),
    ];
    final saved = await _write((repository) async {
      final written = <CalorieEntry>[];
      try {
        for (final copy in copies) {
          await repository.savePlannedEntry(copy);
          written.add(copy);
        }
      } on Object {
        // Copies saved before the failure would stay hidden without undo.
        for (final copy in written) {
          await repository.deletePlannedEntry(copy.id);
        }
        rethrow;
      }
    });
    return saved ? copies : null;
  }

  /// Deletes [plans] together. Returns false when it failed.
  Future<bool> deleteAll(List<CalorieEntry> plans) =>
      _write((repository) async {
        for (final plan in plans) {
          await repository.deletePlannedEntry(plan.id);
        }
      });

  /// Saves the new [plan] and lets the diary open its day. Returns false
  /// when it failed.
  Future<bool> plan(CalorieEntry plan) async {
    final planned = ref.read(lastPlannedDayProvider.notifier);
    final saved = await restore(plan);
    if (saved) {
      planned.planned(plan.loggedAt);
    }
    return saved;
  }

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
    Future<void> Function(PlannedEntryRepository repository) write,
  ) async {
    // The diary dashboards learn about the change from the revision.
    final revision = ref.read(calorieOverviewRevisionProvider.notifier);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => _using(plannedEntryRepositoryProvider, write),
    );
    if (!result.hasError) {
      revision.markChanged();
    }
    if (ref.mounted) {
      state = result;
    }
    return !result.hasError;
  }
}
