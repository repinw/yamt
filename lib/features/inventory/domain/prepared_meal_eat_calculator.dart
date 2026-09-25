import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

const _defaultPortions = 1.0;
const _wholeNumberTolerance = 0.000001;
const _portionQuickValues = <num>[0.5, 1.0, 2.0, 3.0];
const _gramQuickValues = <num>[100, 250, 500];

/// Unit the amount of a prepared meal is entered in.
enum PreparedMealEatAmountMode {
  /// Number of portions.
  portions,

  /// Cooked grams.
  grams,
}

/// Amount rules for eating a prepared meal.
class PreparedMealEatCalculator {
  /// Creates the calculator for [meal].
  const new(this.meal);

  /// Meal being eaten.
  final PreparedMeal meal;

  /// Whether the amount can be entered in grams.
  bool get canUseGrams {
    final finalNetWeight = meal.finalNetWeight;
    return finalNetWeight != null &&
        finalNetWeight > 0 &&
        meal.totalPortions > 0;
  }

  /// Portions the sheet starts with: one, or less when less is left.
  num get defaultPortions {
    final remaining = meal.remainingPortions;
    if (remaining <= 0 || remaining >= _defaultPortions) {
      return _defaultPortions;
    }
    return remaining;
  }

  /// Converts [grams] to portions. The remaining grams map to all portions.
  num? gramsToPortions(num grams) {
    final finalNetWeight = meal.finalNetWeight;
    if (finalNetWeight == null ||
        finalNetWeight <= 0 ||
        meal.totalPortions < 1) {
      return null;
    }
    final remainingGrams = meal.remainingNetWeight;
    if (remainingGrams != null && grams >= remainingGrams) {
      return meal.remainingPortions;
    }
    return grams * meal.totalPortions / finalNetWeight;
  }

  /// Converts [portions] to cooked grams.
  num? portionsToGrams(num portions) {
    final finalNetWeight = meal.finalNetWeight;
    if (finalNetWeight == null ||
        finalNetWeight <= 0 ||
        meal.totalPortions < 1) {
      return null;
    }
    return portions * finalNetWeight / meal.totalPortions;
  }

  /// Converts [amount] in [mode] to portions.
  num? portionsFor(num amount, PreparedMealEatAmountMode mode) {
    return switch (mode) {
      PreparedMealEatAmountMode.portions => amount,
      PreparedMealEatAmountMode.grams => gramsToPortions(amount),
    };
  }

  /// Converts [amount] from [from] to [to].
  num? convertAmount(
    num amount, {
    required PreparedMealEatAmountMode from,
    required PreparedMealEatAmountMode to,
  }) {
    if (from == to) {
      return amount;
    }
    return switch (to) {
      PreparedMealEatAmountMode.portions => gramsToPortions(amount),
      PreparedMealEatAmountMode.grams => portionsToGrams(amount),
    };
  }

  /// Portions to eat for [amount] in [mode], or null when out of range.
  num? validPortions(num? amount, PreparedMealEatAmountMode mode) {
    if (amount == null || !_isAmountInRange(amount, mode)) {
      return null;
    }
    final portions = portionsFor(amount, mode);
    if (portions == null ||
        portions <= 0 ||
        portions > meal.remainingPortions) {
      return null;
    }
    return portions;
  }

  /// Everything left, in [mode].
  num remainingAmount(PreparedMealEatAmountMode mode) {
    return switch (mode) {
      PreparedMealEatAmountMode.portions => meal.remainingPortions,
      PreparedMealEatAmountMode.grams => meal.remainingNetWeight ?? 0,
    };
  }

  /// Quick amounts in [mode]: everything left first, then fixed steps.
  List<num> quickValues(PreparedMealEatAmountMode mode) {
    final limit = remainingAmount(mode);
    if (limit <= 0) {
      return const <num>[];
    }
    final steps = switch (mode) {
      PreparedMealEatAmountMode.portions => _portionQuickValues,
      PreparedMealEatAmountMode.grams => _gramQuickValues,
    };
    final values = <num>[];
    for (final value in [limit, ...steps]) {
      if (value > 0 && value <= limit && !values.contains(value)) {
        values.add(value);
      }
    }
    return values;
  }

  /// Bound ingredients with the amounts that [portions] contain.
  List<({PreparedMealComponent component, double amount})> scaledComponents(
    num portions,
  ) {
    if (meal.totalPortions < 1) {
      return const [];
    }
    final ratio = portions / meal.totalPortions;
    return [
      for (final component in meal.components)
        (component: component, amount: component.usedAmount * ratio),
    ];
  }

  bool _isAmountInRange(num amount, PreparedMealEatAmountMode mode) {
    if (amount <= 0) {
      return false;
    }
    return amount <= remainingAmount(mode);
  }
}

/// Parses an entered meal amount. Whole numbers come back as [int].
num? parsePreparedMealAmountInput(String rawValue) {
  final parsed = parsePositiveDecimalInput(rawValue);
  if (parsed == null || !parsed.isFinite) {
    return null;
  }
  final rounded = parsed.roundToDouble();
  if ((parsed - rounded).abs() < _wholeNumberTolerance) {
    return rounded.toInt();
  }
  return parsed;
}
