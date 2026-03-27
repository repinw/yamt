import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'prepared_meal_selection_controller.g.dart';

class PreparedMealSelectionState {
  const PreparedMealSelectionState({
    this.selectedItemIds = const <String>{},
    this.bindRequestToken = 0,
  });

  final Set<String> selectedItemIds;
  final int bindRequestToken;

  bool get isSelectionMode => selectedItemIds.isNotEmpty;

  int get selectedCount => selectedItemIds.length;

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

@riverpod
class PreparedMealSelectionController
    extends _$PreparedMealSelectionController {
  @override
  PreparedMealSelectionState build() {
    return const PreparedMealSelectionState();
  }

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

  void clearSelection() {
    if (state.selectedItemIds.isEmpty) {
      return;
    }
    state = state.copyWith(selectedItemIds: const <String>{});
  }

  void requestCreateMeal() {
    state = state.copyWith(bindRequestToken: state.bindRequestToken + 1);
  }
}
