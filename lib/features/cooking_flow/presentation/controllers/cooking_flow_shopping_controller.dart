import 'dart:developer' as developer;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/cooking_flow/application/cooking_flow_wizard_state.dart';
import 'package:yamt/features/shoppinglist/application/'
    'shopping_list_operations.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_revert.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';

part 'cooking_flow_shopping_controller.g.dart';

/// Outcome of [CookingFlowShoppingController.addLabels].
typedef CookingFlowShoppingListAddResult = ({
  CookingFlowShoppingListActionResult result,
  ShoppingListRevert? revert,
});

/// Coordinates cookflow shopping-list side effects.
@riverpod
class CookingFlowShoppingController extends _$CookingFlowShoppingController {
  @override
  void build() {}

  /// Adds labels to shopping list. On success, the returned revert undoes it.
  Future<CookingFlowShoppingListAddResult> addLabels(
    List<String> labels,
  ) async {
    final keepAlive = ref.keepAlive();
    final subscription = ref.listen(
      shoppingListControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    try {
      return await _addLabels(labels);
    } finally {
      subscription.close();
      keepAlive.close();
    }
  }

  Future<CookingFlowShoppingListAddResult> _addLabels(
    List<String> labels,
  ) async {
    final controller = ref.read(shoppingListControllerProvider.notifier);
    final knownLabels = (await _currentShoppingListItems())
        .map((item) => normalizeShoppingListValue(item.normalizedName))
        .where((label) => label.isNotEmpty)
        .toSet();
    if (!ref.mounted) {
      return (
        result: CookingFlowShoppingListActionResult.disposed,
        revert: null,
      );
    }

    final labelsToAdd = <String>[];
    for (final label in labels) {
      final normalizedLabel = normalizeShoppingListValue(label);
      if (normalizedLabel.isEmpty || knownLabels.contains(normalizedLabel)) {
        continue;
      }
      labelsToAdd.add(label);
      knownLabels.add(normalizedLabel);
    }
    if (labelsToAdd.isEmpty) {
      return (
        result: CookingFlowShoppingListActionResult.success,
        revert: const <String, ShoppingListItem?>{},
      );
    }

    final revert = await controller.addItemsByNames(labelsToAdd);
    return (
      result: revert == null
          ? CookingFlowShoppingListActionResult.failed
          : CookingFlowShoppingListActionResult.success,
      revert: revert,
    );
  }

  /// Undoes an add recorded by [addLabels].
  Future<bool> revertAdd(ShoppingListRevert revert) async {
    final keepAlive = ref.keepAlive();
    final subscription = ref.listen(
      shoppingListControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    try {
      return await ref
          .read(shoppingListControllerProvider.notifier)
          .revert(revert);
    } finally {
      subscription.close();
      keepAlive.close();
    }
  }

  /// Resolves matching shopping-list labels.
  Future<void> resolveLabels(List<String> labels) async {
    final keepAlive = ref.keepAlive();
    final subscription = ref.listen(
      shoppingListControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    try {
      await _resolveLabels(labels);
    } finally {
      subscription.close();
      keepAlive.close();
    }
  }

  Future<void> _resolveLabels(List<String> labels) async {
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
      return await ref.read(shoppingListRepositoryProvider).readAll();
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
