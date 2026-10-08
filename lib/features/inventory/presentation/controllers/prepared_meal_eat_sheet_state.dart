import 'package:meta/meta.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/diary_day_status.dart';
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
    this.potGrossText = '',
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
  bool get isPlan => DiaryDayStatus.of(day: loggedAt, today: today).isFuture;

  /// Meal the food is logged to.
  final MealType mealType;

  /// Whether the amount is outside the remaining stock.
  final bool hasAmountError;

  /// Text of the field for the pot on the scale; empty when not weighed.
  final String potGrossText;

  /// Grams of food in the pot after a weighing on this page: the pot on the
  /// scale minus the empty pot, or null without one or when the pot is not
  /// heavier than empty.
  int? get freshPotNetWeight {
    final tare = calculator.meal.potTareWeight;
    final gross = int.tryParse(potGrossText);
    if (tare == null || gross == null || gross <= tare) {
      return null;
    }
    return gross - tare;
  }

  /// Whether the pot was weighed but is not heavier than empty.
  bool get isPotTooLight =>
      potGrossText.isNotEmpty && freshPotNetWeight == null;

  /// Amount parsed from the field.
  num? get amount => parsePreparedMealAmountInput(amountText);

  /// Quick amounts in the current mode. The first one is everything left.
  List<num> get quickValues => calculator.quickValues(mode);

  /// [quickValues] with their index, from the smallest value up, for the
  /// marks under the ruler. Index 0 stays everything left.
  List<(int, num)> get sortedQuickValues =>
      quickValues.indexed.toList()..sort((a, b) => a.$2.compareTo(b.$2));

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

  /// Whether the first mark takes the rest of the pot: the meal was weighed
  /// in its pot, so eating it empty sets the sum right without a scale.
  bool get offersRest => calculator.meal.potTareWeight != null;

  /// Whether the entered amount is everything left, up to the rounding of
  /// the amount field. More than is left is an error, not the rest.
  bool get takesRest {
    final portions = calculator.validPortions(amount, mode);
    return portions != null && calculator.isEverythingLeft(portions);
  }

  /// Grams of [portionsOrOne], or null when the meal has no known weight.
  int? get portionGrams => calculator.portionsToGrams(portionsOrOne)?.round();

  /// kcal in 100 g of the food left, or null when its weight is not known.
  int? get kcalPer100Grams {
    final meal = calculator.meal;
    final net = calculator.currentNetWeight;
    if (net == null || net <= 0 || meal.totalPortions < 1) {
      return null;
    }
    final kcalLeft =
        meal.totalKcal * meal.remainingPortions / meal.totalPortions;
    return (kcalLeft * 100 / net).round();
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
    String? potGrossText,
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
      potGrossText: potGrossText ?? this.potGrossText,
    );
  }
}
