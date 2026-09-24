// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Shopping list repository.

@ProviderFor(shoppingListRepository)
final shoppingListRepositoryProvider = ShoppingListRepositoryProvider._();

/// Shopping list repository.

final class ShoppingListRepositoryProvider
    extends
        $FunctionalProvider<
          ShoppingListRepository,
          ShoppingListRepository,
          ShoppingListRepository
        >
    with $Provider<ShoppingListRepository> {
  /// Shopping list repository.
  ShoppingListRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingListRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingListRepositoryHash();

  @$internal
  @override
  $ProviderElement<ShoppingListRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ShoppingListRepository create(Ref ref) {
    return shoppingListRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShoppingListRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShoppingListRepository>(value),
    );
  }
}

String _$shoppingListRepositoryHash() =>
    r'f0ee6445a8e3d7e01323f8d1c20ccea466b64a74';
