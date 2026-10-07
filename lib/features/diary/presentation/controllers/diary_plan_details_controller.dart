import 'package:collection/collection.dart';
import 'package:riverpod/riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_entry_details_state.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_plan_details_state.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';

part 'diary_plan_details_controller.g.dart';

/// Controller of the details page of the plan [planId] on [planDay]: holds
/// the day, meal, amount and portions the user picks until they save. Null
/// once the plan is gone from its day, for example eaten.
@riverpod
class DiaryPlanDetailsController extends _$DiaryPlanDetailsController {
  @override
  DiaryPlanDetailsState? build(
    String planId,
    DateTime planDay,
    DateTime today,
  ) {
    final plan = ref.watch(
      diaryDayDashboardControllerProvider(planDay).select(
        (state) => state.data?.plannedEntries.firstWhereOrNull(
          (entry) => entry.id == planId,
        ),
      ),
    );
    if (plan == null) {
      return null;
    }
    final mealId = plan.bundleSourcePreparedMealId;
    // A meal that left the Vorrat hides the counter.
    final meal = mealId == null
        ? null
        : ref.watch(livePreparedMealProvider(mealId)).value;
    final now = ref.watch(clockProvider)();
    // The picks stay when the plan or its meal changes.
    final previous = stateOrNull;
    return DiaryPlanDetailsState(
      // The plan as stored now, with the amount the user typed.
      amount: DiaryEntryDetailsState(
        entry: plan,
        amountText:
            previous?.amount.amountText ??
            diaryEntryAmountText(plan.consumedAmount),
        today: today,
      ),
      loggedAt: previous?.loggedAt ?? plan.loggedAt,
      mealType: previous?.mealType ?? plan.mealType,
      now: previous?.now ?? now,
      meal: meal,
      pickedPortions: previous?.pickedPortions,
    );
  }

  /// Takes a typed amount.
  void setAmountText(String text) {
    _update(
      (current) =>
          current.copyWith(amount: current.amount.copyWith(amountText: text)),
    );
  }

  /// Takes a picked day; the plan keeps its time of day.
  void setDay(DateTime day) {
    _update((current) {
      final time = current.loggedAt;
      return current.copyWith(
        loggedAt: DateTime(
          day.year,
          day.month,
          day.day,
          time.hour,
          time.minute,
        ),
      );
    });
  }

  /// Takes a picked meal.
  void setMealType(MealType mealType) {
    _update((current) => current.copyWith(mealType: mealType));
  }

  /// Takes picked portions of the cooked meal.
  void setPortions(int portions) {
    _update((current) => current.copyWith(pickedPortions: portions));
  }

  void _update(
    DiaryPlanDetailsState Function(DiaryPlanDetailsState current) change,
  ) {
    if (state case final current?) {
      state = change(current);
    }
  }
}
