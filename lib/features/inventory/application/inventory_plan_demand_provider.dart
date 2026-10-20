import 'dart:developer';

import 'package:riverpod/riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/household/application/household_members_provider.dart';
import 'package:yamt/features/household/domain/household_member.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/application/template_plan_entry.dart';
import 'package:yamt/features/inventory/data/plan_reservation_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_plan_demand.dart';
import 'package:yamt/features/inventory/domain/plan_reservation.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

part 'inventory_plan_demand_provider.g.dart';

/// The open plans from today to the last day that can be planned. Overdue
/// plans do not count.
@riverpod
Future<List<CalorieEntry>> openPlans(Ref ref) {
  // Plan writes bump the revision.
  ref.watch(calorieOverviewRevisionProvider);
  final today = dateOnly(ref.watch(clockProvider)());
  return ref
      .watch(plannedEntryRepositoryProvider)
      .loadPlannedEntries(today, addLocalDays(today, diaryPlanAheadDayCount));
}

/// The Kochbuch recipes and Vorlagen that recipe plans come from.
@riverpod
Stream<List<PreparedMeal>> planTemplates(Ref ref) =>
    ref.watch(preparedMealTemplateRepositoryProvider).watchAll();

/// The plan reservations of the other household members, including members
/// who left.
@riverpod
Stream<List<MemberPlanReservation>> otherPlanReservations(Ref ref) =>
    ref.watch(planReservationRepositoryProvider).watchOthers();

/// What the open plans take from the Vorrat, foods and cooked meals:
/// "verplant" on Vorrat rows and "fehlt" on plan rows. The plans of the
/// other household members count as "verplant" too.
@riverpod
Future<InventoryPlanDemand> openPlanDemand(Ref ref) async {
  // Start the loads before awaiting one, so they run side by side.
  final items = ref.watch(inventoryQuickEatItemsProvider.future)..ignore();
  final meals = ref.watch(inventoryQuickEatMealsProvider.future)..ignore();
  final plans = ref.watch(openPlansProvider.future)..ignore();
  final templates = ref.watch(planTemplatesProvider.future)..ignore();
  final others = ref.watch(otherPlanReservationsProvider.future)..ignore();
  final members = ref.watch(householdMembersProvider.future)..ignore();
  final parser = ref.watch(templateIngredientParserProvider);
  final now = ref.watch(clockProvider)();
  final ownUid = ref.watch(
    authStateChangesProvider.select((user) => user.asData?.value?.uid),
  );
  final stock = await items;
  final templatesById = {
    for (final template in await _orNone(templates, 'the recipes of the plans'))
      template.id: template,
  };
  final open = await plans;
  return inventoryPlanDemand(
    open,
    stock,
    await meals,
    ingredientNeedsByPlanId: {
      for (final plan in open)
        if (templatesById[plan.bundleSourceTemplateId] case final template?)
          plan.id: templatePlanIngredientNeeds(
            plan: plan,
            template: template,
            items: stock,
            parser: parser,
            now: now,
          ),
    },
    unstockedIngredientsByPlanId: {
      for (final plan in open)
        if (templatesById[plan.bundleSourceTemplateId] case final template?)
          plan.id: templatePlanUnstockedIngredients(
            plan: plan,
            template: template,
            items: stock,
            parser: parser,
          ),
    },
    othersReservations: await _openOfCurrentMembers(
      others,
      members,
      today: normalizeLocalDay(now),
    ),
    ownUid: ownUid ?? '',
  );
}

/// What the own open plans keep from the shared Vorrat, to share with the
/// household.
@riverpod
Future<List<PlanReservation>> ownPlanReservations(Ref ref) async =>
    (await ref.watch(openPlanDemandProvider.future)).ownReservations;

/// Another household member whose plan on `day`, `daysAhead` days from
/// today, keeps stock of a pack or cooked meal.
typedef PlanStockHolder = ({
  HouseholdMember member,
  DateTime day,
  int daysAhead,
});

/// The other members whose plans keep stock of each pack or cooked meal, by
/// item or meal id, each with the day of the plan, in the order the plans
/// take it.
@riverpod
Future<Map<String, List<PlanStockHolder>>> planStockHolders(Ref ref) async {
  final demand = ref.watch(openPlanDemandProvider.future)..ignore();
  final today = dateOnly(ref.watch(clockProvider)());
  final members = {
    for (final member in await ref.watch(householdMembersProvider.future))
      member.uid: member,
  };
  return {
    for (final MapEntry(key: stockId, value: holders)
        in (await demand).othersByStockId.entries)
      stockId: [
        for (final holder in holders)
          if (members[holder.uid] case final member?)
            (
              member: member,
              day: holder.day,
              daysAhead: diaryDaysBetween(today, dateOnly(holder.day)),
            ),
      ],
  };
}

// A member who left keeps the document until the server deletes it, and a
// member who did not open the app since keeps plans of past days.
Future<List<MemberPlanReservation>> _openOfCurrentMembers(
  Future<List<MemberPlanReservation>> others,
  Future<List<HouseholdMember>> members, {
  required DateTime today,
}) async {
  final reservations = [
    for (final other in await _orNone(others, 'the plans of the household'))
      if (!other.reservation.at.isBefore(today)) other,
  ];
  // Alone in the household: no need to wait for the members.
  if (reservations.isEmpty) {
    return const [];
  }
  final current = {
    for (final member in await _orNone(members, 'the household members'))
      member.uid,
  };
  return [
    for (final other in reservations)
      if (current.contains(other.uid)) other,
  ];
}

// Without the recipes or the household, the own plans still count.
Future<List<T>> _orNone<T>(Future<List<T>> load, String what) async {
  try {
    return await load;
  } on Object catch (error, stackTrace) {
    log(
      'Failed to read $what.',
      name: 'openPlanDemand',
      error: error,
      stackTrace: stackTrace,
    );
    return [];
  }
}
