import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';

const _defaultPortions = 1.0;
const _wholeNumberTolerance = 0.000001;
const _portionQuickValues = <num>[0.5, 1.0, 2.0, 3.0];
const _gramQuickValues = <num>[100, 250, 500];

/// How long a pot weighing stays fresh enough to eat from without weighing
/// again.
const potWeighingMaxAge = Duration(hours: 3);

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
    final net = currentNetWeight;
    return net != null && net > 0 && meal.remainingPortions > 0;
  }

  /// Grams of food left: from the last pot weighing when there is one,
  /// otherwise from the weight at "Gekocht".
  int? get currentNetWeight {
    final weighing = meal.potWeighing;
    if (weighing != null) {
      return weighing.netWeightFor(meal.remainingPortions);
    }
    return meal.remainingNetWeight;
  }

  /// Whether the eat page asks to weigh the pot again before eating at
  /// [now]: the meal was weighed in its pot, and since the last weighing
  /// (or the last change, such as "Gekocht") more than [potWeighingMaxAge]
  /// passed or someone ate from it, so water may have evaporated or the
  /// grams left are a guess.
  bool needsPotWeighing(DateTime now) {
    if (meal.potTareWeight == null) {
      return false;
    }
    final (weighedAt, portionsThen) = switch (meal.potWeighing) {
      final weighing? => (weighing.weighedAt, weighing.remainingPortions),
      null => (meal.updatedAt, meal.totalPortions),
    };
    return now.difference(weighedAt) > potWeighingMaxAge ||
        portionsThen != meal.remainingPortions;
  }

  /// Portions the sheet starts with: one, or less when less is left.
  num get defaultPortions {
    final remaining = meal.remainingPortions;
    if (remaining <= 0 || remaining >= _defaultPortions) {
      return _defaultPortions;
    }
    return remaining;
  }

  /// Converts [grams] to portions: their share of the grams left, times the
  /// portions left. The grams left map to all portions left.
  num? gramsToPortions(num grams) {
    if (!canUseGrams) {
      return null;
    }
    final net = currentNetWeight!;
    if (grams >= net) {
      return meal.remainingPortions;
    }
    return grams * meal.remainingPortions / net;
  }

  /// Converts [portions] to grams of the food left.
  num? portionsToGrams(num portions) {
    if (!canUseGrams) {
      return null;
    }
    return portions * currentNetWeight! / meal.remainingPortions;
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
      PreparedMealEatAmountMode.grams => currentNetWeight ?? 0,
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

  /// Bound ingredients with the amounts that [portions] contain, ready to
  /// display.
  List<({PreparedMealComponent component, double amount})> scaledComponents(
    num portions,
  ) {
    if (meal.totalPortions < 1) {
      return const [];
    }
    final ratio = portions / meal.totalPortions;
    return [
      for (final component in meal.components)
        (
          component: component,
          amount: preparedMealComponentDisplayAmount(
            component,
            component.usedAmount * ratio,
          ),
        ),
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
