import 'dart:math' as math;

import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// What a cook can do with a Vorrat meal.
enum PreparedMealAction {
  /// Log portions of the meal into the diary.
  eat,

  /// Plan portions of the meal for a later day.
  plan,

  /// Change the meal's ingredients in the editor.
  editIngredients,
}

/// The one place that decides what a Vorrat meal allows now. Sheets, the
/// Kochbuch, the diary and the commit store ask here instead of combining
/// the meal's flags themselves.
extension PreparedMealRules on PreparedMeal {
  /// Whether [action] is allowed now.
  ///
  /// A meal with open rows has unknown nutrition, so it can be neither
  /// eaten nor planned. A meal in the pot can be planned as a share of the
  /// pot, but eaten only after "Gekocht" gives it portions. Ingredients stay
  /// editable until the first portion is gone.
  bool allows(PreparedMealAction action) => switch (action) {
    PreparedMealAction.eat =>
      !isInPot && !hasPendingRecipeIngredients && !isDepleted,
    PreparedMealAction.plan => !hasPendingRecipeIngredients && !isDepleted,
    PreparedMealAction.editIngredients => remainingPortions >= totalPortions,
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
