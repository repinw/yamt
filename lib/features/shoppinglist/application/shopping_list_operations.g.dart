// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list_operations.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Active product keys for integrations that add shopping entries.

@ProviderFor(activeShoppingListItemKeys)
final activeShoppingListItemKeysProvider =
    ActiveShoppingListItemKeysProvider._();

/// Active product keys for integrations that add shopping entries.

final class ActiveShoppingListItemKeysProvider
    extends
        $FunctionalProvider<
          Set<ShoppingListItemMatchKey>,
          Set<ShoppingListItemMatchKey>,
          Set<ShoppingListItemMatchKey>
        >
    with $Provider<Set<ShoppingListItemMatchKey>> {
  /// Active product keys for integrations that add shopping entries.
  ActiveShoppingListItemKeysProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeShoppingListItemKeysProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeShoppingListItemKeysHash();

  @$internal
  @override
  $ProviderElement<Set<ShoppingListItemMatchKey>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Set<ShoppingListItemMatchKey> create(Ref ref) {
    return activeShoppingListItemKeys(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<ShoppingListItemMatchKey> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<ShoppingListItemMatchKey>>(
        value,
      ),
    );
  }
}

String _$activeShoppingListItemKeysHash() =>
    r'525eae5aba27cd8ad7b6a6e78432b7a02c5d7c15';

/// Whether an external product is already on the list.

@ProviderFor(sourceItemInActiveShoppingList)
final sourceItemInActiveShoppingListProvider =
    SourceItemInActiveShoppingListFamily._();

/// Whether an external product is already on the list.

final class SourceItemInActiveShoppingListProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether an external product is already on the list.
  SourceItemInActiveShoppingListProvider._({
    required SourceItemInActiveShoppingListFamily super.from,
    required ShoppingListSourceItem super.argument,
  }) : super(
         retry: null,
         name: r'sourceItemInActiveShoppingListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sourceItemInActiveShoppingListHash();

  @override
  String toString() {
    return r'sourceItemInActiveShoppingListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as ShoppingListSourceItem;
    return sourceItemInActiveShoppingList(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SourceItemInActiveShoppingListProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sourceItemInActiveShoppingListHash() =>
    r'7192ead418320aef5488aaac5a23555e283d87ee';

/// Whether an external product is already on the list.

final class SourceItemInActiveShoppingListFamily extends $Family
    with $FunctionalFamilyOverride<bool, ShoppingListSourceItem> {
  SourceItemInActiveShoppingListFamily._()
    : super(
        retry: null,
        name: r'sourceItemInActiveShoppingListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether an external product is already on the list.

  SourceItemInActiveShoppingListProvider call(ShoppingListSourceItem item) =>
      SourceItemInActiveShoppingListProvider._(argument: item, from: this);

  @override
  String toString() => r'sourceItemInActiveShoppingListProvider';
}
