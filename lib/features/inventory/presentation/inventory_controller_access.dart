import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';

const _controllerAccessLogName = 'InventoryControllerAccess';

/// Runs [operation] on the loaded inventory items controller.
///
/// Calorie-owned flows reach the inventory through this helper, so their
/// stock writes go through the controller that serializes them. Returns
/// [fallbackValue] when the controller is gone or the operation throws.
Future<T> withInventoryController<T>({
  required Ref ref,
  required String operationName,
  required T fallbackValue,
  required Future<T> Function(InventoryItemsController controller) operation,
}) async {
  final subscription = ref.listen(
    inventoryItemsControllerProvider,
    (_, _) {},
    fireImmediately: true,
  );
  try {
    if (!ref.mounted) {
      return fallbackValue;
    }
    await waitForLoadedProvider(ref, inventoryItemsControllerProvider);
    if (!ref.mounted) {
      return fallbackValue;
    }
    return await operation(ref.read(inventoryItemsControllerProvider.notifier));
  } on Object catch (error, stackTrace) {
    log(
      'Failed to $operationName.',
      name: _controllerAccessLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return fallbackValue;
  } finally {
    subscription.close();
  }
}

/// Waits until [provider] left its loading state.
Future<void> waitForLoadedProvider<T>(
  Ref ref,
  ProviderListenable<AsyncValue<T>> provider,
) async {
  final current = ref.read(provider);
  if (current is! AsyncLoading) {
    return;
  }
  final completer = Completer<void>();
  final sub = ref.listen<AsyncValue<T>>(provider, (_, next) {
    if (next is! AsyncLoading && !completer.isCompleted) {
      completer.complete();
    }
  });
  try {
    await completer.future;
  } finally {
    sub.close();
  }
}

/// Reads the inventory item with [itemId], or `null` when it is gone.
Future<InventoryItem?> findInventoryItem({
  required InventoryItemRepository repository,
  required String itemId,
}) async {
  final normalizedItemId = itemId.trim();
  if (normalizedItemId.isEmpty) {
    return null;
  }
  final items = await repository.readAll();
  for (final item in items) {
    if (item.id == normalizedItemId) {
      return item;
    }
  }
  return null;
}
