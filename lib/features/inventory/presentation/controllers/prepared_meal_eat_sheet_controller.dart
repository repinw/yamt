import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/inventory/domain/eat_amount_step.dart';
import 'package:yamt/features/inventory/domain/eat_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_prepared_meal_eat_request.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_eat_calculator.dart';

part 'prepared_meal_eat_sheet_controller.g.dart';

const _portionStep = 0.25;

/// State of the prepared meal eat sheet.
@immutable
class PreparedMealEatSheetState {
  /// Creates the sheet state.
  const new({
    required this.calculator,
    required this.localeName,
    required this.amountText,
    required this.mode,
    required this.loggedAt,
    required this.today,
    required this.mealType,
    required this.hasAmountError,
  });

  /// Amount rules of the meal.
  final PreparedMealEatCalculator calculator;

  /// Locale the amount text is formatted in.
  final String localeName;

  /// Text of the amount field.
  final String amountText;

  /// Unit of the amount field.
  final PreparedMealEatAmountMode mode;

  /// When the food is logged.
  final DateTime loggedAt;

  /// The current day.
  final DateTime today;

  /// Meal the food is logged to.
  final MealType mealType;

  /// Whether the amount is outside the remaining stock.
  final bool hasAmountError;

  /// Amount parsed from the field.
  num? get amount => parsePreparedMealAmountInput(amountText);

  /// Quick amounts in the current mode. The first one is everything left.
  List<num> get quickValues => calculator.quickValues(mode);

  /// Largest value of the amount ruler: everything left.
  double get amountMax => calculator.remainingAmount(mode).toDouble();

  /// Value of the amount field on the ruler, or 0 when it cannot be parsed.
  double get amountValue => (amount ?? 0).toDouble();

  /// Step the amount ruler snaps to.
  double get amountStep {
    return switch (mode) {
      PreparedMealEatAmountMode.portions => _portionStep,
      PreparedMealEatAmountMode.grams => eatAmountStep(amountMax).toDouble(),
    };
  }

  /// Portions of the entered amount, or one portion without one.
  num get portionsOrOne {
    final entered = amount;
    final portions = entered == null
        ? null
        : calculator.portionsFor(entered, mode);
    return portions ?? 1;
  }

  /// Nutrition of [portionsOrOne].
  EatNutrition? get nutrition {
    final meal = calculator.meal;
    if (meal.totalPortions < 1) {
      return null;
    }
    return EatNutrition.ofPreparedMeal(
      meal,
      portionsOrOne / meal.totalPortions,
    );
  }

  /// Bound ingredients with the amounts in [portionsOrOne].
  List<({PreparedMealComponent component, double amount})> get components {
    return calculator.scaledComponents(portionsOrOne);
  }

  /// Creates a copy with the given fields replaced.
  PreparedMealEatSheetState copyWith({
    String? amountText,
    PreparedMealEatAmountMode? mode,
    DateTime? loggedAt,
    MealType? mealType,
    bool? hasAmountError,
  }) {
    return PreparedMealEatSheetState(
      calculator: calculator,
      localeName: localeName,
      amountText: amountText ?? this.amountText,
      mode: mode ?? this.mode,
      loggedAt: loggedAt ?? this.loggedAt,
      today: today,
      mealType: mealType ?? this.mealType,
      hasAmountError: hasAmountError ?? this.hasAmountError,
    );
  }
}

/// Holds the input of the eat sheet for one prepared meal.
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
    final calculator = PreparedMealEatCalculator(meal);
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
  InventoryPreparedMealEatRequest? submit() {
    final portions = state.calculator.validPortions(state.amount, state.mode);
    if (portions == null) {
      state = state.copyWith(hasAmountError: true);
      return null;
    }
    return InventoryPreparedMealEatRequest(
      portions: portions,
      mealType: state.mealType,
      loggedDay: state.loggedAt,
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
