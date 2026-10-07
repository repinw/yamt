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
    final day = ref.watch(
      diaryDayDashboardControllerProvider(planDay).select(
        (state) => (
          isLoaded: state.data != null,
          plan: state.data?.plannedEntries.firstWhereOrNull(
            (entry) => entry.id == planId,
          ),
        ),
      ),
    );
    // A day that reloads without data keeps the page as it is.
    if (!day.isLoaded) {
      return stateOrNull;
    }
    final plan = day.plan;
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
    final previousText = previous?.amount.amountText;
    final next = DiaryPlanDetailsState(
      // The plan as stored now. An amount the user did not type follows it.
      amount: DiaryEntryDetailsState(
        entry: plan,
        amountText:
            previousText == null ||
                previousText ==
                    diaryEntryAmountText(previous!.plan.consumedAmount)
            ? diaryEntryAmountText(plan.consumedAmount)
            : previousText,
        today: today,
      ),
      // A day or meal the user did not pick follows the plan.
      loggedAt: previous == null || previous.loggedAt == previous.plan.loggedAt
          ? plan.loggedAt
          : previous.loggedAt,
      mealType: previous == null || previous.mealType == previous.plan.mealType
          ? plan.mealType
          : previous.mealType,
      now: previous?.now ?? now,
      meal: meal,
      pickedPortions: previous?.pickedPortions,
    );
    // A pick above what the meal has left now drops to it for good.
    return previous?.pickedPortions == null
        ? next
        : next.copyWith(pickedPortions: next.portions);
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
