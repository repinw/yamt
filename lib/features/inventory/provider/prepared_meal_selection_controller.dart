import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'prepared_meal_selection_controller.g.dart';

/// Defines prepared meal selection state.
class PreparedMealSelectionState {
  /// The prepared meal selection state.
  const PreparedMealSelectionState({
    this.selectedItemIds = const <String>{},
    this.bindRequestToken = 0,
  });

  /// The selected item ids.
  final Set<String> selectedItemIds;

  /// The bind request token.
  final int bindRequestToken;

  /// Whether selection mode.
  bool get isSelectionMode => selectedItemIds.isNotEmpty;

  /// The selected count.
  int get selectedCount => selectedItemIds.length;

  /// Copy with.
  PreparedMealSelectionState copyWith({
    Set<String>? selectedItemIds,
    int? bindRequestToken,
  }) {
    return PreparedMealSelectionState(
      selectedItemIds: selectedItemIds ?? this.selectedItemIds,
      bindRequestToken: bindRequestToken ?? this.bindRequestToken,
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
            other.bindRequestToken == bindRequestToken;
  }

  @override
  int get hashCode {
    return Object.hash(
      const SetEquality<String>().hash(selectedItemIds),
      bindRequestToken,
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
    if (state.selectedItemIds.isEmpty) {
      return;
    }
    state = state.copyWith(selectedItemIds: const <String>{});
  }

  /// Request create meal.
  void requestCreateMeal() {
    state = state.copyWith(bindRequestToken: state.bindRequestToken + 1);
  }
}
