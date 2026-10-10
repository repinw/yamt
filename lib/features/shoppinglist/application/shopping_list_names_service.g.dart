// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list_names_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The service on the household's shopping list.

@ProviderFor(shoppingListNamesService)
final shoppingListNamesServiceProvider = ShoppingListNamesServiceProvider._();

/// The service on the household's shopping list.

final class ShoppingListNamesServiceProvider
    extends
        $FunctionalProvider<
          ShoppingListNamesService,
          ShoppingListNamesService,
          ShoppingListNamesService
        >
    with $Provider<ShoppingListNamesService> {
  /// The service on the household's shopping list.
  ShoppingListNamesServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingListNamesServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingListNamesServiceHash();

  @$internal
  @override
  $ProviderElement<ShoppingListNamesService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ShoppingListNamesService create(Ref ref) {
    return shoppingListNamesService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShoppingListNamesService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShoppingListNamesService>(value),
    );
  }
}

String _$shoppingListNamesServiceHash() =>
    r'f20efd31aeaf23c8027ad65c59eae6d96a5c02bb';
