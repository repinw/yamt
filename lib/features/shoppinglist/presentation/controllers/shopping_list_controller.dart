import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/data/app_version_config_repository.dart';
import 'package:yamt/core/domain/app_update_status.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_subscription.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_addition.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_revert.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_schedule.dart';

part 'shopping_list_controller.g.dart';

/// Owns realtime list state and serialized, optimistic mutations.
@riverpod
class ShoppingListController extends _$ShoppingListController {
  final _subscription = ShoppingListSubscription();
  final _queue = SerializedMutationQueue();
  final _addition = const ShoppingListAddition();
  var _awaitsUpdateStatus = false;

  @override
  Future<List<ShoppingListItem>> build() async {
    final repository = ref.watch(shoppingListRepositoryProvider);
    _awaitsUpdateStatus = false;
    ref.onDispose(() => unawaited(_subscription.cancel()));
    final items = await _subscription.start(
      repository,
      onData: _onData,
      onError: _onError,
    );
    if (!ref.mounted) return items;
    final due = renewDueShoppingItems(items, DateTime.now());
    if (due == null && !_mustRewriteStoredItems(repository)) return items;
    final next = due ?? items;
    try {
      return await repository.saveAll(next) ? next : items;
    } on Object {
      return items;
    }
  }

  /// Temporary migration, added in 3.11.0: removed in 3.14.0. Whether the
  /// stored list holds entries from before the done flag and this app may
  /// rewrite them: an app below the minimum version must not, and until the
  /// status is known the entries stay as they are.
  bool _mustRewriteStoredItems(ShoppingListRepository repository) {
    if (!repository.holdsUnmigratedItems) return false;
    final updateStatus = ref.read(appUpdateStatusProvider).value;
    if (updateStatus == null && !_awaitsUpdateStatus) {
      _awaitsUpdateStatus = true;
      ref.listen(
        appUpdateStatusProvider,
        (_, _) => unawaited(processDue()),
        onError: (_, _) {},
      );
    }
    return updateStatus != null && updateStatus is! AppUpdateRequired;
  }

  /// Reloads the current list.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Adds or merges a product.
  Future<bool> addItem({
    required String name,
    String? brand,
    String? note,
    int quantity = 1,
    double estimatedUnitPrice = 0,
  }) async {
    final revert = await addItemWithRevert(
      name: name,
      brand: brand,
      note: note,
      quantity: quantity,
      estimatedUnitPrice: estimatedUnitPrice,
    );
    return revert != null;
  }

  /// Adds or merges a product and returns the change for [revert], or null
  /// when the input is invalid or the save fails.
  Future<ShoppingListRevert?> addItemWithRevert({
    required String name,
    String? brand,
    String? note,
    int quantity = 1,
    double estimatedUnitPrice = 0,
  }) {
    final input = _addition.parseAddItemInput(
      name: name,
      brand: brand,
      note: note,
      quantity: quantity,
      estimatedUnitPrice: estimatedUnitPrice,
    );
    if (input == null) return Future.value();
    return _mutateWithRevert((items) => _add(items, input));
  }

  /// Adds or merges several products in one save, as an import does. Entries
  /// without a name are left out. Returns the change for [revert], or null
  /// when nothing is valid or the save fails.
  Future<ShoppingListRevert?> addItemsWithRevert(
    List<({String name, String? brand, String? note, int quantity})> entries,
  ) {
    final inputs = [
      for (final entry in entries)
        ?_addition.parseAddItemInput(
          name: entry.name,
          brand: entry.brand,
          note: entry.note,
          quantity: entry.quantity,
          estimatedUnitPrice: 0,
        ),
    ];
    if (inputs.isEmpty) return Future.value();
    return _mutateWithRevert(
      (items) => inputs.fold<List<ShoppingListItem>>(items, _add),
    );
  }

  /// Undoes a change recorded by [addItemWithRevert].
  Future<bool> revert(ShoppingListRevert revert) => revertAll([revert]);

  /// Undoes the changes in [reverts], newest first, in one save.
  Future<bool> revertAll(List<ShoppingListRevert> reverts) => _mutate(
    (items) =>
        reverts.fold<List<ShoppingListItem>>(items, applyShoppingListRevert),
  );

  List<ShoppingListItem> _add(
    List<ShoppingListItem> items,
    ShoppingListAddInput input,
  ) => _addition.mergeAddedItem(
    previousItems: items,
    input: input,
    generatedId: const Uuid().v4(),
  );

