import 'dart:math' as math;

import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_pot_weighing.dart';

/// What a cook can do with a Vorrat meal.
enum PreparedMealAction {
  /// Log portions of the meal into the diary.
  eat,

  /// Plan portions of the meal for a later day.
  plan,

  /// Change the meal's ingredients in the editor.
  editIngredients,

  /// Weigh the food again and give the meal a new weight.
  changeWeight,
}

/// The one place that decides what a Vorrat meal allows now. Sheets, the
/// Kochbuch, the diary and the commit store ask here instead of combining
/// the meal's flags themselves.
extension PreparedMealRules on PreparedMeal {
  /// Whether [action] is allowed now.
  ///
  /// A meal with open rows has unknown nutrition, so it cannot be eaten;
  /// it can be planned only as a reminder without kcal
  /// (`CalorieEntry.nutritionPending`). A meal in the pot can be planned as
  /// a share of the pot, but eaten only after "Gekocht" gives it portions.
  /// Ingredients stay editable until the first portion is gone. A weight is
  /// set at "Gekocht" and can change afterwards while food is left; pieces
  /// split the nutrients by count, so they have no weight.
  bool allows(PreparedMealAction action) => switch (action) {
    PreparedMealAction.eat =>
      !isInPot && !hasPendingRecipeIngredients && !isDepleted,
    PreparedMealAction.plan => !isDepleted,
    PreparedMealAction.editIngredients => remainingPortions >= totalPortions,
    PreparedMealAction.changeWeight =>
      finalNetWeight != null &&
          !isInPot &&
          !isServedInPieces &&
          !isDepleted &&
          totalPortions >= 1,
  };

  /// Whether [action] is allowed now for [portions] of the meal.
  bool allowsPortions(PreparedMealAction action, num portions) =>
      portions > 0 && allows(action) && portions <= remainingPortions;

  /// Whether the meal still waits for the cook: in the pot or with open
  /// rows, and not eaten up.
  bool get isOpen =>
      (isInPot || hasPendingRecipeIngredients) && remainingPortions > 0;

  /// The meal after [portions] left it at [at], never below zero. Negative
  /// [portions] come back.
  PreparedMeal withPortionsTaken(num portions, DateTime at) => copyWith(
    remainingPortions: math.max(0, remainingPortions - portions),
    updatedAt: at,
  );

  /// The meal with [grams] of food left at [at], as the pot weighs it on
  /// the eat page: grams per portion and per 100 g count from the weighing,
  /// and the meal's weight from "Gekocht" stays.
  PreparedMeal withFoodWeighed(int grams, DateTime at) => copyWith(
    potWeighing: PreparedMealPotWeighing(
      netWeight: grams,
      weighedAt: at,
      remainingPortions: remainingPortions,
    ),
    updatedAt: at,
  );

  /// The meal with [grams] of food left at [at] for [portions] portions,
  /// weighed again, for example cold the next morning.
  ///
  /// [portions] are the portions left when the cook weighed, which can be
  /// more than are left now when someone ate in the meantime. The weighing
  /// ties the grams to them, so grams per portion and per 100 g count from
  /// it. The meal's weight becomes what the whole meal weighs: [grams]
  /// scaled from [portions] to all portions. The nutrients of the meal and
  /// of each portion stay, and so do diary entries made from it.
  PreparedMeal withWeightLeft(int grams, num portions, DateTime at) => copyWith(
    potWeighing: PreparedMealPotWeighing(
      netWeight: grams,
      weighedAt: at,
      remainingPortions: portions,
    ),
    finalNetWeight: (grams * totalPortions / portions).round(),
    updatedAt: at,
  );
}

/// The portions of [meal] that [plan] eats: the same share of the meal as
/// when it was planned. A meal planned in the pot was one portion then and
/// has its real portions now.
num preparedMealPlanShare(CalorieEntry plan, PreparedMeal meal) {
  final planned = plan.bundleConsumedPortions ?? 0;
  final plannedTotal = plan.bundleTotalPortions;
  if (plannedTotal == null || plannedTotal <= 0) {
    return planned;
  }
  return planned * meal.totalPortions / plannedTotal;
}

/// The share of [meal] that [plan] takes, in whole portions of the meal as
/// it is now, or null when that share is no whole number of portions.
///
/// The meal may have been portioned anew since the plan was made, so the
/// planned portions scale by the meal's portions now over those then.
int? preparedMealPlanPortions(CalorieEntry plan, PreparedMeal meal) {
  final planned = plan.bundleConsumedPortions;
  final plannedTotal = plan.bundleTotalPortions ?? 0;
  if (planned == null || plannedTotal <= 0 || meal.totalPortions < 2) {
    return null;
  }
  final portions = planned * meal.totalPortions / plannedTotal;
  final whole = portions.round();
  return whole >= 1 && (portions - whole).abs() < 1e-9 ? whole : null;
}

/// The most portions of [meal] a plan that takes [planned] portions can be
/// changed to. Plans reserve no portions, so a plan can take what is left,
/// and never less than it has.
int preparedMealPlanMaxPortions(PreparedMeal meal, int planned) =>
    math.max(planned, meal.remainingPortions.floor());
