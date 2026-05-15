import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'prepared_meal_selection_controller.g.dart';

/// Defines why inventory items are being selected.
enum PreparedMealSelectionPurpose {
  /// Create a new prepared meal from selected inventory items.
  createMeal,

  /// Add selected inventory items to an existing prepared meal edit.
  addIngredientsToMeal,
}

/// Defines prepared meal selection state.
@immutable
class PreparedMealSelectionState {
  /// The prepared meal selection state.
  const PreparedMealSelectionState({
    this.selectedItemIds = const <String>{},
    this.bindRequestToken = 0,
    this.purpose = PreparedMealSelectionPurpose.createMeal,
  });

  /// The selected item ids.
  final Set<String> selectedItemIds;

  /// The bind request token.
  final int bindRequestToken;

  /// The current selection purpose.
  final PreparedMealSelectionPurpose purpose;

  /// Whether selection mode.
  bool get isSelectionMode {
    return selectedItemIds.isNotEmpty ||
        purpose == PreparedMealSelectionPurpose.addIngredientsToMeal;
  }

  /// Whether selecting ingredients for an existing meal edit.
  bool get isAddingIngredientsToMeal {
    return purpose == PreparedMealSelectionPurpose.addIngredientsToMeal;
  }

  /// The selected count.
  int get selectedCount => selectedItemIds.length;

  /// Copy with.
  PreparedMealSelectionState copyWith({
    Set<String>? selectedItemIds,
    int? bindRequestToken,
    PreparedMealSelectionPurpose? purpose,
  }) {
    return PreparedMealSelectionState(
      selectedItemIds: selectedItemIds ?? this.selectedItemIds,
      bindRequestToken: bindRequestToken ?? this.bindRequestToken,
      purpose: purpose ?? this.purpose,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PreparedMealSelectionState &&
            const SetEquality<String>().equals(
              other.selectedItemIds,
              selectedItemIds,
            ) &&
            other.bindRequestToken == bindRequestToken &&
            other.purpose == purpose;
  }

  @override
  int get hashCode {
    return Object.hash(
      const SetEquality<String>().hash(selectedItemIds),
      bindRequestToken,
      purpose,
    );
  }
}

/// Defines prepared meal selection controller.
@riverpod
class PreparedMealSelectionController
    extends _$PreparedMealSelectionController {
  @override
  PreparedMealSelectionState build() {
    return const PreparedMealSelectionState();
  }

  /// Enter selection.
  void enterSelection(String itemId) {
    final trimmedItemId = itemId.trim();
    if (trimmedItemId.isEmpty) {
      return;
    }
    state = PreparedMealSelectionState(
      selectedItemIds: <String>{trimmedItemId},
      bindRequestToken: state.bindRequestToken,
    );
  }

  /// Start ingredient selection for an existing meal edit.
  void startAddIngredientsToMealSelection() {
    state = PreparedMealSelectionState(
      bindRequestToken: state.bindRequestToken,
      purpose: PreparedMealSelectionPurpose.addIngredientsToMeal,
    );
  }

  /// Toggle selection.
  void toggleSelection(String itemId) {
    final trimmedItemId = itemId.trim();
    if (trimmedItemId.isEmpty) {
      return;
    }
    final nextSelection = Set<String>.from(state.selectedItemIds);
    if (!nextSelection.add(trimmedItemId)) {
      nextSelection.remove(trimmedItemId);
    }
    state = state.copyWith(selectedItemIds: nextSelection);
  }

  /// Clear selection.
  void clearSelection() {
    if (!state.isSelectionMode) {
      return;
    }
    state = PreparedMealSelectionState(
      bindRequestToken: state.bindRequestToken,
    );
  }

  /// Request create meal.
  void requestCreateMeal() {
    state = state.copyWith(bindRequestToken: state.bindRequestToken + 1);
  }

  /// Request the active selection action.
  void confirmSelection() {
    state = state.copyWith(bindRequestToken: state.bindRequestToken + 1);
  }
}
