import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_view_preferences.dart';

/// Defines prepared meal sort criterion.
enum PreparedMealSortCriterion {
  /// Added.
  added,

  /// Eaten.
  eaten,

  /// Alphabetical.
  alphabetical,

  /// Quantity.
  quantity,
}

/// Sorts prepared meals and exposes sort-mode metadata for the UI.
class PreparedMealSorter {
  /// The prepared meal sorter.
  const PreparedMealSorter();

  /// Criterion for.
  PreparedMealSortCriterion criterionFor(PreparedMealSortMode sortMode) {
    return switch (sortMode) {
      PreparedMealSortMode.addedDescending ||
      PreparedMealSortMode.addedAscending => PreparedMealSortCriterion.added,
      PreparedMealSortMode.eatenDescending ||
      PreparedMealSortMode.eatenAscending => PreparedMealSortCriterion.eaten,
      PreparedMealSortMode.alphabeticalAscending ||
      PreparedMealSortMode.alphabeticalDescending =>
        PreparedMealSortCriterion.alphabetical,
      PreparedMealSortMode.quantityAscending ||
      PreparedMealSortMode.quantityDescending =>
        PreparedMealSortCriterion.quantity,
    };
  }

  /// Is ascending.
  bool isAscending(PreparedMealSortMode sortMode) {
    return switch (sortMode) {
      PreparedMealSortMode.addedAscending ||
      PreparedMealSortMode.eatenAscending ||
      PreparedMealSortMode.alphabeticalAscending ||
      PreparedMealSortMode.quantityAscending => true,
      PreparedMealSortMode.addedDescending ||
      PreparedMealSortMode.eatenDescending ||
      PreparedMealSortMode.alphabeticalDescending ||
      PreparedMealSortMode.quantityDescending => false,
    };
  }

  /// Default ascending for criterion.
  bool defaultAscendingForCriterion(PreparedMealSortCriterion criterion) {
    return switch (criterion) {
      PreparedMealSortCriterion.added ||
      PreparedMealSortCriterion.eaten => false,
      PreparedMealSortCriterion.alphabetical ||
      PreparedMealSortCriterion.quantity => true,
    };
  }

  /// Mode for.
  PreparedMealSortMode modeFor(
    PreparedMealSortCriterion criterion, {
    required bool ascending,
  }) {
    return switch ((criterion, ascending)) {
      (PreparedMealSortCriterion.added, true) =>
        PreparedMealSortMode.addedAscending,
      (PreparedMealSortCriterion.added, false) =>
        PreparedMealSortMode.addedDescending,
      (PreparedMealSortCriterion.eaten, true) =>
        PreparedMealSortMode.eatenAscending,
      (PreparedMealSortCriterion.eaten, false) =>
        PreparedMealSortMode.eatenDescending,
      (PreparedMealSortCriterion.alphabetical, true) =>
        PreparedMealSortMode.alphabeticalAscending,
      (PreparedMealSortCriterion.alphabetical, false) =>
        PreparedMealSortMode.alphabeticalDescending,
      (PreparedMealSortCriterion.quantity, true) =>
        PreparedMealSortMode.quantityAscending,
      (PreparedMealSortCriterion.quantity, false) =>
        PreparedMealSortMode.quantityDescending,
    };
  }

  /// Sorts the provided growable list in place and returns it.
  List<PreparedMeal> sort(
    List<PreparedMeal> meals, {
    required PreparedMealSortMode sortMode,
  }) {
    final normalizedNames = <String, String>{
      for (final meal in meals) meal.id: meal.name.toLowerCase(),
    };

    meals.sort((left, right) {
      final normalizedLeftName = normalizedNames[left.id]!;
      final normalizedRightName = normalizedNames[right.id]!;
      final nameCompare = normalizedLeftName.compareTo(normalizedRightName);
      final dateCompare = left.createdAt.compareTo(right.createdAt);
      final updatedCompare = left.updatedAt.compareTo(right.updatedAt);
      final ratioCompare = left.remainingRatio.compareTo(right.remainingRatio);
      final portionsCompare = left.remainingPortions.compareTo(
        right.remainingPortions,
      );

      return switch (sortMode) {
        PreparedMealSortMode.addedDescending =>
          dateCompare != 0 ? -dateCompare : nameCompare,
        PreparedMealSortMode.addedAscending =>
          dateCompare != 0 ? dateCompare : nameCompare,
        PreparedMealSortMode.eatenDescending =>
          updatedCompare != 0
              ? -updatedCompare
              : dateCompare != 0
              ? -dateCompare
              : nameCompare,
        PreparedMealSortMode.eatenAscending =>
          updatedCompare != 0
              ? updatedCompare
              : dateCompare != 0
              ? dateCompare
              : nameCompare,
        PreparedMealSortMode.alphabeticalAscending =>
          nameCompare != 0 ? nameCompare : -dateCompare,
        PreparedMealSortMode.alphabeticalDescending =>
          nameCompare != 0 ? -nameCompare : -dateCompare,
        PreparedMealSortMode.quantityAscending =>
          ratioCompare != 0
              ? ratioCompare
              : portionsCompare != 0
              ? portionsCompare
              : nameCompare,
        PreparedMealSortMode.quantityDescending =>
          ratioCompare != 0
              ? -ratioCompare
              : portionsCompare != 0
              ? -portionsCompare
              : nameCompare,
      };
    });
    return meals;
  }
}