  /// Removes a list entry while retaining favorite and schedule settings.
  Future<bool> removeItem(String id) =>
      _mutate((items) => removeShoppingItems(items, (item) => item.id == id));

  /// Increases the requested quantity.
  Future<bool> incrementQuantity(String id) => _update(
    id,
    (item) => item.copyWith(quantity: item.quantity + 1, isArchived: false),
  );

  /// Reduces the requested quantity, down to one.
  Future<bool> decrementQuantity(String id) => _update(
    id,
    (item) => item.copyWith(quantity: (item.quantity - 1).clamp(1, 999999)),
  );

  /// Puts an entry into the cart or back onto the list; its quantity stays.
  Future<bool> setDone(String id, {required bool done}) =>
      _update(id, (item) => item.copyWith(isDone: done));

  /// Takes the entries in the cart off the list; saved products stay saved.
  Future<bool> finishTrip() =>
      _mutate((items) => removeShoppingItems(items, (item) => item.isInCart));

  /// Toggles persistence in the favorites section.
  Future<bool> toggleFavorite(String id) =>
      _update(id, (item) => item.copyWith(isFavorite: !item.isFavorite));

  /// Configures recurrence; zero disables it.
  Future<bool> setSchedule(
    String id, {
    required int days,
    required int quantity,
    DateTime? firstDue,
  }) {
    if (days < 0 || days > 365 || quantity < 1 || quantity > 999) {
      return Future.value(false);
    }
    return _update(
      id,
      (item) => configureShoppingSchedule(
        item,
        days: days,
        quantity: quantity,
        firstDue: firstDue,
        now: DateTime.now(),
      ),
    );
  }

  /// Re-adds a saved product without duplicating an existing active entry.
  Future<bool> addSavedItem(String id) => _update(
    id,
    (item) => item.isOpen
        ? item
        : item.copyWith(
            quantity: !item.isArchived
                ? item.quantity
                : item.repeatEveryDays > 0
                ? item.repeatQuantity
                : 1,
            isArchived: false,
            isDone: false,
          ),
  );

  /// Applies overdue schedules on resume and while the list is alive.
  Future<bool> processDue() => _mutate(
    (items) =>
        renewDueShoppingItems(items, DateTime.now()) ??
        (_mustRewriteStoredItems(ref.read(shoppingListRepositoryProvider))
            ? [...items]
            : null),
  );

  Future<bool> _update(
    String id,
    ShoppingListItem Function(ShoppingListItem) update,
  ) => _mutate((items) {
    if (!items.any((item) => item.id == id)) return null;
    return [
      for (final item in items)
        if (item.id == id) update(item) else item,
    ];
  });

  Future<bool> _mutate(
    List<ShoppingListItem>? Function(List<ShoppingListItem>) change,
  ) async => await _mutateWithRevert(change) != null;

  Future<ShoppingListRevert?> _mutateWithRevert(
    List<ShoppingListItem>? Function(List<ShoppingListItem>) change,
  ) => _queue.run<ShoppingListRevert?>(
    operation: () async {
      final items = state.asData?.value ?? await future;
      if (!ref.mounted) return null;
      final next = change(items);
      if (next == null) return const {};
      if (!await _save(items, next)) return null;
      return shoppingListRevertOf(items, next);
    },
    fallbackValue: null,
    onError: _logError,
  );

  Future<bool> _save(
    List<ShoppingListItem> previous,
    List<ShoppingListItem> next,
  ) async {
    final repository = ref.read(shoppingListRepositoryProvider);
    state = AsyncData(next);
    try {
      final saved = await repository.saveAll(next);
      if (!saved && ref.mounted) state = AsyncData(previous);
      return saved;
    } on Object catch (error, stack) {
      _logError(error, stack);
      if (ref.mounted) state = AsyncData(previous);
      return false;
    }
  }

  void _onData(List<ShoppingListItem> items) {
    if (!ref.mounted) return;
    state = AsyncData(items);
  }

  void _onError(Object error, StackTrace stack) {
    if (ref.mounted) state = AsyncError(error, stack);
  }

  void _logError(Object error, StackTrace stack) => log(
    'Shopping list mutation failed.',
    name: 'ShoppingListController',
    error: error,
    stackTrace: stack,
  );
}
