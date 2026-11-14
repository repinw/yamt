// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list_view.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The list page as the user sees it: the stored list of the chosen scope,
/// with taps not saved yet, by shelf or by name. Loads and fails with the
/// list.

@ProviderFor(shoppingListView)
final shoppingListViewProvider = ShoppingListViewProvider._();

/// The list page as the user sees it: the stored list of the chosen scope,
/// with taps not saved yet, by shelf or by name. Loads and fails with the
/// list.

final class ShoppingListViewProvider
    extends
        $FunctionalProvider<
          AsyncValue<ShoppingListView>,
          AsyncValue<ShoppingListView>,
          AsyncValue<ShoppingListView>
        >
    with $Provider<AsyncValue<ShoppingListView>> {
  /// The list page as the user sees it: the stored list of the chosen scope,
  /// with taps not saved yet, by shelf or by name. Loads and fails with the
  /// list.
  ShoppingListViewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingListViewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingListViewHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<ShoppingListView>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<ShoppingListView> create(Ref ref) {
    return shoppingListView(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<ShoppingListView> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<ShoppingListView>>(value),
    );
  }
}

String _$shoppingListViewHash() => r'19e869cf2fddfd5b16f5b0fe687eb6eb58afa24e';

/// The entries of the list an addition goes to: the private list in the
/// private scope, else the household list. Adding merges only within it.

@ProviderFor(shoppingAddTargetItems)
final shoppingAddTargetItemsProvider = ShoppingAddTargetItemsProvider._();

/// The entries of the list an addition goes to: the private list in the
/// private scope, else the household list. Adding merges only within it.

final class ShoppingAddTargetItemsProvider
    extends
        $FunctionalProvider<
          List<ShoppingListItem>,
          List<ShoppingListItem>,
          List<ShoppingListItem>
        >
    with $Provider<List<ShoppingListItem>> {
  /// The entries of the list an addition goes to: the private list in the
  /// private scope, else the household list. Adding merges only within it.
  ShoppingAddTargetItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingAddTargetItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingAddTargetItemsHash();

  @$internal
  @override
  $ProviderElement<List<ShoppingListItem>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ShoppingListItem> create(Ref ref) {
    return shoppingAddTargetItems(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ShoppingListItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ShoppingListItem>>(value),
    );
  }
}

String _$shoppingAddTargetItemsHash() =>
    r'ba9eb4111e97347e29255482dd21994d765a41c1';
