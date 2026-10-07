import 'package:meta/meta.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_edits.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_entry_details_state.dart';
import 'package:yamt/features/inventory/application/prepared_meal_diary_entry.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_rules.dart';

/// State of the plan details page: the plan, and the day, meal, amount or
/// portions the user picked, which save only on confirm.
@immutable
class DiaryPlanDetailsState {
  /// Creates the state.
  const new({
    required this.amount,
    required this.loggedAt,
    required this.mealType,
    required this.now,
    this.meal,
    this.pickedPortions,
  });

  /// The plan and the typed amount, with the rules of the entry details.
  final DiaryEntryDetailsState amount;

  /// The picked day, at the plan's time of day.
  final DateTime loggedAt;

  /// The picked meal.
  final MealType mealType;

  /// When the page opened, the update time of a plan with other portions.
  final DateTime now;

  /// The cooked meal the plan takes portions of, as it is now, or null.
  final PreparedMeal? meal;

  /// Portions of [meal] the user picked, or null before they change them.
  final int? pickedPortions;

  /// The plan as stored.
  CalorieEntry get plan => amount.entry;

  /// The plan's share of [meal] in whole portions of the meal as it is now,
  /// or null when the portions cannot change.
  int? get plannedPortions {
    final meal = this.meal;
    return meal == null ? null : preparedMealPlanPortions(plan, meal);
  }

  /// Portions the counter shows, or null when it is hidden.
  int? get portions {
    final planned = plannedPortions;
    if (planned == null) {
      return null;
    }
    final picked = pickedPortions ?? planned;
    // The meal may have shrunk since the pick.
    final max = maxPortions;
    return max != null && picked > max ? max : picked;
  }

  /// Most portions the counter allows.
  int? get maxPortions {
    final meal = this.meal;
    final planned = plannedPortions;
    return meal == null || planned == null
        ? null
        : preparedMealPlanMaxPortions(meal, planned);
  }

  /// The plan with the picked portions, or null when they did not change.
  CalorieEntry? get _resized {
    final meal = this.meal;
    final portions = this.portions;
    if (meal == null || portions == null || portions == plannedPortions) {
      return null;
    }
    return preparedMealPlanWithPortions(plan, meal, portions, now: () => now);
  }

  /// The plan with its totals at the picked amount or portions.
  CalorieEntry get preview => _resized ?? amount.preview;

  /// Whether the main button saves instead of eating the plan as is. An
  /// invalid amount counts as changed, so the plan is not eaten as is.
  bool get isChanged =>
      loggedAt != plan.loggedAt ||
      mealType != plan.mealType ||
      _resized != null ||
      amount.changedAmount != null ||
      amount.hasAmountError;

  /// The plan to save.
  CalorieEntry get changed {
    final changedAmount = amount.changedAmount;
    final base =
        _resized ??
        (changedAmount == null
            ? plan
            : rescaleCalorieEntry(
                plan,
                amount: changedAmount,
                now: plan.updatedAt,
              ));
    return base.copyWith(loggedAt: loggedAt, mealType: mealType);
  }

  /// Copy with the given fields replaced.
  DiaryPlanDetailsState copyWith({
    DiaryEntryDetailsState? amount,
    DateTime? loggedAt,
    MealType? mealType,
    int? pickedPortions,
  }) {
    return DiaryPlanDetailsState(
      amount: amount ?? this.amount,
      loggedAt: loggedAt ?? this.loggedAt,
      mealType: mealType ?? this.mealType,
      now: now,
      meal: meal,
      pickedPortions: pickedPortions ?? this.pickedPortions,
    );
  }
}
