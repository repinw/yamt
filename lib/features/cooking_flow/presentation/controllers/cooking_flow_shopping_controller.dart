import 'dart:developer' as developer;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/cooking_flow/application/cooking_flow_wizard_state.dart';
import 'package:yamt/features/shoppinglist/application/'
    'shopping_list_operations.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/provider/shopping_list_controller.dart';

part 'cooking_flow_shopping_controller.g.dart';

/// Coordinates cookflow shopping-list side effects.
@riverpod
class CookingFlowShoppingController extends _$CookingFlowShoppingController {
  @override
  void build() {
    ref.watch(shoppingListControllerProvider);
  }

  /// Adds labels to shopping list.
  Future<CookingFlowShoppingListActionResult> addLabels(
    List<String> labels,
  ) async {
    final controller = ref.read(shoppingListControllerProvider.notifier);
    final knownLabels = (await _currentShoppingListItems())
        .map((item) => normalizeShoppingListValue(item.normalizedName))
        .where((label) => label.isNotEmpty)
        .toSet();
    if (!ref.mounted) {
      return CookingFlowShoppingListActionResult.disposed;
    }

    for (final label in labels) {
      final normalizedLabel = normalizeShoppingListValue(label);
      if (normalizedLabel.isEmpty || knownLabels.contains(normalizedLabel)) {
        continue;
      }
      final added = await controller.addItem(name: label);
      if (!ref.mounted) {
        return CookingFlowShoppingListActionResult.disposed;
      }
      if (!added) {
        return CookingFlowShoppingListActionResult.failed;
      }
      knownLabels.add(normalizedLabel);
    }
    return CookingFlowShoppingListActionResult.success;
  }

  /// Resolves matching shopping-list labels.
  Future<void> resolveLabels(List<String> labels) async {
    if (labels.isEmpty) {
      return;
    }

    final shoppingItems = await _currentShoppingListItems();
    if (!ref.mounted || shoppingItems.isEmpty) {
      return;
    }

    final controller = ref.read(shoppingListControllerProvider.notifier);
    final labelsToResolve = labels
        .map(normalizeShoppingListValue)
        .where((label) => label.isNotEmpty)
        .toSet();
    if (labelsToResolve.isEmpty) {
      return;
    }

    final matchingItems = shoppingItems
        .where((item) {
          return labelsToResolve.contains(
            normalizeShoppingListValue(item.normalizedName),
          );
        })
        .toList(growable: false);
    final wasResolved = await controller.resolveItemsByIds(
      matchingItems.map((item) => item.id),
    );
    if (!ref.mounted || !wasResolved) {
      return;
    }
  }

  Future<List<ShoppingListItem>> _currentShoppingListItems() async {
    final currentItems = ref.read(shoppingListControllerProvider).asData?.value;
    if (currentItems != null) {
      return currentItems;
    }
    try {
      return await ref.read(shoppingListControllerProvider.future);
    } on Object catch (error, stackTrace) {
      developer.log(
        'Failed to read shopping list items for cookflow.',
        name: 'CookingFlowShoppingController',
        error: error,
        stackTrace: stackTrace,
      );
      return const <ShoppingListItem>[];
    }
  }
}
