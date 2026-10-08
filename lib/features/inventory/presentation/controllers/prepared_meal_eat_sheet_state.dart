import 'package:meta/meta.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/inventory/domain/eat_amount_step.dart';
import 'package:yamt/features/inventory/domain/eat_nutrition.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_eat_calculator.dart';

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

  /// Whether the food is saved as a plan: its day lies after [today].
  bool get isPlan => isDiaryFutureDay(day: loggedAt, today: today);

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
    PreparedMealEatCalculator? calculator,
    String? amountText,
    PreparedMealEatAmountMode? mode,
    DateTime? loggedAt,
    MealType? mealType,
    bool? hasAmountError,
  }) {
    return PreparedMealEatSheetState(
      calculator: calculator ?? this.calculator,
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
