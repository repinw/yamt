import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/provider/'
    'prepared_meal_selection_controller.dart';

void main() {
  test('selection controller enters, toggles and clears selection', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller =
        container.read(
            preparedMealSelectionControllerProvider.notifier,
          )
          ..enterSelection('item-1')
          ..toggleSelection('item-2');
    expect(
      container.read(preparedMealSelectionControllerProvider).selectedItemIds,
      {'item-1', 'item-2'},
    );

    controller.toggleSelection('item-1');
    expect(
      container.read(preparedMealSelectionControllerProvider).selectedItemIds,
      {'item-2'},
    );

    controller.clearSelection();
    expect(
      container.read(preparedMealSelectionControllerProvider).isSelectionMode,
      isFalse,
    );
  });
}
