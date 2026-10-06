import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/application/last_planned_day_provider.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_calorie_bridge_flow.dart';
import 'package:yamt/features/inventory/domain/inventory_eat_outcome.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_policy.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';

part 'inventory_plan_service.g.dart';

/// The inventory plan service.
@riverpod
InventoryPlanService inventoryPlanService(Ref ref) {
  return InventoryPlanService(
    plans: ref.watch(plannedEntryRepositoryProvider),
    overviewRevision: ref.watch(calorieOverviewRevisionProvider.notifier),
    lastPlannedDay: ref.watch(lastPlannedDayProvider.notifier),
    userId: ref.watch(firebaseAuthProvider).currentUser?.uid,
    clock: ref.watch(clockProvider),
  );
}

/// Plans foods for a later day: saves a diary entry that takes no stock.
class InventoryPlanService {
  /// Creates the service.
  const new({
    required this._plans,
    required this._overviewRevision,
    required this._lastPlannedDay,
    required this._userId,
    required this._clock,
  });

  static const _uuid = Uuid();

  final PlannedEntryRepository _plans;
  final CalorieOverviewRevision _overviewRevision;
  final LastPlannedDay _lastPlannedDay;
  final String? _userId;
  final DateTime Function() _clock;

  /// Whether [request] becomes a plan: the user plans it, or its day lies
  /// after today.
  bool isPlan(InventoryItemEatRequest request) =>
      request.isPlan ||
      isDiaryFutureDay(day: request.loggedAt, today: _clock());

  /// Saves [request] of [item] as a plan.
  ///
  /// [item] is a Vorrat item, or a food that is not in the Vorrat when
  /// [inVorrat] is false, such as a search result; the plan then names no
  /// Vorrat item.
  Future<InventoryEatOutcome> plan({
    required InventoryItem item,
    required InventoryItemEatRequest request,
    bool inVorrat = true,
  }) async {
    final profile = InventoryCalorieBridgeFlow.buildProfileFromInventoryItem(
      item,
    );
    if (profile == null) {
      return const InventoryEatFailed(InventoryEatFailure.noNutrition);
    }
    if (!canDirectlySaveInventoryItemEatRequest(item, request)) {
      return const InventoryEatFailed(InventoryEatFailure.cannotPlan);
    }
    final userId = _userId;
    if (userId == null) {
      return const InventoryEatFailed(InventoryEatFailure.notSaved);
    }
    final entry = InventoryCalorieBridgeFlow.buildCalorieEntry(
      id: _uuid.v4(),
      userId: userId,
      profile: profile,
      inventoryContext: InventoryCalorieBridgeFlow.buildInventoryContext(
        item: item,
        request: request,
      ),
      request: request,
      now: _clock(),
      inVorrat: inVorrat,
    );
    await _plans.savePlannedEntry(entry);
    _overviewRevision.markChanged();
    _lastPlannedDay.planned(entry.loggedAt);
    return InventoryEatPlanned(entry);
  }

  /// Deletes [plan].
  Future<void> unplan(CalorieEntry plan) async {
    await _plans.deletePlannedEntry(plan.id);
    _overviewRevision.markChanged();
  }
}
