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
}
