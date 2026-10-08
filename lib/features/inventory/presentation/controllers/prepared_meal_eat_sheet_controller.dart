import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_prepared_meal_eat_request.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_eat_calculator.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_portions.dart';

import 'package:yamt/features/inventory/presentation/controllers/prepared_meal_eat_sheet_state.dart';

part 'prepared_meal_eat_sheet_controller.g.dart';

/// Holds the input of the eat sheet for one prepared meal.
///
/// The sheet works with [meal] as the Vorrat holds it now, for example after
/// its open rows were filled, and keeps what the user entered when it
/// changes.
@riverpod
class PreparedMealEatSheetController extends _$PreparedMealEatSheetController {
  @override
  PreparedMealEatSheetState build({
    required PreparedMeal meal,
    required String localeName,
    DateTime? initialLoggedAt,
    MealType? initialMealType,
  }) {
    final now = ref.watch(clockProvider)();
    final loggedAt = initialLoggedAt ?? now;
    final live = ref.listen(livePreparedMealProvider(meal.id), (_, next) {
      if (next.value case final next?) {
        _follow(next);
      }
    });
    final current = live.read().value ?? meal;
    final calculator = PreparedMealEatCalculator(current);
    return PreparedMealEatSheetState(
      calculator: calculator,
      localeName: localeName,
      amountText: formatPreparedMealPortions(
        calculator.defaultPortions,
        localeName: localeName,
      ),
      mode: PreparedMealEatAmountMode.portions,
      loggedAt: loggedAt,
      today: now,
      mealType: initialMealType ?? MealType.defaultForDateTime(loggedAt),
      hasAmountError: false,
    );
  }

  /// Sets the amount field text.
  void setAmountText(String text) {
    state = state.copyWith(amountText: text, hasAmountError: false);
  }

  /// Sets the amount to [value] in the current unit, for example from the
  /// ruler.
  void pickAmount(num value) => setAmountText(_format(value, state.mode));

  /// Switches between portions and grams and converts the entered amount.
  void switchMode() {
    if (!state.calculator.canUseGrams) {
      return;
    }
    final mode = switch (state.mode) {
      PreparedMealEatAmountMode.portions => PreparedMealEatAmountMode.grams,
      PreparedMealEatAmountMode.grams => PreparedMealEatAmountMode.portions,
    };
    final current = state.amount;
    final converted = current == null
        ? null
        : state.calculator.convertAmount(current, from: state.mode, to: mode);
    state = state.copyWith(
      mode: mode,
      hasAmountError: false,
      amountText: converted != null && converted > 0
          ? _format(converted, mode)
          : null,
    );
  }

  /// Logs the meal on [day] at the current time of day.
  void setLoggedDay(DateTime day) {
    state = state.copyWith(
      loggedAt: loggedAtOnDay(day, now: ref.read(clockProvider)()),
    );
  }

  /// Sets the meal the food is logged to.
  void setMealType(MealType mealType) {
    state = state.copyWith(mealType: mealType);
  }

  /// Returns the eat request, or null and shows an error for a bad amount.
  /// [asPlan] plans the meal, even on today; [planDay] plans it on that day
  /// at the current time of day, without showing the day first.
  InventoryPreparedMealEatRequest? submit({
    bool asPlan = false,
    DateTime? planDay,
  }) {
    final portions = state.calculator.validPortions(state.amount, state.mode);
    if (portions == null) {
      // The page stays open, so it shows the picked day with the error.
      if (planDay != null) {
        setLoggedDay(planDay);
      }
      state = state.copyWith(hasAmountError: true);
      return null;
    }
    return InventoryPreparedMealEatRequest(
      meal: state.calculator.meal,
      portions: portions,
      mealType: state.mealType,
      loggedDay: planDay == null
          ? state.loggedAt
          : loggedAtOnDay(planDay, now: ref.read(clockProvider)()),
      isPlan: asPlan,
    );
  }

  void _follow(PreparedMeal meal) {
    if (meal == state.calculator.meal) {
      return;
    }
    state = state.copyWith(
      calculator: PreparedMealEatCalculator(meal),
      hasAmountError: false,
    );
  }

  String _format(num amount, PreparedMealEatAmountMode mode) {
    return switch (mode) {
      PreparedMealEatAmountMode.portions => formatPreparedMealPortions(
        amount,
        localeName: state.localeName,
      ),
      PreparedMealEatAmountMode.grams => formatInventoryAmountValue(
        amount: amount.round(),
        unit: InventoryAmountUnit.gram,
      ),
    };
  }
}
