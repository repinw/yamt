import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// The rows of a Vorrat meal that no food fills: open rows, which keep the
/// meal from being eaten, and ignored rows, which the cook left out but can
/// still fill or open again.
extension PreparedMealRows on PreparedMeal {
  /// The meal without the open or ignored [row]. [rest], the part of the
  /// row that a food did not cover, takes its place in the same list. Null
  /// when the meal has no such row.
  PreparedMeal? withoutRow(String row, {String? rest}) {
    if (_replaced(pendingRecipeIngredients, row, rest) case (final open, _)) {
      return copyWith(pendingRecipeIngredients: open);
    }
    if (_replaced(ignoredPendingRecipeIngredients, row, rest) case (
      final ignored,
      _,
    )) {
      return copyWith(ignoredPendingRecipeIngredients: ignored);
    }
    return null;
  }

  /// The meal with the rows an edit leaves: each food whose Vorrat item is
  /// not among [keptItemIds] opens its row again, and the open or ignored
  /// [deletedRows] are gone.
  PreparedMeal withEditedRows({
    required Set<String> keptItemIds,
    required List<String> deletedRows,
  }) {
    var next = copyWith(
      pendingRecipeIngredients: [
        ...pendingRecipeIngredients,
        for (final component in components)
          if (!keptItemIds.contains(component.inventoryItemId))
            component.openRow,
      ],
    );
    for (final row in deletedRows) {
      next = next.withoutRow(row) ?? next;
    }
    return next;
  }

  /// The meal with the open [row] ignored, or null when no such row is open.
  PreparedMeal? withRowIgnored(String row) {
    if (_replaced(pendingRecipeIngredients, row, null) case (
      final open,
      final stored,
    )) {
      return copyWith(
        pendingRecipeIngredients: open,
        ignoredPendingRecipeIngredients: [
          ...ignoredPendingRecipeIngredients,
          stored,
        ],
      );
    }
    return null;
  }

  /// The meal with the ignored [row] open again, or null when no such row
  /// is ignored.
  PreparedMeal? withRowOpened(String row) {
    if (_replaced(ignoredPendingRecipeIngredients, row, null) case (
      final ignored,
      final stored,
    )) {
      return copyWith(
        pendingRecipeIngredients: [...pendingRecipeIngredients, stored],
        ignoredPendingRecipeIngredients: ignored,
      );
    }
    return null;
  }
}

/// [rows] with the first entry that reads [row] replaced by [rest], or
/// left out without one, and that entry as it was stored. Null when [rows]
/// has no such entry.
(List<String>, String)? _replaced(List<String> rows, String row, String? rest) {
  final trimmed = row.trim();
  final index = rows.indexWhere((entry) => entry.trim() == trimmed);
  if (index < 0) {
    return null;
  }
  return ([...rows.take(index), ?rest, ...rows.skip(index + 1)], rows[index]);
}
