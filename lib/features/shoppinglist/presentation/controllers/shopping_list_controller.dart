import 'dart:async';
import 'dart:developer' show log;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_subscription.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_addition.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_schedule.dart';

part 'shopping_list_controller.g.dart';

/// Owns realtime list state and serialized, optimistic mutations.
@riverpod
class ShoppingListController extends _$ShoppingListController {
  final _subscription = ShoppingListSubscription();
  final _queue = SerializedMutationQueue();
  final _addition = const ShoppingListAddition();

  @override
  Future<List<ShoppingListItem>> build() async {
    final repository = ref.watch(shoppingListRepositoryProvider);
    ref.onDispose(() => unawaited(_subscription.cancel()));
    final items = await _subscription.start(
      repository,
      onData: _onData,
      onError: _onError,
    );
    if (!ref.mounted) return items;
    final due = renewDueShoppingItems(items, DateTime.now());
    if (due == null) return items;
    try {
      return await repository.saveAll(due) ? due : items;
    } on Object {
      return items;
    }
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
    int quantity = 1,
    double estimatedUnitPrice = 0,
  }) {
    final input = _addition.parseAddItemInput(
      name: name,
      brand: brand,
      quantity: quantity,
      estimatedUnitPrice: estimatedUnitPrice,
    );
    if (input == null) return Future.value(false);
    return _mutate((items) => _add(items, input));
  }

  /// Adds several names in one persisted mutation.
  Future<bool> addItemsByNames(Iterable<String> names) {
    final inputs = names
        .map(
          (name) => _addition.parseAddItemInput(
            name: name,
            quantity: 1,
            estimatedUnitPrice: 0,
          ),
        )
        .whereType<ShoppingListAddInput>()
        .toList();
    if (inputs.isEmpty) return Future.value(false);
    return _mutate((items) => inputs.fold<List<ShoppingListItem>>(items, _add));
  }

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

  /// Reduces the quantity; zero keeps the entry crossed off.
  Future<bool> decrementQuantity(String id) => _update(
    id,
    (item) => item.copyWith(quantity: (item.quantity - 1).clamp(0, 999999)),
  );

  /// Resolves a set of shopping entries after purchasing or cooking.
  Future<bool> resolveItemsByIds(Iterable<String> ids) {
    final selected = ids.map((id) => id.trim()).toSet();
    return _mutate(
      (items) => removeShoppingItems(
        [
          for (final item in items)
            if (selected.contains(item.id) && item.quantity > 1)
              item.copyWith(quantity: item.quantity - 1)
            else
              item,
        ],
        (item) =>
            selected.contains(item.id) &&
            items.firstWhere((original) => original.id == item.id).quantity <=
                1,
      ),
    );
  }

  /// Clears completed entries without deleting saved products.
  Future<bool> clearCrossedOffItems() => _mutate(
    (items) => removeShoppingItems(
      items,
      (item) => item.quantity == 0 && !item.isArchived,
    ),
  );

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
    (item) => item.quantity > 0 && !item.isArchived
        ? item
        : item.copyWith(
            quantity: item.repeatEveryDays > 0 ? item.repeatQuantity : 1,
            isArchived: false,
          ),
  );

  /// Applies overdue schedules on resume and while the list is alive.
  Future<bool> processDue() =>
      _mutate((items) => renewDueShoppingItems(items, DateTime.now()));

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
  ) => _queue.run<bool>(
    operation: () async {
      final items = state.asData?.value ?? await future;
      if (!ref.mounted) return false;
      final next = change(items);
      if (next == null) return true;
      return _save(items, next);
    },
    fallbackValue: false,
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
